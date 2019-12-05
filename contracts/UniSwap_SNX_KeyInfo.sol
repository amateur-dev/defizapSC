pragma solidity ^0.5.0;

import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';

interface IuniswapExchange {
    function totalSupply() external view returns (uint256);
}


contract gettingKeyValues {
    IuniswapExchange uniswapExchangeContract = IuniswapExchange(0x3958B4eC427F8fa24eB60F42821760e88d485f7F);
    address uniswapExchangeContract_forBalance = address(0x3958B4eC427F8fa24eB60F42821760e88d485f7F);
    IERC20 public SNX_TOKEN_ADDRESS = IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
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
        token_reserve = SNX_TOKEN_ADDRESS.balanceOf(uniswapExchangeContract_forBalance);
        token_amount = SafeMath.div(SafeMath.mul(value,token_reserve),eth_reserve) + 1;
        liquidity_minted_num = SafeMath.mul(total_liquidity,value);
        liquidity_minted = SafeMath.div(liquidity_minted_num,eth_reserve);
        max_tokens = token_amount;
        min_liquidity = liquidity_minted - 1;
        return true;
    }
    
}
