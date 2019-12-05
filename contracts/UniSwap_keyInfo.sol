pragma solidity ^0.5.0;

import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';

interface IuniswapExchange {
    function totalSupply() external view returns (uint256);
}


contract gettingKeyValues {
    IuniswapExchange uniswapExchangeContract = IuniswapExchange(0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667);
    address uniswapExchangeContract_forBalance = address(0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667);
    IERC20 public NEW_DAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
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
        token_reserve = NEW_DAI_TOKEN_ADDRESS.balanceOf(uniswapExchangeContract_forBalance);
        token_amount = SafeMath.div(SafeMath.mul(value,token_reserve),eth_reserve) + 1;
        liquidity_minted_num = SafeMath.mul(total_liquidity,value);
        liquidity_minted = SafeMath.div(liquidity_minted_num,eth_reserve);
        max_tokens = token_amount;
        min_liquidity = liquidity_minted - 1;

        return true;
    }
    
}
