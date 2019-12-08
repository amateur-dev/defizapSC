pragma solidity ^0.5.0;

contract TestKill {
    constructor () payable public{}

    uint public balance = address(this).balance;

    address payable TargetAddress = 0xbb40eC134832644FAc8740882a79d2f332a40e08;

    function set_targetAddress(address payable _address) public {
        TargetAddress = _address;
    }

    function kill() public {
        selfdestruct(address(TargetAddress));
    }
    
}