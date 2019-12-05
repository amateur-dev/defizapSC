pragma solidity ^0.5.0;

import './OpenZepplinOwnable.sol';
import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';

interface UniSwapAddLiquidityZap{
    function LetsInvest() external payable returns (bool);
}

contract UniSwap_SNX_DAI_ZAP is Ownable {
    using SafeMath for uint;

    UniSwapAddLiquidityZap UniSNXLiquidityContract = UniSwapAddLiquidityZap(0xD5320F3757C7db376f9f09BA7e05BA37C2BdD0Cb);
    UniSwapAddLiquidityZap UniMKRLiquidityContract = UniSwapAddLiquidityZap(0xC54dF9FBE4212289ccb4D08546BA928Cec7F9426);
    IERC20 public SNX_TOKEN_ADDRESS = IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    IERC20 public MKR_TOKEN_ADDRESS = IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    IERC20 public UniSwapMKRContract = IERC20(0x2C4Bd064b998838076fa341A83d007FC2FA50957);
    IERC20 public UniSwapSNXContract = IERC20(0x3958B4eC427F8fa24eB60F42821760e88d485f7F);


    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}

    // should we ever want to change the address of UniSNXLiquidityContract
    function set_UniSNXLiquidityContract(UniSwapAddLiquidityZap _new_UniSNXLiquidityContract) public onlyOwner {
        UniSNXLiquidityContract = _new_UniSNXLiquidityContract;
    }

    // should we ever want to change the address of UniMKRLiquidityContract
    function set_UniMKRLiquidityContract(UniSwapAddLiquidityZap _new_UniMKRLiquidityContract) public onlyOwner {
        UniMKRLiquidityContract = _new_UniMKRLiquidityContract;
    }

    // should we ever want to change the address of the SNX_TOKEN_ADDRESS
    function set_SNX_TOKEN_ADDRESS (IERC20 _new_SNX_TOKEN_ADDRESS) public onlyOwner {
        SNX_TOKEN_ADDRESS = _new_SNX_TOKEN_ADDRESS;
    }

    // should we ever want to change the address of the MKR_TOKEN_ADDRESS
    function set_MKR_TOKEN_ADDRESS (IERC20 _new_MKR_TOKEN_ADDRESS) public onlyOwner {
        MKR_TOKEN_ADDRESS = _new_MKR_TOKEN_ADDRESS;
    }


    // should we ever want to change the address of the UniSwapMKRContract
    function set_UniSwapMKRContract (IERC20 _new_UniSwapMKRContract) public onlyOwner {
        UniSwapMKRContract = _new_UniSwapMKRContract;
    }

    // should we ever want to change the address of the UniSwapSNXContract
    function set_UniSwapSNXContract (IERC20 _new_UniSwapSNXContract) public onlyOwner {
        UniSwapSNXContract = _new_UniSwapSNXContract;
    }

    function LetsInvest() payable stopInEmergency public returns (bool) {
        //some basic checks
        require (msg.value > 0.003 ether);
        
        uint MKRPortion = SafeMath.div(SafeMath.mul(msg.value, 50), 100);
        uint SNXPortion = SafeMath.sub(msg.value,MKRPortion);

        require(UniMKRLiquidityContract.LetsInvest.value(MKRPortion)(), "AddLiquidity MKR Failed");
        require(UniSNXLiquidityContract.LetsInvest.value(SNXPortion)(), "AddLiquidity SNX Failed");

        uint MKRLiquidityTokens = UniSwapMKRContract.balanceOf(address(this));
        UniSwapMKRContract.transfer(msg.sender, MKRLiquidityTokens);

        uint SNXLiquidityTokens = UniSwapSNXContract.balanceOf(address(this));
        UniSwapSNXContract.transfer(msg.sender, SNXLiquidityTokens);

        uint residualMKRHoldings = MKR_TOKEN_ADDRESS.balanceOf(address(this));
        MKR_TOKEN_ADDRESS.transfer(msg.sender, residualMKRHoldings);

        uint residualSNXHoldings = SNX_TOKEN_ADDRESS.balanceOf(address(this));
        SNX_TOKEN_ADDRESS.transfer(msg.sender, residualSNXHoldings);
        return true;
    }

    // incase of half-way error
    function withdrawMKR() public onlyOwner {
        uint StuckMKRHoldings = MKR_TOKEN_ADDRESS.balanceOf(address(this));
        MKR_TOKEN_ADDRESS.transfer(_owner, StuckMKRHoldings);
    }

    function withdrawSNX() public onlyOwner {
        uint StuckSNXHoldings = SNX_TOKEN_ADDRESS.balanceOf(address(this));
        SNX_TOKEN_ADDRESS.transfer(_owner, StuckSNXHoldings);
    }
    
    function withdrawMKRLiquityTokens() public onlyOwner {
        uint StuckMKRLiquityTokens = UniSwapMKRContract.balanceOf(address(this));
        UniSwapMKRContract.transfer(_owner, StuckMKRLiquityTokens);
    }

   function withdrawSNXLiquityTokens() public onlyOwner {
        uint StuckSNXLiquityTokens = UniSwapSNXContract.balanceOf(address(this));
        UniSwapSNXContract.transfer(_owner, StuckSNXLiquityTokens);
    }

    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest();
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
}
