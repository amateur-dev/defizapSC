pragma solidity ^0.5.0;

import './OpenZepplinOwnable.sol';
import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';
import './OpenZepplinReentrancyGuard.sol';


///@author DeFiZap
///@notice this contract implements one click conversion from ETH to unipool liquidity tokens (CHAI)

interface IuniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}


interface IuniswapExchange {
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
}

interface IKyberInterface {
    function swap(IERC20 src) external payable returns (uint incomingTokens);
}

interface IChaiContract {
    function join(address dst, uint wad) external;
}


contract UniSwap_ETH_CHAIZap is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    
    // events
    event ERC20TokenHoldingsOnConversionDaiChai(uint);
    event ERC20TokenHoldingsOnConversionEthDai(uint);
    event LiquidityTokens(uint);

    
    // state variables
    uint public balance = address(this).balance;
    address payable private walletId = 0x19627796b318E27C333530aD67c464Cfc37596ec;

    // in relation to the emergency functioning of this contract
    bool private stopped = false;
     
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    // - Key Addresses
    IuniswapFactory public UniSwapFactoryAddress = IuniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IKyberInterface public KyberInterfaceAddresss;
    IERC20 public NEWDAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IChaiContract public CHAI_TOKEN_ADDRESS = IChaiContract(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    
    function set_KyberInterfaceAddresss(IKyberInterface _new_KyberInterfaceAddresss) public onlyOwner {
        KyberInterfaceAddresss = _new_KyberInterfaceAddresss;
    }
    
    
    function LetsInvest(address _towhomtoissue) public payable stopInEmergency returns (uint) {
        IERC20 ERC20TokenAddress = IERC20(address(CHAI_TOKEN_ADDRESS));
        IuniswapExchange UniSwapExchangeContractAddress = IuniswapExchange(UniSwapFactoryAddress.getExchange(address(CHAI_TOKEN_ADDRESS)));
        IChaiContract ChaiTokenAddress = IChaiContract(address(CHAI_TOKEN_ADDRESS));

        // determining the portion of the incoming ETH to be converted to the ERC20 Token
        uint conversionPortion = SafeMath.div(SafeMath.mul(msg.value, 505), 1000);
        uint non_conversionPortion = SafeMath.sub(msg.value,conversionPortion);

        uint incomingTokens = KyberInterfaceAddresss.swap.value(conversionPortion)(NEWDAI_TOKEN_ADDRESS);
        
        // conversion of DAI to CHAI
        uint qty2approve = SafeMath.mul(incomingTokens, 3);
        require(NEWDAI_TOKEN_ADDRESS.approve(address(ERC20TokenAddress), qty2approve));
        ChaiTokenAddress.join(address(this), incomingTokens);
        uint ERC20TokenHoldings = ERC20TokenAddress.balanceOf(address(this));
        require (ERC20TokenHoldings > 0, "the conversion did not happen as planned");
        emit ERC20TokenHoldingsOnConversionDaiChai(ERC20TokenHoldings);
        ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),ERC20TokenHoldings);

        // adding Liquidity
        uint max_tokens_ans = getMaxTokens(address(UniSwapExchangeContractAddress), ERC20TokenAddress, non_conversionPortion);
        UniSwapExchangeContractAddress.addLiquidity.value(non_conversionPortion)(1,max_tokens_ans,SafeMath.add(now,1800));
        ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),0);

        // transferring Liquidity
        uint LiquityTokenHoldings = UniSwapExchangeContractAddress.balanceOf(address(this));
        emit LiquidityTokens(LiquityTokenHoldings);
        UniSwapExchangeContractAddress.transfer(_towhomtoissue, LiquityTokenHoldings);
        ERC20TokenHoldings = ERC20TokenAddress.balanceOf(address(this));
        ERC20TokenAddress.transfer(_towhomtoissue, ERC20TokenHoldings);
        return LiquityTokenHoldings;
    }

    function getMaxTokens(address _UniSwapExchangeContractAddress, IERC20 _ERC20TokenAddress, uint _value) internal view returns (uint) {
        uint contractBalance = address(_UniSwapExchangeContractAddress).balance;
        uint eth_reserve = SafeMath.sub(contractBalance, _value);
        uint token_reserve = _ERC20TokenAddress.balanceOf(_UniSwapExchangeContractAddress);
        uint token_amount = SafeMath.div(SafeMath.mul(_value,token_reserve),eth_reserve) + 1;
        return token_amount;
    }
    
    
    function setWalletId(address payable _walletId) public onlyOwner returns(bool){
        walletId = _walletId;
    }
    
    function getWalletId() public view returns(address){
        return walletId;
    }

    
    // incase of half-way error
    function withdrawERC20Token (address _TokenContractAddress) public onlyOwner {
        IERC20 ERC20TokenAddress = IERC20(_TokenContractAddress);
        uint StuckERC20Holdings = ERC20TokenAddress.balanceOf(address(this));
        ERC20TokenAddress.transfer(_owner, StuckERC20Holdings);
    }
    
    function set_new_CHAI_TokenContractAddress(address _new_CHAI_TokenContractAddress) public onlyOwner {
        CHAI_TOKEN_ADDRESS = IChaiContract(address(_new_CHAI_TokenContractAddress));
        
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
            LetsInvest(msg.sender);
        }
    }
    
      function toggleContractActive() onlyOwner public {
    stopped = !stopped;
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        _owner.transfer(address(this).balance);
    }
    
    function _selfDestruct() public onlyOwner {
        selfdestruct(_owner);
    }
    
}
