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
}



contract uniswapExchangeExecution is Ownable {
    using SafeMath for uint;
    
    // event
    event MKRHoldingsTransferred (uint, address);
    
    
    // state variables
    uint256 public price;
    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    // - this is address of the ETH to NewDAI contract in uniswapExchange
    IuniswapExchange uniswapExchangeContract = IuniswapExchange(0x2C4Bd064b998838076fa341A83d007FC2FA50957);
    IERC20 public MKR_TOKEN_ADDRESS = IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
   
    // should we ever want to change the address of the UniSwapExchangeContract
    function set_uniswapExchangeContract(IuniswapExchange _new_uniswapExchangeContract) onlyOwner public {
        uniswapExchangeContract = _new_uniswapExchangeContract;
    }
    
    
    // should we ever want to change the address of the NEW_DAI_TOKEN_ADDRESS
    function set_MKR_TOKEN_ADDRESS (IERC20 _new_MKR_TOKEN_ADDRESS) onlyOwner public {
        MKR_TOKEN_ADDRESS = _new_MKR_TOKEN_ADDRESS;
    }
    
    function ConvertETH2MKR() payable stopInEmergency public returns (uint) {
        //some basic checks
        require (msg.sender != address(0));
        require (msg.value > 0.001 ether);
        
        // converting half of the ETH to new DAI
        
        uint min_Tokens = SafeMath.div(SafeMath.mul((uniswapExchangeContract.getEthToTokenInputPrice(msg.value)),95),100);
        uint deadLineToConvert = now + 1800;
        uniswapExchangeContract.ethToTokenSwapInput.value(msg.value)(min_Tokens,deadLineToConvert);
        uint MKRHoldings = MKR_TOKEN_ADDRESS.balanceOf(address(this));
        MKR_TOKEN_ADDRESS.transfer(msg.sender, MKRHoldings);
        emit MKRHoldingsTransferred(MKRHoldings, msg.sender);
        return MKRHoldings;
    }
    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            ConvertETH2MKR();
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
    
}