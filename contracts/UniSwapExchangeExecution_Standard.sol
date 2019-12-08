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
    function tokenAddress() external view returns (address token);
}



contract uniswapExchangeExecution is Ownable {
    using SafeMath for uint;
    
    // event
    event ERC20TokenHoldingsTransferred (uint, address);
    
    
    // state variables
    uint256 public price;
    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    function LetsConvert(IuniswapExchange _ExchangeContractAddress) public payable stopInEmergency returns (uint) {
        IERC20 ERC20TokenAddress = IERC20(_ExchangeContractAddress.tokenAddress());
        uint min_Tokens = SafeMath.div(SafeMath.mul((_ExchangeContractAddress.getEthToTokenInputPrice(msg.value)),95),100);
        uint deadLineToConvert = now + 1800;
        _ExchangeContractAddress.ethToTokenSwapInput.value(msg.value)(min_Tokens,deadLineToConvert);
        uint ERC20TokenHoldings = ERC20TokenAddress.balanceOf(address(this));
        ERC20TokenAddress.transfer(msg.sender, ERC20TokenHoldings);
        emit ERC20TokenHoldingsTransferred(ERC20TokenHoldings, msg.sender);
        return ERC20TokenHoldings;
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
            revert("Use the DeFiZap Front End");
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
    
}