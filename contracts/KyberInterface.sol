pragma solidity ^0.5.0;


import "./OpenZepplinOwnable.sol";
import "./OpenZepplinOwnable.sol";
import "./OpenZepplinSafeMath.sol";


interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface IKyberNetworkProxy {
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function trade(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId) external payable returns (uint);
}



contract KyberInterace is Ownable {
    using SafeMath for uint;
    
    // state variables
    // - setting up Imp Contract Addresses
    IKyberNetworkProxy public kyberNetworkProxyContract = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    
    // - variable for tracking the ETH balance of this contract
    uint public balance;
    
    // events
    event UnitsTransferred(uint, uint);

    // this function should be called should we ever want to change the kyberNetworkProxyContract address
    function set_kyberNetworkProxyContract(IKyberNetworkProxy _kyberNetworkProxyContract) onlyOwner public {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
    }
    
    // 
    function swap(ERC20 _TokenAddress) public payable {
        uint minConversionRate;
        uint slippageRate;
        (minConversionRate,slippageRate) = kyberNetworkProxyContract.getExpectedRate(ETH_TOKEN_ADDRESS, _TokenAddress, msg.value);
        uint destAmount = kyberNetworkProxyContract.trade.value(msg.value)(ETH_TOKEN_ADDRESS, msg.value, _TokenAddress, msg.sender, 2^255, 1, address(0x19627796b318E27C333530aD67c464Cfc37596ec));
        emit UnitsTransferred(minConversionRate, destAmount);
    }
    
    // fx, in case something goes wrong {hint! learnt from experience}
    function inCaseTokengetsStuck(ERC20 _TokenAddress) onlyOwner public {
        uint qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(_owner, qty);
    }
    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {revert();}
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
    
    function destruct() onlyOwner public{
        selfdestruct(_owner);
    }
 
}