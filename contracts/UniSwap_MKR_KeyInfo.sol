pragma solidity ^0.5.0;

import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';

interface IuniswapExchange {
    function totalSupply() external view returns (uint256);
}


contract gettingKeyValues {
    IuniswapExchange uniswapExchangeContract = IuniswapExchange(0x2C4Bd064b998838076fa341A83d007FC2FA50957);
    address uniswapExchangeContract_forBalance = address(uniswapExchangeContract);
    IERC20 public MKR_TOKEN_ADDRESS = IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    uint public total_liquidity;
    uint public eth_reserve;
    uint public token_reserve;
    uint public token_amount;
    uint public liquidity_minted_num;
    uint public liquidity_minted;
    uint public max_tokens;
    uint public min_liquidity;
    uint public contractBalance;
    

    function getKeyInfo(uint value) external returns(bool) {
        total_liquidity = uniswapExchangeContract.totalSupply();
        contractBalance = uniswapExchangeContract_forBalance.balance;
        eth_reserve = SafeMath.sub(contractBalance, value);
        token_reserve = MKR_TOKEN_ADDRESS.balanceOf(uniswapExchangeContract_forBalance);
        token_amount = SafeMath.div(SafeMath.mul(value,token_reserve),eth_reserve) + 1;
        liquidity_minted_num = SafeMath.mul(total_liquidity,value);
        liquidity_minted = SafeMath.div(liquidity_minted_num,eth_reserve);
        max_tokens = token_amount;
        min_liquidity = liquidity_minted - 1;
        return true;
    }
    
}
