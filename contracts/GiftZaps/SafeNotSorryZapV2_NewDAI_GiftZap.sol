pragma solidity ^0.5.0;

import "../OpenZepplinOwnable.sol";
import "../OpenZepplinReentrancyGuard.sol";
import "../OpenZepplinSafeMath.sol";


interface Invest2cDAI_NEW {
    function LetsInvest(address _towhomtoissue) external payable;
}

interface Invest2Fulcrum {
    function LetsInvest2Fulcrum(address _towhomtoissue) external payable;
}


// through this contract we are putting UserProvided allocation to cDAI and to 2xLongETH
contract SafeNotSorryZapV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    
    // state variables
    
    
    // - variables in relation to the percentages
    Invest2Fulcrum public Invest2FulcrumContract = Invest2Fulcrum(0xAB58BBF6B6ca1B064aa59113AeA204F554E8fBAe);
    Invest2cDAI_NEW public Invest2cDAI_NEWContract = Invest2cDAI_NEW(0x1FE91B5D531620643cADcAcc9C3bA83097c1B698);
    
    
    // - in relation to the ETH held by this contract
    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;
    
    // this function should be called should we ever want to change the underlying Fulcrum Long ETHContract address
    function set_Invest2FulcrumContract (Invest2Fulcrum _Invest2FulcrumContract) onlyOwner public {
        Invest2FulcrumContract = _Invest2FulcrumContract;
    }
    
    // this function should be called should we ever want to change the underlying Fulcrum Long ETHContract address
    function set_Invest2cDAI_NEWContract (Invest2cDAI_NEW _Invest2cDAI_NEWContract) onlyOwner public {
        Invest2cDAI_NEWContract = _Invest2cDAI_NEWContract;
    }
    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}

    
    function toggleContractActive() onlyOwner public {
    stopped = !stopped;
    }

    function LetsInvest(uint _allocationToCDAI_new, address _gifteeAddress) stopInEmergency nonReentrant payable public returns (bool) {
        require(_allocationToCDAI_new < 100, "Wrong Allocation");
        uint investAmt2cDAI_NEW = SafeMath.div(SafeMath.mul(msg.value,_allocationToCDAI_new), 100);
        uint investAmt2cFulcrum = SafeMath.sub(msg.value, investAmt2cDAI_NEW);
        require (SafeMath.sub(msg.value,SafeMath.add(investAmt2cDAI_NEW, investAmt2cFulcrum)) == 0);
        Invest2cDAI_NEWContract.LetsInvest.value(investAmt2cDAI_NEW)(_gifteeAddress);
        Invest2FulcrumContract.LetsInvest2Fulcrum.value(investAmt2cFulcrum)(_gifteeAddress);
        return true;
        
    }
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest(90, msg.sender);
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
    function _destruct() public onlyOwner {
        selfdestruct(_owner);
    }

}
