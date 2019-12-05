pragma solidity ^0.5.0;

import './OpenZepplinOwnable.sol';
import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';

// the objective of this contract is only to get the exchange price of the assets from the uniswap indexed

interface IuniswapExchange {
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function totalSupply() external view returns (uint256);
}


interface IuniswapExchangeExecution {
    function ConvertETH2SNX() payable external returns (uint);
}


interface IUSKI_SNX {
    function getKeyInfo(uint value) external returns(bool);
    function max_tokens() external returns(uint);
    function min_liquidity() external returns(uint);
}

contract uniswapLiquidityProviderZAP_ETHSNX is Ownable {
    using SafeMath for uint;
    
    // events
    event SNXReceived(uint);
    event LiquidityTokens(uint);
    
    // state variables
    uint256 public price;
    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    // - this is address of the ETH to SNX contract in uniswapExchange
    IuniswapExchange uniswapExchangeContract = IuniswapExchange(0x3958B4eC427F8fa24eB60F42821760e88d485f7F);
    IuniswapExchangeExecution public uniswapExchangeExecutionContract = IuniswapExchangeExecution(0x8f1Ee1dAD73D1BA09e23318012d972cccC40f040);
    IERC20 public SNX_TOKEN_ADDRESS = IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    IUSKI_SNX public USKIContract = IUSKI_SNX(0x7b055ff2498d0E8e83Ec009292eC24fa8d007097);  
    
    address public uniswapExchangeContract_forBalance = address(uniswapExchangeContract);
    
    
    constructor() public {
        initialRun();
    }
    
    function initialRun() onlyOwner internal {
        SNX_TOKEN_ADDRESS.approve(address(uniswapExchangeContract),100000000000000000000000000000);
    }
    
    
    // should we ever want to change the address of the UniSwapExchangeContract
    function set_uniswapExchangeContract(IuniswapExchange _new_uniswapExchangeContract) onlyOwner public {
        uniswapExchangeContract = _new_uniswapExchangeContract;
    }
    
    // should we ever want to change the address of the uniswapExchangeExecutionContract
    function set_uniswapExchangeExecutionContract (IuniswapExchangeExecution _new_uniswapExchangeExecutionContract) onlyOwner public {
        uniswapExchangeExecutionContract = _new_uniswapExchangeExecutionContract;
    }
    
    
    // should we ever want to change the address of the KeyInfo Contract
    function set_USKIContract (IUSKI_SNX _new_USKIContract) onlyOwner public {
        USKIContract = _new_USKIContract;
    }
    
    // should we ever want to change the address of the SNX_TOKEN_ADDRESS
    function set_SNX_TOKEN_ADDRESS (IERC20 _new_SNX_TOKEN_ADDRESS) onlyOwner public {
        SNX_TOKEN_ADDRESS = _new_SNX_TOKEN_ADDRESS;
    }
    
    
    function LetsInvest() payable stopInEmergency public returns (bool) {
        //some basic checks
        require (msg.value > 0.001 ether);
        
        uint conversionPortion = SafeMath.div(SafeMath.mul(msg.value, 505), 1000);
        uint non_conversionPortion = SafeMath.sub(msg.value,conversionPortion);
        
        // converting half of the ETH to new SNX
        uint SNXReceivedAmt = uniswapExchangeExecutionContract.ConvertETH2SNX.value(conversionPortion)();
        emit SNXReceived(SNXReceivedAmt);
        
        
        // adding Liquidity
        USKIContract.getKeyInfo(non_conversionPortion);
        uint max_tokens_ans = USKIContract.max_tokens();
        uint deadLineToAddLiquidity = SafeMath.add(now,1800);
        uniswapExchangeContract.addLiquidity.value(non_conversionPortion)(1,max_tokens_ans,deadLineToAddLiquidity);

        // transferring Liquidity
        uint holdings = uniswapExchangeContract.balanceOf(address(this));
        emit LiquidityTokens(holdings);
        uniswapExchangeContract.transfer(msg.sender, holdings);
        uint residualSNXHoldings = SNX_TOKEN_ADDRESS.balanceOf(address(this));
        SNX_TOKEN_ADDRESS.transfer(msg.sender, residualSNXHoldings);
        return true;
    }
    
    // incase of half-way error
    function withdrawSNX() public onlyOwner {
        uint StuckSNXHoldings = SNX_TOKEN_ADDRESS.balanceOf(address(this));
        SNX_TOKEN_ADDRESS.transfer(_owner, StuckSNXHoldings);
    }
    
    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest();
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
    
}