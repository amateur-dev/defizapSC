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
}



contract UniSwapAddLiquityV3_General is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    
    // events
    event ERC20TokenHoldingsOnConversion(uint);
    event LiquidityTokens(uint);
    event Res_Tokens(uint);
    event SQRT(uint);
    event splitofinvestmentAmount(uint,uint);
    event ANS(uint);

    
    // state variables
    uint public balance = address(this).balance;

    // in relation to the emergency functioning of this contract
    bool private stopped = false;
     
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    // - Key Addresses
    IuniswapFactory public UniSwapFactoryAddress = IuniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);

    function sqrt(uint x) internal pure returns (uint){
       uint n = x / 2;
       uint lstX = 0;
       while (n != lstX){
           lstX = n;
           n = (n + x/n) / 2; 
       }
       return uint(n);
   }

    function abs(int x) internal pure returns (uint) {
        if(x < 0) {
            return uint(-x);
        }
        return uint(x);
    }
    
    function u_pow(uint x, uint p) internal pure returns (uint) {
        if(p == 0) return 1;
        if(p % 2 == 1) {
            return u_pow(x, p-1)*x;
        }
        else
        {
            return u_pow(x, p / 2)*u_pow(x, p / 2);
        }
    }
    
    function pow(int x, uint p) internal pure returns (int) {
        int r = int(u_pow(abs(x), p));
        if(p % 2 == 1) {
            return -1*r;
        }
        return r;
    }
   
    function _computation() public returns (uint) {
        address UniSwapExchangeContractAddress = 0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667;
        uint _value = 2000000000000000000;
        // determining the portion of the incoming ETH to be converted to the ERC20 Token
        uint contractBalance = UniSwapExchangeContractAddress.balance;
        // int token_reserve = int(ERC20TokenAddress.balanceOf(UniSwapExchangeContractAddress));
        // Doing the math
        uint UniPoolCharge = 300000000000000000;
        uint _2ETH = (SafeMath.mul(2,contractBalance));
        emit ANS((_2ETH));
        uint ETHf = (SafeMath.mul(contractBalance,UniPoolCharge));
        emit ANS(ETHf);
        uint _2bsquared = SafeMath.sub(ETHf,_2ETH);
        uint squared = SafeMath.mul(_2bsquared, _2bsquared);
        emit ANS(squared);
        // uint part1 = SafeMath.mul(4,contractBalance);
        // uint part2 = (1000000000000000000-UniPoolCharge);
        // uint part3 = _value;
        // uint _2Bracket = SafeMath.mul(SafeMath.mul(part1,part2),part3);
        // emit ANS(_2Bracket);
        // uint _2sqrt = SafeMath.add(squared,_2Bracket);
        // emit ANS(_2sqrt);
        // uint sqroot = sqrt(_2sqrt);
        // emit SQRT(sqroot);
        // int numerator = _2ETH-ETHf-int(sqroot);
        // emit ANS(numerator);
        // int denomiator = 2*(-1+UniPoolCharge);
        // emit ANS(denomiator);
        // uint _ans = SafeMath.div(numerator/denomiator);
        // emit ANS(_ans);
        // return _ans;
    }

    // function LetsInvest(address _TokenContractAddress, address _towhomtoissue) public payable stopInEmergency returns (uint) {
    //     IERC20 ERC20TokenAddress = IERC20(_TokenContractAddress);
    //     IuniswapExchange UniSwapExchangeContractAddress = IuniswapExchange(UniSwapFactoryAddress.getExchange(_TokenContractAddress));
    

        
    //     // uint conversionPortion = SafeMath.div(SafeMath.mul(msg.value, (5007)), 10000);
        
    //     uint conversionPortion = _computation(address(UniSwapExchangeContractAddress), ERC20TokenAddress, msg.value);
    //     uint non_conversionPortion = SafeMath.sub(msg.value,conversionPortion);
    //     emit splitofinvestmentAmount(conversionPortion,non_conversionPortion);


    //     // coversion of ETH to the ERC20 Token
    //     uint min_Tokens = SafeMath.div(SafeMath.mul(UniSwapExchangeContractAddress.getEthToTokenInputPrice(conversionPortion),95),100);
    //     uint deadLineToConvert = SafeMath.add(now,1800);
    //     UniSwapExchangeContractAddress.ethToTokenSwapInput.value(conversionPortion)(min_Tokens,deadLineToConvert);
    //     uint ERC20TokenHoldings = ERC20TokenAddress.balanceOf(address(this));
    //     ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),ERC20TokenHoldings);
    //     require (ERC20TokenHoldings > 0, "the conversion did not happen as planned");
    //     emit ERC20TokenHoldingsOnConversion(ERC20TokenHoldings);


    //     // adding Liquidity
    //     uint max_tokens_ans = getMaxTokens(address(UniSwapExchangeContractAddress), ERC20TokenAddress, non_conversionPortion);
    //     uint deadLineToAddLiquidity = SafeMath.add(now,1800);
    //     UniSwapExchangeContractAddress.addLiquidity.value(non_conversionPortion)(1,max_tokens_ans,deadLineToAddLiquidity);
    //     ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),0);

    //     // transferring Liquidity
    //     uint LiquityTokenHoldings = UniSwapExchangeContractAddress.balanceOf(address(this));
    //     emit LiquidityTokens(LiquityTokenHoldings);
    //     UniSwapExchangeContractAddress.transfer(_towhomtoissue, LiquityTokenHoldings);
    //     uint residualERC20Holdings = ERC20TokenAddress.balanceOf(address(this));
    //     ERC20TokenAddress.transfer(_towhomtoissue, residualERC20Holdings);
    //     emit Res_Tokens(residualERC20Holdings);
    // }

    function getMaxTokens(address _UniSwapExchangeContractAddress, IERC20 _ERC20TokenAddress, uint _value) internal view returns (uint) {
        uint contractBalance = address(_UniSwapExchangeContractAddress).balance;
        uint eth_reserve = SafeMath.sub(contractBalance, _value);
        uint token_reserve = _ERC20TokenAddress.balanceOf(_UniSwapExchangeContractAddress);
        uint token_amount = SafeMath.div(SafeMath.mul(_value,token_reserve),eth_reserve) + 1;
        return token_amount;
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