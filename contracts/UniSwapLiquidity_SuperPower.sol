pragma solidity ^0.5.0;

import './OpenZepplinOwnable.sol';
import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';
import './OpenZepplinReentrancyGuard.sol';

interface UniSwapAddLiquityV2_General {
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue) external payable returns (uint);
}