pragma solidity ^0.5.1;

contract Invest2_sETH_Storage {
    // - variable for tracking the ETH balance of this contract
    uint public balance;
    bytes32 USDbytes32 = 0x7355534400000000000000000000000000000000000000000000000000000000;
    bytes32 public sETHbytes32 = 0x7345544800000000000000000000000000000000000000000000000000000000;
    address public synthDepotInterfaceContractAddress = 0x172E09691DfBbC035E37c73B62095caa16Ee2388;
    address public synthProxyInterfaceContractAddress = 0xC011A72400E58ecD99Ee497CF89E3775d4bd732F;
    address public sETHContractAddress = 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb;
}