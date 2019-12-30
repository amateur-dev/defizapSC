// Copyright (C) 2019, 2020 dipeshsukhani, nodarjonashi, toshsharma, suhailg

pragma solidity ^0.5.13;

import "./OpenZepplinOwnable.sol";
import "./OpenZepplinReentrancyGuard.sol";
import './OpenZepplinIERC20.sol';
import "./OpenZepplinSafeMath.sol";



// this is the underlying contract that invests in 2xLongETH on Fulcrum
interface Invest2Fulcrum2xLongETH {
    function LetsInvest2Fulcrum(address _towhomtoissue) external payable;
}

interface UniSwapAddLiquityV2_General {
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue) external payable returns (uint);
}


// through this contract we are putting 33% allocation to 2xLongETH and 67% to Uniswap pool
contract PoolBullZap is Ownable {
    using SafeMath for uint;
    //events
    
    // state variables

    // - variables in relation to the percentages
    uint public ETH2xLongPercentage = 33;
    // - in relation to the ETH held by this contract
    uint public balance = address(this).balance;
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    // - Key Addresses
    Invest2Fulcrum2xLongETH public Invest2Fulcrum2xLong_ETHContract = Invest2Fulcrum2xLongETH(0xAB58BBF6B6ca1B064aa59113AeA204F554E8fBAe);
    UniSwapAddLiquityV2_General public UniSwapAddLiquityV2_GeneralAddress =
    UniSwapAddLiquityV2_General(0x606563f8DC27F316b77F22d14D9Cd025B4F70469);
    address public NEW_DAI_TOKEN_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // this function should be called if we ever want to change the ETH2xLongPercentage
    function changeETH2xLongPercentage (uint _percentage) public onlyOwner{
        ETH2xLongPercentage = _percentage;
    }
    // this function should be called if we ever want to change the ERC20 token address
    function changeTokenAddress(address _tokenAddress) public onlyOwner {
        NEW_DAI_TOKEN_ADDRESS = _tokenAddress;
    }
    // this function should be called should we ever want to change the underlying Kyber Interface Contract address
    function set_UniswapAddLiquidityAddress(UniSwapAddLiquityV2_General _new_UniswapAddress) public onlyOwner {
        UniSwapAddLiquityV2_GeneralAddress = _new_UniswapAddress;
    }
    // this function should be called should we ever want to change the underlying Fulcrum Long ETHContract address
    function set_Invest2Fulcrum2xLong_ETHContract (Invest2Fulcrum2xLongETH _Invest2Fulcrum2xLong_ETHContract) onlyOwner public {
        Invest2Fulcrum2xLong_ETHContract = _Invest2Fulcrum2xLong_ETHContract;
    }
    // main function which will make the investments
    function LetsInvest(address payable _towhomtoissue) public payable returns(uint) {
        require (msg.value > 100000000000000);
        require (msg.sender != address(0));
        uint invest_amt = msg.value;
        address payable investor = _towhomtoissue;
        //Determine ETH 2x Long and Uniswap portions
        uint ETH2xLongPortion = SafeMath.div(SafeMath.mul(invest_amt,ETH2xLongPercentage),100);
        uint UniswapPortion = SafeMath.sub(invest_amt, ETH2xLongPortion);
        require (SafeMath.sub(invest_amt, SafeMath.add(UniswapPortion, ETH2xLongPortion)) == 0 );
        // Invest Uniswap portion
        UniSwapAddLiquityV2_GeneralAddress.LetsInvest.value(UniswapPortion)(NEW_DAI_TOKEN_ADDRESS, investor);
        // Invest ETH 2x Long portion
        Invest2Fulcrum2xLong_ETHContract.LetsInvest2Fulcrum.value(ETH2xLongPortion)(investor);
    }
    // fx in relation to ETH held by the contract sent by the owner
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    // fallback function let you / anyone send ETH to this wallet without the need to call any function
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
    
    function _destruct() public onlyOwner {
        selfdestruct(_owner);
    }
}
