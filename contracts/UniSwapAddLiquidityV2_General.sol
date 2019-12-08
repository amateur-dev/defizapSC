pragma solidity ^0.5.0;

import './OpenZepplinOwnable.sol';
import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';
import './OpenZepplinReentrancyGuard.sol';

// the objective of this contract is only to get the exchange price of the assets from the uniswap indexed

interface IuniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}


interface IuniswapExchange {
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function totalSupply() external view returns (uint256);
    function tokenAddress() external view returns (address token);
}



contract uniswapLiquidityProviderZAP is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    
    // events
    event ERC20TokenHoldingsOnConversion(uint);
    event LiquidityTokens(uint);

    
    // state variables
    uint public balance = address(this).balance;

    // in relation to the emergency functioning of this contract
    bool private stopped = false;
     
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    // - Key Addresses
    IuniswapFactory UniSwapFactoryAddress = IuniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);

    constructor() public {
        // TokenContractAddress = IERC20(_tokenContractAddress);
        // getUniSwapExchangeAddress(_tokenContractAddress);
        // TokenContractAddress.approve(address(uniswapExchangeContract),100000000000000000000000000000);
    }
   
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue) public payable stopInEmergency nonReentrant returns (uint) {
        IuniswapExchange UniSwapExchangeContractAddress = IuniswapExchange(UniSwapFactoryAddress.getExchange(_TokenContractAddress));
        IERC20 ERC20TokenAddress = IERC20(_TokenContractAddress);

        // determining the portion of the incoming ETH to be converted to the ERC20 Token
        uint conversionPortion = SafeMath.div(SafeMath.mul(msg.value, 505), 1000);
        uint non_conversionPortion = SafeMath.sub(msg.value,conversionPortion);

        // coversion of ETH to the ERC20 Token
        uint min_Tokens = SafeMath.div(SafeMath.mul((UniSwapExchangeContractAddress.getEthToTokenInputPrice(msg.value)),95),100);
        uint deadLineToConvert = SafeMath.add(now,1800);
        UniSwapExchangeContractAddress.ethToTokenSwapInput.value(msg.value)(min_Tokens,deadLineToConvert);
        uint ERC20TokenHoldings = ERC20TokenAddress.balanceOf(address(this));
        require (ERC20TokenHoldings > 0, "the conversion did not happen as planned");
        // ERC20TokenAddress.transfer(msg.sender, ERC20TokenHoldings);
        emit ERC20TokenHoldingsOnConversion(ERC20TokenHoldings);


        // adding Liquidity
        uint contractBalance = address(UniSwapExchangeContractAddress).balance;
        uint eth_reserve = SafeMath.sub(contractBalance, non_conversionPortion);
        uint token_reserve = ERC20TokenAddress.balanceOf(address(UniSwapExchangeContractAddress));
        uint token_amount = SafeMath.div(SafeMath.mul(non_conversionPortion,token_reserve),eth_reserve) + 1;
        uint max_tokens = token_amount;
        uint deadLineToAddLiquidity = SafeMath.add(now,1800);
        UniSwapExchangeContractAddress.addLiquidity.value(non_conversionPortion)(1,max_tokens,deadLineToAddLiquidity);

        // transferring Liquidity
        uint LiquityTokenHoldings = UniSwapExchangeContractAddress.balanceOf(address(this));
        emit LiquidityTokens(LiquityTokenHoldings);
        UniSwapExchangeContractAddress.transfer(_towhomtoissue, LiquityTokenHoldings);
        uint residualERC20Holdings = ERC20TokenAddress.balanceOf(address(this));
        ERC20TokenAddress.transfer(_towhomtoissue, residualERC20Holdings);
        return LiquityTokenHoldings;
    }

    
    // incase of half-way error
    function withdrawERC20Token (address _TokenContractAddress) public onlyOwner {
        IERC20 ERC20TokenAddress = IERC20(_TokenContractAddress);
        uint StuckERC20Holdings = ERC20TokenAddress.balanceOf(address(this));
        ERC20TokenAddress.transfer(_owner, StuckERC20Holdings);
    }
    
    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() public payable  onlyOwner {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            revert("Not allowed to send any ETH directly to this address");
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        _owner.transfer(address(this).balance);
    }
    
}