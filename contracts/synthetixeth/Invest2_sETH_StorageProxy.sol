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
contract Invest2_sETH_StorageProxy is OwnedUpgradeabilityProxy, Invest2_sETH_Storage  {

   function setUSDbytes32(bytes32 _USDbytes32) external onlyProxyOwner returns(bytes32) {
       USDbytes32 = _USDbytes32;
       return USDbytes32;
   }

    function setETHbytes32(bytes32 _ETHbytes32) external onlyProxyOwner returns(bytes32) {
       sETHbytes32 = _ETHbytes32;
       return sETHbytes32;
    }

    function setSynthDepotInterfaceContractAddress(address _synthDepotInterfaceContractAddress) external onlyProxyOwner returns(address) {
       synthDepotInterfaceContractAddress = _synthDepotInterfaceContractAddress;
       return synthDepotInterfaceContractAddress;
    }

    function setSynthProxyInterfaceContractAddress(address _synthProxyInterfaceContractAddress) external onlyProxyOwner returns(address) {
       synthProxyInterfaceContractAddress = _synthProxyInterfaceContractAddress;
       return synthProxyInterfaceContractAddress;
   }

   function setSETHContractAddress(address _sETHContractAddress) external onlyProxyOwner returns(address) {
       sETHContractAddress = _sETHContractAddress;
       return sETHContractAddress;
   }
}