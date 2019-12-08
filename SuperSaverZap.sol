
// File: contracts/Ownable.sol

pragma solidity >0.4.0 <0.6.0;

contract Ownable {

  address payable public owner;

  constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  
  function transferOwnership(address payable newOwner) external onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

// File: contracts/ReentrancyGuard.sol

pragma solidity ^0.5.0;

contract ReentrancyGuard {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// File: contracts/SafeMath.sol

pragma solidity ^0.5.0;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/SuperSaverZap.sol

pragma solidity ^0.5.0;





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
    function set_Invest2cDAIContract (Invest2cDAI _Invest2cDAIContract) onlyOwner public {
        _Invest2cDAIContract = _Invest2cDAIContract;
    }
    
    // this function should be called should we ever want to change the portion to be invested in cDAI
    function change_cDAIAllocation(uint _numberPercentageValue) public onlyOwner {
        cDAIPercentage = _numberPercentageValue;
    }
    
    // main function which will make the investments
    function LetsInvest() public payable returns(uint) {
        require (msg.value > 100000000000000);
        require (msg.sender != address(0));
        uint invest_amt = msg.value;
        address payable investor = address(msg.sender);
        uint cDAIPortion = SafeMath.div(SafeMath.mul(invest_amt,cDAIPercentage),100);
        uint iDAIPortion = SafeMath.sub(invest_amt, cDAIPortion);
        require (SafeMath.sub(invest_amt, SafeMath.add(cDAIPortion, iDAIPortion)) ==0 );
        Invest2cDAIContract.letsGetSomeDAI.value(cDAIPortion)(investor);
        Invest2FulcrumiDAIContract.LetsInvest2FulcrumiDAI.value(iDAIPortion)(investor);
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
            LetsInvest();
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    
}
