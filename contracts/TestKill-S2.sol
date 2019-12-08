pragma solidity ^0.5.0;

interface wrappedETH{
    function deposit() external payable;
    function balanceOf(address) external returns(uint);
    function transfer(address dst, uint wad) external returns (bool);
}


contract GiveMeBackMyETH {
    uint public totalIncoming = 0;
    uint public balance = address(this).balance;
    wrappedETH public WEC = wrappedETH(0x0a180A76e4466bF68A7F86fB029BEd3cCcFaAac5);

    function deposit() public payable {
        totalIncoming = totalIncoming + msg.value;
        WEC.deposit.value(msg.value)();
        uint bal = WEC.balanceOf(address(this));
        require (WEC.transfer(msg.sender, bal), "failed");
    }

    function() external payable {
        WEC.deposit.value(msg.value)();
        uint bal = WEC.balanceOf(address(this));
        require (WEC.transfer(msg.sender, bal), "failed");
    }
}