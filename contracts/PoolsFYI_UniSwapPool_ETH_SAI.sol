pragma solidity ^0.5.0;

import './OpenZepplinOwnable.sol';
import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';
import './OpenZepplinReentrancyGuard.sol';


// Interface for ETH_SAI_Addliquidity
interface UniSwap_Zap_Contract{
    function LetsInvest() external payable;
}

// Objectives
// - ServiceProvider's users should be able to send ETH to the UniSwap_ZAP contracts and get the UniTokens and the residual ERC20 tokens
// - ServiceProvider should have the ability to charge a commission, should is choose to do so
// - ServiceProvider should be able to provide a commission rate in percentage
// - ServiceProvider WILL receive its commission from the incomimg UniTokens
// - ServiceProvider WILL have to withdraw its commission tokens separately 


contract ServiceProvider_UniSwap_Zap is Ownable, ReentrancyGuard {
    using SafeMath for uint;

    UniSwap_Zap_Contract public UniSwap_Zap_ContractAddress;
    IERC20 public SAI_TokenContractAddress;
    IERC20 public UniSwapSAIExchangeContractAddress;
    
    address internal ServiceProviderAddress;

    uint public balance = address(this).balance;
    uint private TotalServiceChargeTokens;
    uint private serviceChargeInBasisPoints = 0;
    
    event TransferredToUser_liquidityTokens_residualSAI(uint, uint);
    event ServiceChargeTokensTransferred(uint);


    
    constructor (UniSwap_Zap_Contract _UniSwap_Zap_ContractAddress, IERC20 _SAI_TokenContractAddress, IERC20 _UniSwapSAIExchangeContractAddress, address _ServiceProviderAddress) public {
        UniSwap_Zap_ContractAddress = _UniSwap_Zap_ContractAddress;
        SAI_TokenContractAddress = _SAI_TokenContractAddress;
        UniSwapSAIExchangeContractAddress = _UniSwapSAIExchangeContractAddress;
        ServiceProviderAddress = _ServiceProviderAddress;
    }

     // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    
    
    function toggleContractActive() public onlyOwner {
    stopped = !stopped;
    }

    
    // should we ever want to change the address of ZapContractAddress
    function set_UniSwap_Zap_ContractAddress(UniSwap_Zap_Contract _new_UniSwap_Zap_ContractAddress) public onlyOwner  {
        UniSwap_Zap_ContractAddress = _new_UniSwap_Zap_ContractAddress;
    }
  
    // should we ever want to change the address of the SAI_TOKEN_ADDRESS Contract
    function set_SAI_TokenContractAddress (IERC20 _new_SAI_TokenContractAddress) public onlyOwner {
        SAI_TokenContractAddress = _new_SAI_TokenContractAddress;
    }

    // should we ever want to change the address of the _UniSwap SAIExchange Contract Address
    function set_UniSwapSAIExchangeContractAddress (IERC20 _new_UniSwapSAIExchangeContractAddress) public onlyOwner {
        UniSwapSAIExchangeContractAddress = _new_UniSwapSAIExchangeContractAddress;
    }

 
    // to get the ServiceProviderAddress, only the Owner can call this fx
    function get_ServiceProviderAddress() public onlyOwner returns (address) {
        return ServiceProviderAddress;
    }
    
    // to set the ServiceProviderAddress, only the Owner can call this fx
    function set_ServiceProviderAddress (address _new_ServiceProviderAddress) public onlyOwner  {
        ServiceProviderAddress = _new_ServiceProviderAddress;
        return serviceChargeInBasisPoints;
    }

    // to find out the serviceChargeRate, only the Owner can call this fx
    function get_serviceChargeRate () public onlyOwner returns (uint) {
        return serviceChargeInBasisPoints;
    }
    
    // should the ServiceProvider ever want to change the Service Charge rate, only the Owner can call this fx
    function set_serviceChargeRate (uint _new_serviceChargeInBasisPoints) public onlyOwner {
        serviceChargeInBasisPoints = _new_serviceChargeInBasisPoints;
    }


    function LetsInvest() public payable stopInEmergency nonReentrant returns (bool) {
        UniSwap_Zap_ContractAddress.LetsInvest.value(msg.value)();
        

        // finding out the UniTokens received and the residual SAI Tokens Received
        uint SAILiquidityTokens = UniSwapSAIExchangeContractAddress.balanceOf(address(this));
        uint residualSAIHoldings = SAI_TokenContractAddress.balanceOf(address(this));

        // Adjusting for ServiceCharge
        uint ServiceChargeTokens = SafeMath.div(SafeMath.mul(SAILiquidityTokens,serviceChargeInBasisPoints),10000);
        TotalServiceChargeTokens = TotalServiceChargeTokens + ServiceChargeTokens;
        

        // Sending Back the Balance LiquityTokens and residual SAI Tokens to user
        uint UserLiquidityTokens = SafeMath.sub(SAILiquidityTokens,ServiceChargeTokens);
        require(UniSwapSAIExchangeContractAddress.transfer(msg.sender, UserLiquidityTokens), "Failure to send Liquidity Tokens to User");
        require(SAI_TokenContractAddress.transfer(msg.sender, residualSAIHoldings), "Failure to send residual SAI holdings");
        emit TransferredToUser_liquidityTokens_residualSAI(UserLiquidityTokens, residualSAIHoldings);
        return true;
    }

    // to find out the serviceChargeRate, only the Owner can call this fx
    function get_TotalServiceChargeTokens() public onlyOwner returns (uint) {
        return TotalServiceChargeTokens;
    }
    
    
    function withdrawServiceChargeTokens(uint _amountInUnits) public onlyOwner {
        require (_amountInUnits >= TotalServiceChargeTokens, "You are asking for more than what you have earned");
        require(UniSwapSAIExchangeContractAddress.transfer(ServiceProviderAddress, _amountInUnits), "Failure to send ServiceChargeTokens");
        emit ServiceChargeTokensTransferred(_amountInUnits);
    }


    // Should there be a need to withdraw any other ERC20 token
    function withdrawAnyOtherERC20Token(IERC20 _targetContractAddress) public onlyOwner {
        uint OtherTokenBalance = _targetContractAddress.balanceOf(address(this));
        _targetContractAddress.transfer(_owner, OtherTokenBalance);
    }
    

    // incase of half-way error
    function withdrawSAI() public onlyOwner {
        uint StuckSAIHoldings = SAI_TokenContractAddress.balanceOf(address(this));
        SAI_TokenContractAddress.transfer(_owner, StuckSAIHoldings);
    }
    
    function withdrawSAILiquityTokens() public onlyOwner {
        uint StuckSAILiquityTokens = UniSwapSAIExchangeContractAddress.balanceOf(address(this));
        UniSwapSAIExchangeContractAddress.transfer(_owner, StuckSAILiquityTokens);
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