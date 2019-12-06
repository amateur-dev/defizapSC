pragma solidity ^0.5.0;


import "./OpenZepplinOwnable.sol";
import "./OpenZepplinOwnable.sol";
import "./OpenZepplinSafeMath.sol";
import "./OpenZepplinIERC20.sol";

interface IKyberNetworkProxy {
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function tradeWithHint(IERC20 src, uint srcAmount, IERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);
    function swapEtherToToken(IERC20 token, uint minRate) external payable returns (uint);
}



interface Compound {
    function approve (address spender, uint256 amount ) external returns ( bool );
    function mint ( uint256 mintAmount ) external returns ( uint256 );
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint _value) external returns (bool success);
}


contract Invest2cDAI_NEW is Ownable {
    using SafeMath for uint;
    
    // state variables
    // - setting up Imp Contract Addresses
    IKyberNetworkProxy public kyberNetworkProxyContract = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IERC20 constant public ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    IERC20 public NEWDAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    Compound public COMPOUND_TOKEN_ADDRESS = Compound(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    
    // - variable for tracking the ETH balance of this contract
    uint public balance;
    
    // events
    event UnitsReceivedANDSentToAddress(uint, address);

    // this function should be called should we ever want to change the kyberNetworkProxyContract address
    function set_kyberNetworkProxyContract(IKyberNetworkProxy _kyberNetworkProxyContract) onlyOwner public {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
    }
    
    // this function should be called should we ever want to change the NEWDAI_TOKEN_ADDRESS
    function set_NEWDAI_TOKEN_ADDRESS(IERC20 _NEWDAI_TOKEN_ADDRESS) onlyOwner public {
        NEWDAI_TOKEN_ADDRESS = _NEWDAI_TOKEN_ADDRESS;
    }
    // this function should be called should we ever want to change the COMPOUND_TOKEN_ADDRESS 
    function set_COMPOUND_TOKEN_ADDRESS(Compound _COMPOUND_TOKEN_ADDRESS) onlyOwner public {
        COMPOUND_TOKEN_ADDRESS = _COMPOUND_TOKEN_ADDRESS;
    }
    
    
    // 
    function LetsInvest(address _towhomtoissue) public payable {
        uint minConversionRate;
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(ETH_TOKEN_ADDRESS, NEWDAI_TOKEN_ADDRESS, msg.value);
        uint destAmount = kyberNetworkProxyContract.swapEtherToToken.value(msg.value)(NEWDAI_TOKEN_ADDRESS, minConversionRate);
        uint qty2approve = SafeMath.mul(destAmount, 3);
        require(NEWDAI_TOKEN_ADDRESS.approve(address(COMPOUND_TOKEN_ADDRESS), qty2approve));
        COMPOUND_TOKEN_ADDRESS.mint(destAmount); 
        uint cDAI2transfer = COMPOUND_TOKEN_ADDRESS.balanceOf(address(this));
        require(COMPOUND_TOKEN_ADDRESS.transfer(_towhomtoissue, cDAI2transfer));
        require(NEWDAI_TOKEN_ADDRESS.approve(address(COMPOUND_TOKEN_ADDRESS), 0));
        emit UnitsReceivedANDSentToAddress(cDAI2transfer, _towhomtoissue);
    }
    
    // fx, in case something goes wrong {hint! learnt from experience}
    function inCaseDAI_NEWgetsStuck() onlyOwner public {
        uint qty = NEWDAI_TOKEN_ADDRESS.balanceOf(address(this));
        NEWDAI_TOKEN_ADDRESS.transfer(_owner, qty);
    }
    
    function inCaseC_DAIgetsStuck() onlyOwner public {
        uint CDAI_qty = COMPOUND_TOKEN_ADDRESS.balanceOf(address(this));
        COMPOUND_TOKEN_ADDRESS.transfer(_owner, CDAI_qty);
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
        } else {
            LetsInvest(msg.sender);
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
 
}