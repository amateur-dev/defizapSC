pragma solidity ^0.5.0;

import './OpenZepplinOwnable.sol';
import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';
import './OpenZepplinReentrancyGuard.sol';


// Interface for ETH_DAI_Addliquidity
interface UniSwapAddLiquidityZap{
    function LetsInvest() external payable returns (bool);
}

// Objectives
// - PoolsFYI users should be able to send ETH to the ETH_DAI_ZAP contract and get the UniTokens and the residual DAI tokens
// - PoolsFYI Wallet address should be able to provide a commission rate in percentage
// - PoolsFYI should receive its commission from the incomimg UniTokens
// - The commission tokens should be sent to PoolsFYI Wallet wallet address immediately 


contract ServiceProvider_UniSwap_ETH_DAI_Zap is Ownable, ReentrancyGuard {
    using SafeMath for uint;

    UniSwapAddLiquidityZap UniDAILiquidityContract = UniSwapAddLiquidityZap(0x5d389106Ae7bB313d7eC39F71D8F825Ed17D7ba1);
    IERC20 public UniSwapDAIContract = IERC20(0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667);
    IERC20 public DAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public ServiceProviderAddress = address(0xA3F19470d3Fc0c0F69bD82876bd573B592cA9597);

    uint public balance = address(this).balance;
    uint private TotalServiceChargeTokens;
    uint private serviceChargeInBasisPoints = 0;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}

    event DAILiquidityTokensReceived(uint);
    event ServiceChargeTokensTransferred(uint);
    event TransferredToUser_liquidityTokens_residualDAI(uint, uint);

    function toggleContractActive() public onlyOwner {
    stopped = !stopped;
    }

    
    // should we ever want to change the address of UniDAILiquidityContract
    function set_UniDAILiquidityContract(UniSwapAddLiquidityZap _new_UniDAILiquidityContract) public onlyOwner  {
        UniDAILiquidityContract = _new_UniDAILiquidityContract;
    }

    // should we ever want to change the address of the UniSwapDAIContract
    function set_UniSwapDAIContract (IERC20 _new_UniSwapDAIContract) public onlyOwner {
        UniSwapDAIContract = _new_UniSwapDAIContract;
    }
    
    // should we ever want to change the address of the DAI_TOKEN_ADDRESS Contract
    function set_DAI_TOKEN_ADDRESS (IERC20 _new_DAI_TOKEN_ADDRESS) public onlyOwner {
        DAI_TOKEN_ADDRESS = _new_DAI_TOKEN_ADDRESS;
    }

    // to find out the serviceChargeRate, only the Owner can call this fx
    function get_serviceChargeRate () public onlyOwner returns (uint) {
        return serviceChargeInBasisPoints;
    }

    // should the ServiceProvider ever want to change the Service Charge rate
    function set_serviceChargeRate (uint _new_serviceChargeInBasisPoints) public onlyOwner {
        serviceChargeInBasisPoints = _new_serviceChargeInBasisPoints;
    }

    // should the ServiceProvider ever want to change its wallet address
    function set_ServiceProviderAddress (address _new_ServiceProviderAddress) public onlyOwner {
        ServiceProviderAddress = _new_ServiceProviderAddress;
    }


    function LetsInvest() public payable stopInEmergency nonReentrant returns (bool) {
        //some basic checks
        require(UniDAILiquidityContract.LetsInvest.value(msg.value)(), "AddLiquidity Failed");

        // finding out the UniTokens received and the residual DAI Tokens Received
        uint DAILiquidityTokens = UniSwapDAIContract.balanceOf(address(this));
        emit DAILiquidityTokensReceived(DAILiquidityTokens);
        uint residualDAIHoldings = DAI_TOKEN_ADDRESS.balanceOf(address(this));

        // Adjusting for ServiceCharge
        uint ServiceChargeTokens = SafeMath.div(SafeMath.mul(DAILiquidityTokens,serviceChargeInBasisPoints),10000);
        TotalServiceChargeTokens = TotalServiceChargeTokens + ServiceChargeTokens;
        // Transfering of the ServiceChargeTokens
        

        // Sending Back the Balance LiquityTokens and residual DAI Tokens to user
        uint UserLiquidityTokens = SafeMath.sub(DAILiquidityTokens,ServiceChargeTokens);
        require(UniSwapDAIContract.transfer(msg.sender, UserLiquidityTokens), "Failure to send Liquidity Tokens to User");
        require(DAI_TOKEN_ADDRESS.transfer(msg.sender, residualDAIHoldings), "Failure to send residual DAI holdings");
        emit TransferredToUser_liquidityTokens_residualDAI(UserLiquidityTokens, residualDAIHoldings);
        return true;
    }

    // to find out the serviceChargeRate, only the Owner can call this fx
    function get_TotalServiceChargeTokens() public onlyOwner returns (uint) {
        return TotalServiceChargeTokens;
    }
    
    
    function withdrawServiceChargeTokens(uint _amountInUnits) public onlyOwner {
        require (_amountInUnits >= TotalServiceChargeTokens, "You are asking for more than what you have earned");
        require(UniSwapDAIContract.transfer(ServiceProviderAddress, _amountInUnits), "Failure to send ServiceChargeTokens");
        emit ServiceChargeTokensTransferred(_amountInUnits);
    }


    // Should there be a need to withdraw any other ERC20 token
    function withdrawAnyOtherERC20Token(IERC20 _targetContractAddress) public onlyOwner {
        uint OtherTokenBalance = _targetContractAddress.balanceOf(address(this));
        _targetContractAddress.transfer(ServiceProviderAddress, OtherTokenBalance);
    }
    

    // incase of half-way error
    function withdrawDAI() public onlyOwner {
        uint StuckDAIHoldings = DAI_TOKEN_ADDRESS.balanceOf(address(this));
        DAI_TOKEN_ADDRESS.transfer(_owner, StuckDAIHoldings);
    }
    
    function withdrawDAILiquityTokens() public onlyOwner {
        uint StuckDAILiquityTokens = UniSwapDAIContract.balanceOf(address(this));
        UniSwapDAIContract.transfer(_owner, StuckDAILiquityTokens);
    }

    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() public payable onlyOwner {
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
    function withdraw() public onlyOwner {
        _owner.transfer(address(this).balance);
    }


}