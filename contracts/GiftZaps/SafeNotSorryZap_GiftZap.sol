pragma solidity ^0.5.0;

import "../Ownable.sol";
import "../ReentrancyGuard.sol";
import "../SafeMath.sol";


interface Invest2cDAI {
    function letsGetSomeDAI(address _towhomtoissue) external payable;
}

interface Invest2Fulcrum {
    function LetsInvest2Fulcrum(address _towhomtoissue) external payable;
}


// through this contract we are putting 90% allocation to cDAI and 10% to 2xLongETH
contract SafeNotSorryZap is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    
    // state variables
    
    
    // - variables in relation to the percentages
    uint public cDAIAllocation = 90;
    Invest2Fulcrum public Invest2FulcrumContract = Invest2Fulcrum(0xAB58BBF6B6ca1B064aa59113AeA204F554E8fBAe);
    Invest2cDAI public Invest2cDAIContract = Invest2cDAI(0x275413360ae1B2E27C0061712d42875F8D2AC0DF);
    
    
    // - in relation to the ETH held by this contract
    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    function toggleContractActive() onlyOwner public {
    stopped = !stopped;
    }
    
    function change_cDAIAllocation(uint _numberPercentageValue) public onlyOwner {
        cDAIAllocation = _numberPercentageValue;
    }
    
    
    // this function lets you deposit ETH into this wallet 
    function LetsInvest(address _gifteeAddress) stopInEmergency payable public returns (bool) {
        uint investAmt2cDAI = SafeMath.div(SafeMath.mul(msg.value,cDAIAllocation), 100);
        uint investAmt2cFulcrum = SafeMath.sub(msg.value, investAmt2cDAI);
        require (SafeMath.sub(msg.value,SafeMath.add(investAmt2cDAI, investAmt2cFulcrum)) == 0);
        Invest2cDAIContract.letsGetSomeDAI.value(investAmt2cDAI)(_gifteeAddress);
        Invest2FulcrumContract.LetsInvest2Fulcrum.value(investAmt2cFulcrum)(_gifteeAddress);
        
    }
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
