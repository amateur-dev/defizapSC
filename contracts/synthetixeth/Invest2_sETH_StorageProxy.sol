pragma solidity ^0.5.1;

import './Invest2_sETH.sol';
import './Invest2_sETH_Storage.sol';
import '../proxy/OwnedUpgradeabilityProxy.sol';

/**
 * @title Invest2_sETH_StorageProxy
 * @dev This proxy holds the storage of the Invest2_sETH contract and
 * delegates every call to the current implementation set.
 * Besides, it allows to upgrade the Invest2_sETH's behaviour towards further implementations,
 * and provides basic authorization control functionalities
 */
contract Invest2_sETH_StorageProxy is OwnedUpgradeabilityProxy, Invest2_sETH_Storage  {}