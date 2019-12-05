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
    function ConvertETH2NEWDai() payable external returns (uint);
}


interface IUSKI {
    function getKeyInfo(uint value) external returns(bool);
    function max_tokens() external returns(uint);
    function min_liquidity() external returns(uint);
}

contract uniswapLiquidityProviderZAP is Ownable {
    using SafeMath for uint;
    
    // events
    event DaiReceived(uint);
    event LiquidityTokens(uint);
    event ResidualTokens(uint);
    event Everything(uint, uint, uint, uint);
    // event Everything(ETHExchanged, DAITokensReceived, ETHTransferred, ResidualDai)
    
    // state variables
    uint256 public price;
    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    // - this is address of the ETH to NewDAI contract in uniswapExchange
    IuniswapExchange uniswapExchangeContract = IuniswapExchange(0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667);
    IuniswapExchangeExecution public uniswapExchangeExecutionContract = IuniswapExchangeExecution(0x995A332bfCeBE3068C1B7B0cC6959FecF73c56Ac);
    IERC20 public NEW_DAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IUSKI public USKIContract = IUSKI(0x85d57c13436DF73d2248C535b5CdE41Dc8B63F27);  
    
    address public uniswapExchangeContract_forBalance = address(uniswapExchangeContract);
    
    
    constructor() public {
        initialRun();
    }
    
    function initialRun() onlyOwner internal {
        NEW_DAI_TOKEN_ADDRESS.approve(address(uniswapExchangeContract),100000000000000000000000000000);
    }
    
    
    // should we ever want to change the address of the UniSwapExchangeContract
    function set_uniswapExchangeContract(IuniswapExchange _new_uniswapExchangeContract) onlyOwner public {
        uniswapExchangeContract = _new_uniswapExchangeContract;
    }
    
    // should we ever want to change the address of the uniswapExchangeExecutionContract
    function set_uniswapExchangeExecutionContract (IuniswapExchangeExecution _new_uniswapExchangeExecutionContract) onlyOwner public {
        uniswapExchangeExecutionContract = _new_uniswapExchangeExecutionContract;
    }
    
    
    // should we ever want to change the address of the NEW_DAI_TOKEN_ADDRESS
    function set_USKIContract (IUSKI _new_USKIContract) onlyOwner public {
        USKIContract = _new_USKIContract;
    }
    
    // should we ever want to change the address of the KeyInfo Contract
    function set_NEW_DAI_TOKEN_ADDRESS (IERC20 _new_NEW_DAI_TOKEN_ADDRESS) onlyOwner public {
        NEW_DAI_TOKEN_ADDRESS = _new_NEW_DAI_TOKEN_ADDRESS;
    }
    
    
    function LetsInvest(uint _number) payable stopInEmergency public returns (bool) {
        //some basic checks
        require (msg.value > 0.001 ether);
        
        uint conversionPortion = SafeMath.div(SafeMath.mul(msg.value, _number), 10000);
        uint non_conversionPortion = SafeMath.sub(msg.value,conversionPortion);
        
        // converting half of the ETH to new DAI
        uint DaiReceivedAmt = uniswapExchangeExecutionContract.ConvertETH2NEWDai.value(conversionPortion)();
        // emit DaiReceived(DaiReceivedAmt);
        
        
        // adding Liquidity
        USKIContract.getKeyInfo(non_conversionPortion);
        // uint min_liquidity_ans = USKI.min_liquidity();
        uint max_tokens_ans = USKIContract.max_tokens();
        uint deadLineToAddLiquidity = SafeMath.add(now,1800);
        uniswapExchangeContract.addLiquidity.value(non_conversionPortion)(1,max_tokens_ans,deadLineToAddLiquidity);

        // transferring Liquidity
        uint holdings = uniswapExchangeContract.balanceOf(address(this));
        // emit LiquidityTokens(holdings);
        uniswapExchangeContract.transfer(msg.sender, holdings);
        uint residualDaiHoldings = NEW_DAI_TOKEN_ADDRESS.balanceOf(address(this));
        NEW_DAI_TOKEN_ADDRESS.transfer(msg.sender, residualDaiHoldings);
        // emit ResidualTokens(residualDaiHoldings);
        emit Everything(conversionPortion, DaiReceivedAmt, non_conversionPortion, residualDaiHoldings);
        return true;
    }
    
    // incase of half-way error
    function withdrawDAI() public onlyOwner {
        uint StuckDaiHoldings = NEW_DAI_TOKEN_ADDRESS.balanceOf(address(this));
        NEW_DAI_TOKEN_ADDRESS.transfer(_owner, StuckDaiHoldings);
    }
    
    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    // function() external payable {
    //     if (msg.sender == _owner) {
    //         depositETH();
    //     } else {
    //         LetsInvest();
    //     }
    // }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
    
}