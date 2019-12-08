pragma solidity ^0.5.0;

import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';

interface IuniswapExchange {
    function totalSupply() external view returns (uint256);
    function tokenAddress() external view returns (address token);
}

contract gettingKeyValues {

    function getGetMaxTokens (IuniswapExchange _ExchangeContractAddress, uint value) external view returns(uint) {
        IuniswapExchange uniswapExchangeContract = _ExchangeContractAddress;
        IERC20 tokenContractAddress = IERC20(uniswapExchangeContract.tokenAddress());
        uint contractBalance = address(uniswapExchangeContract).balance;
        uint eth_reserve = SafeMath.sub(contractBalance, value);
        uint token_reserve = tokenContractAddress.balanceOf(address(uniswapExchangeContract));
        uint token_amount = SafeMath.div(SafeMath.mul(value,token_reserve),eth_reserve) + 1;
        uint max_tokens = token_amount;
        return max_tokens;
    }
}
