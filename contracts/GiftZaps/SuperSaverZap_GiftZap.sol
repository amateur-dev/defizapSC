pragma solidity ^0.5.0;

import "../Ownable.sol";
import "../ReentrancyGuard.sol";
import "../SafeMath.sol";


interface Invest2FulcrumiDAI {
    function LetsInvest2FulcrumiDAI(address _towhomtoissue) external payable;
}

interface Invest2cDAI {
    function letsGetSomeDAI(address _towhomtoissue) external payable;
}

// through this contract we are putting 50% allocation to 2xLongETH and 50% to 2xLongBTC
contract SuperSaverZap is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    // state variables
    
    
    // - variables in relation to the percentages
    uint public cDAIPercentage = 50;
    Invest2cDAI public Invest2cDAIContract = Invest2cDAI(0x275413360ae1B2E27C0061712d42875F8D2AC0DF);
    Invest2FulcrumiDAI public Invest2FulcrumiDAIContract = Invest2FulcrumiDAI(0xf84a6794649a99a12887D20bCE9C5952E49bA190);

    
    // - in relation to the ETH held by this contract
    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
 

    // this function should be called should we ever want to change the underlying Fulcrum Long ETHContract address
    function set_Invest2FulcrumiDAIContract (Invest2FulcrumiDAI _Invest2FulcrumiDAIContract) onlyOwner public {
        Invest2FulcrumiDAIContract = _Invest2FulcrumiDAIContract;
    }
    
    // this function should be called should we ever want to change the underlying Fulcrum Long ETHContract address
    function set_Invest2cDAIContract (Invest2cDAI _new_Invest2cDAIContract) onlyOwner public {
        Invest2cDAIContract = _new_Invest2cDAIContract;
    }
    
    // this function should be called should we ever want to change the portion to be invested in cDAI
    function change_cDAIAllocation(uint _numberPercentageValue) public onlyOwner {
        cDAIPercentage = _numberPercentageValue;
    }
    
    // main function which will make the investments
    function LetsInvest(address _gifteeAddress) stopInEmergency public payable returns(uint) {
        uint cDAIPortion = SafeMath.div(SafeMath.mul(msg.value,cDAIPercentage),100);
        uint iDAIPortion = SafeMath.sub(msg.value, cDAIPortion);
        require (SafeMath.sub(msg.value, SafeMath.add(cDAIPortion, iDAIPortion)) ==0 );
        Invest2cDAIContract.letsGetSomeDAI.value(cDAIPortion)(_gifteeAddress);
        Invest2FulcrumiDAIContract.LetsInvest2FulcrumiDAI.value(iDAIPortion)(_gifteeAddress);
    }
    
    
    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == owner) {
            depositETH();
        } else {
            LetsInvest(msg.sender);
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    
    function _destruct() public onlyOwner {
        selfdestruct(owner);
    }
}