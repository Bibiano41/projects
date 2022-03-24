/**
 *Submitted for verification at BscScan.com on 2021-07-03
*/

// FALTA O FRONT RUNNER
// FALTA TRANSFERENCIA CARTEIRA MARKETING
// FALTA SET ROUTER

// FUNCCAO SOLTA ( NAO ERA PRA DEPLOYAR CARALHO )
// TRANSFER PARA CONTA ( FUNCAO SOLTA, NAO ERA PRA DEPLOYAR )
// PANCAKESWAP ALTERA OS ROUTERS E PARA DE ARRECADAR ( NAO SABIA QUE IAM DEPLOYAR )
// EU TO POR TRAS DISSO, VCS CHEGAM E FAZ DEPLOY DA PARADA SEM CONSULTA
// DE QUEM TA POR TRAS DO NEGOCIO, TEM QUE SE FUDER

// IA REALIZAR OS TESTES




pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage); uint256 c = a - b; return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0; uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() external virtual onlyOwner() {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) external virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }




}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline)  external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


abstract contract ERC20 is IERC20 {

    uint8 private _decimals = 9;
    string private _name = "S0S Amazonia Token";
    string private _symbol = "SOSAMZ";

        function name() external view returns (string memory) { 
        return _name; 
    }

    function symbol() external view returns (string memory) { 
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals; 
    }

}


contract SOSAMZ is Context, ERC20, Ownable {
    
    using SafeMath for uint256;

    uint256 private constant MAXIMUM_VALUE = ~uint256(0);
    uint256 private constant _totalSupply = 100 * 10**6 * 10**9; // 100 MI
    
    mapping (address => uint256) private _totalTopSupply; // == REFLECTIONS !
    mapping (address => uint256) private _totalMiddleSupply; 
    uint256 private _totalBottomSupply = (MAXIMUM_VALUE - (MAXIMUM_VALUE % _totalSupply)); 

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private _totalFees;
    
    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 3;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _companyFee = 3;
    uint256 private _previousCompanyFee = _companyFee;
    address public _companyAddress;
    
    uint256 private numTokensSellToAddToLiquidity = 50000 * (10 ** 9); // 200k
    // uint256 private numTokensSellToAddToEarn = 50000 * ( 10 ** 9);
    uint256 public _maxTxAmount =_totalSupply; 

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool public EJECT_PROTOCOL = false;
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    

    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify( uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity );
    event ProtocolChanged( uint256 block, bool ejectProtocol );
    event ManualWithdrawToLiquify( address owner, uint256 ethReceived );

    modifier feePolicy(bool freeFee) {
        if(freeFee){
            removeAllFee();
            _;
            restoreAllFee();
        } else {
            _;
        }
    }
    
    bool swapping = false;
    modifier lockToSwapping { swapping = true; _; swapping = false; }
    
    // modifier lockTheSwapToLiquify { inSwapAndLiquify = true; _; inSwapAndLiquify = false; }
    
    constructor () public {

        // CHANGE BELOW FOR PRODUCTION

        address routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

        // CHANGE BELOW FOR PRODUCTION

        // address 1
        _totalTopSupply[_msgSender()] = _totalBottomSupply.div(2); 

        // address 4
        _totalTopSupply[0xB9286827F43617a8d061ab95C1678B83aE8155eE] = _totalBottomSupply.div(2); 
        
        // address 5
        _companyAddress = 0xAfF7EB6a4824BA6D0707D1736b04fa86359Ef6e3; 

        // CHANGE ABOVE FOR PRODUCTION  

                //     

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress); // https://pancake.kiemtienonline360.com/

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        uniswapV2Router = _uniswapV2Router;


        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }



    function totalSupply() external view override returns (uint256) { 
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount); return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount); return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "<0"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function totalFees() external view returns (uint256) {
        return _totalFees;
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }
    
    // control 00
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() { 
        require( taxFee < 21 );
        _taxFee = taxFee; 
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require( liquidityFee < 21 );
        _liquidityFee = liquidityFee;
    }
    
    // control 01
    
    function setCampaignFeePercent(uint256 campaignFee) external onlyOwner() { 
        require( campaignFee < 21 );
        _companyFee = campaignFee; 
    }
    
    function setCampaignAddress(address _campaign_address) external onlyOwner() { 
        _companyAddress = _campaign_address; 
    }

    // control 02
    
    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }
    
    // control 03
    
    function excludeFromReward(address account) external onlyOwner() {
        
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Swap router.');
        
        require(_isExcluded[account] == false, "Already excluded");
        
        if(_totalTopSupply[account] > 0) {
            
            _totalMiddleSupply[account] = _getTokens(_totalTopSupply[account]);
        
        }
        
        _isExcluded[account] = true;
        
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        
        require(_isExcluded[account] == true, "Already included");
        
        for (uint256 i = 0; i < _excluded.length; i++) {
            
            if (_excluded[i] == account) {
                
                _excluded[i] = _excluded[_excluded.length - 1];
                
                _totalMiddleSupply[account] = 0;
                
                _isExcluded[account] = false;
                
                _excluded.pop();
                
                break;
            }
        }
    }
    
    // control 04

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _companyFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCompanyFee = _companyFee;
        _taxFee = 0;
        _liquidityFee = 0;
        _companyFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _companyFee = _previousCompanyFee;
    }
    
    // control 05 
    
     function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
         require( maxTxPercent != 0 ); // very important require 
        _maxTxAmount = _totalSupply.mul(maxTxPercent).div( 10**2 );
    }
    
    // external

    function burnTokensAndIncreaseReward(uint256 _tAmount) external {
        
        address sender = _msgSender();
        
        require(_isExcluded[sender] == false);
        
        uint256 _amount = _getAmountREFLECTIONS(_tAmount);
        
        _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
        
        _totalBottomSupply = _totalBottomSupply.sub(_amount);
        
        _totalFees = _totalFees.add(_tAmount);

    }

    // helpers 00
    
    function calculatePercent( uint256 _tAmount, uint _scopeFee ) private pure returns (uint256) {
        return _tAmount.mul(_scopeFee).div( 10 ** 2 );
    }
    

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _totalMiddleSupply[account]; // fridge
        return _getTokens(_totalTopSupply[account]);
    }

    function _getTokens(uint256 _amount) private view returns(uint256) {
        require(_amount <= _totalBottomSupply, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return  _amount.div(currentRate);
    }

    // GET'S

    function _getAmountREFLECTIONS(uint256 _amount) private view returns(uint256){
        return _amount.mul(_getRate());
    }

    function _getRate() private view returns(uint256) {
        (uint256 bottomSupply, uint256 tokenSupply) = _getCurrentSupply();
        return bottomSupply.div(tokenSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 bottomSupply = _totalBottomSupply;
        uint256 tSupply = _totalSupply;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_totalTopSupply[_excluded[i]] > bottomSupply || _totalMiddleSupply[_excluded[i]] > tSupply) return (_totalBottomSupply, _totalSupply);
            bottomSupply = bottomSupply.sub(_totalTopSupply[_excluded[i]]);
            tSupply = tSupply.sub(_totalMiddleSupply[_excluded[i]]);
        }
        if (bottomSupply < _totalBottomSupply.div(_totalSupply)) return (_totalBottomSupply, _totalSupply);
        return (bottomSupply, tSupply);
    }

    // 
    
    receive() external payable {}
    
    function _taxValues( uint256 _tAmount, uint256 currentRate ) private view returns( uint256, uint256) {
            uint _tAmountTax = calculatePercent( _tAmount , _taxFee );
            uint _amountTax = _tAmountTax.mul( currentRate );
            return ( _amountTax , _tAmountTax );
    }
    
    function _liquidityValues(  uint256 _tAmount , uint256 currentRate ) private view returns( uint256, uint256) {
            uint _tAmountLiq = calculatePercent( _tAmount , _liquidityFee );
            uint _amountLiq = _tAmountLiq.mul( currentRate );
            return ( _amountLiq , _tAmountLiq );
    }

    function _campaignValues( uint256 _tAmount, uint256 currentRate ) private view returns( uint256, uint256) {
            uint _tAmountCamp = calculatePercent( _tAmount , _companyFee );
            uint _amountCamp = _tAmountCamp.mul( currentRate );
            return ( _amountCamp , _tAmountCamp );
    }

    bool public swapAndEarnEnabled = true;
    bool private inSwapAndEarn;

    modifier lockSwapToEarn { inSwapAndEarn = true; _; inSwapAndEarn = false;}

    // TRANSFER CONCERNS //

    
    function _transfer( address from, address to, uint256  tAmount ) private {
        
        require(from != address(0), "ERC20: transfer from the zero address");
        
        require(to != address(0), "ERC20: transfer to the zero address");
        
        require( tAmount > 0, "Transfer amount must be greater than zero");
        
        if(from != owner() && to != owner()) {
            require( tAmount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        
        
        if(EJECT_PROTOCOL == false){

                uint256 contractTokenBalance = balanceOf(address(this));
                
                if(contractTokenBalance >= _maxTxAmount) {
                    contractTokenBalance = _maxTxAmount;
                }

        
                bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
                

                if ( overMinTokenBalance && !swapping && from != uniswapV2Pair && swapAndLiquifyEnabled ) {
                    
                    contractTokenBalance = numTokensSellToAddToLiquidity;
                  
                    swapAndLiquify(contractTokenBalance);
                }
               
                
                bool freeFee;
        
                if(_isExcludedFromFee[from] || _isExcludedFromFee[to] ){
                    freeFee = true;
                }
                 _transferPipeline(from ,to , tAmount ,freeFee);

            
        } else {

                _transferPipeline(from ,to , tAmount ,true);

        }
        
        
       
    }
    
    
    
    function ejectProtocol() external onlyOwner() {
        EJECT_PROTOCOL = true;    
        emit ProtocolChanged( block.number , true );
    }
    
    function revertProtocol() external onlyOwner(){
        EJECT_PROTOCOL = false;
        emit ProtocolChanged( block.number , false );
    }
      

    function _transferPipeline(address sender, address recipient, uint256 _tAmount,bool freeFee) private feePolicy(freeFee) {
        
        if(freeFee) {
          return _freeFeeTransfer(sender,recipient, _tAmount);
        }
        
        
        uint256 current_rate = _getRate();
        
        if( !_isExcluded[sender] && !_isExcluded[recipient]){
            
            return _transferStandard(sender,recipient, _tAmount , current_rate );
            
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            
            return _transferToExcluded(sender, recipient, _tAmount , current_rate );
        
        } else if ( _isExcluded[sender] && !_isExcluded[recipient] ) {
            
            return _transferFromExcluded(sender, recipient, _tAmount, current_rate );
            
        } else {
            
            return _transferBothExcluded(sender, recipient, _tAmount, current_rate );
             
        }
        
     
    }
    
    function _getFeeValuesForOneTransfer(uint256 _tAmount, uint256 currentRate ) private view returns( uint256 , uint256 , uint256 , uint256, uint256 , uint256 ) {
        
        ( uint _amountTax, uint _tAmountTax ) = _taxValues( _tAmount,  currentRate );

        ( uint _amountLiq , uint _tAmountLiq ) = _liquidityValues( _tAmount, currentRate );
        
        ( uint _amountCamp, uint _tAmountCamp ) = _campaignValues( _tAmount,  currentRate );
         
        return ( _amountTax , _tAmountTax, _amountLiq , _tAmountLiq , _amountCamp , _tAmountCamp );
        
    }
    
    function _freeFeeTransfer(address sender, address recipient, uint256 _tAmount) private {
    
        uint256 _amount = _tAmount.mul(_getRate()); 
        
        if( !_isExcluded[sender] && !_isExcluded[recipient] ){
            _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
            _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount);
             emit Transfer(sender, recipient, _tAmount); 
            return;
            
        } else if( !_isExcluded[sender] && _isExcluded[recipient] ){
            _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
            _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount);
            _totalMiddleSupply[recipient] = _totalMiddleSupply[recipient].add(_tAmount);
             emit Transfer(sender, recipient, _tAmount); 
            return;
            
        } else if( _isExcluded[sender] && !_isExcluded[recipient] ){
            _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
            _totalMiddleSupply[sender] = _totalMiddleSupply[sender].sub(_tAmount);
            _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount);
             emit Transfer(sender, recipient, _tAmount); 
         
            return;
        } else {
            _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
            _totalMiddleSupply[sender] = _totalMiddleSupply[sender].sub(_tAmount);
            _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount);
            _totalMiddleSupply[recipient] = _totalMiddleSupply[recipient].add(_tAmount);
             emit Transfer(sender, recipient, _tAmount); 
            return;
        }  
    }

    function _transferStandard(address sender, address recipient, uint256 _tAmount ,uint256 current_rate ) private {
     
      uint256 _amount = _tAmount.mul(current_rate); 

      ( uint _amountTax, uint _tAmountTax , uint _amountLiq , uint _tAmountLiq, uint _amountCamp, uint _tAmountCamp  ) = _getFeeValuesForOneTransfer( _tAmount, current_rate );
      
    _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);

    _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount.sub(_amountLiq).sub(_amountTax).sub(_amountCamp));

      deductions( _amountTax , _tAmountTax ,_amountLiq , _tAmountLiq ,  _amountCamp,  _tAmountCamp );
    
     uint _tAmountSubtracted = _tAmount.sub(_tAmountLiq).sub(_tAmountTax).sub(_tAmountCamp);
    
      emit Transfer( sender, recipient, _tAmountSubtracted );
 
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 _tAmount ,  uint256 current_rate ) private {
     
      uint256 _amount = _tAmount.mul(current_rate); 

      ( uint _amountTax, uint _tAmountTax  , uint _amountLiq , uint _tAmountLiq, uint _amountCamp, uint _tAmountCamp ) = _getFeeValuesForOneTransfer( _tAmount, current_rate );


      _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);


      _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount.sub(_amountLiq).sub(_amountTax).sub(_amountCamp));

      uint _tAmountSubtracted = _tAmount.sub(_tAmountLiq).sub(_tAmountTax).sub(_tAmountCamp);

      _totalMiddleSupply[recipient] =  _totalMiddleSupply[recipient].add(_tAmountSubtracted);
      
      deductions(  _amountTax , _tAmountTax,_amountLiq , _tAmountLiq, _amountCamp, _tAmountCamp  );
    
      emit Transfer(sender, recipient, _tAmountSubtracted ); 
     }
     
    function _transferFromExcluded(address sender, address recipient, uint256 _tAmount ,  uint256 current_rate ) private {

      uint256 _amount = _tAmount.mul(current_rate); 

      ( uint _amountTax, uint _tAmountTax , uint _amountLiq , uint _tAmountLiq, uint _amountCamp, uint _tAmountCamp  ) = _getFeeValuesForOneTransfer( _tAmount, current_rate );

      _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
      
      _totalMiddleSupply[sender] =  _totalMiddleSupply[sender].sub(_tAmount);

      _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount.sub(_amountLiq).sub(_amountTax).sub(_amountCamp));
      
      deductions( _amountTax , _tAmountTax ,_amountLiq , _tAmountLiq, _amountCamp, _tAmountCamp );

      uint _tAmountSubtracted = _tAmount.sub(_tAmountLiq).sub(_tAmountTax).sub(_tAmountCamp);

      emit Transfer(sender, recipient, _tAmountSubtracted); 
     }
    
    function _transferBothExcluded(address sender, address recipient, uint256 _tAmount,  uint256 current_rate ) private {

      uint256 _amount = _tAmount.mul(current_rate); 

      ( uint _amountTax, uint _tAmountTax , uint _amountLiq , uint _tAmountLiq, uint _amountCamp, uint _tAmountCamp  ) = _getFeeValuesForOneTransfer( _tAmount, current_rate );

      _totalTopSupply[sender] = _totalTopSupply[sender].sub(_amount);
      
      _totalMiddleSupply[sender] =  _totalMiddleSupply[sender].sub(_tAmount);
      
      _totalTopSupply[recipient] = _totalTopSupply[recipient].add(_amount.sub(_amountLiq).sub(_amountTax).sub(_amountCamp));


     uint _tAmountSubtracted = _tAmount.sub(_tAmountLiq).sub(_tAmountTax).sub(_tAmountCamp);

     _totalMiddleSupply[recipient] =  _totalMiddleSupply[recipient].add(_tAmountSubtracted);
      
     deductions( _amountTax , _tAmountTax ,_amountLiq , _tAmountLiq, _amountCamp, _tAmountCamp );
    
      emit Transfer(sender, recipient, _tAmountSubtracted); 
     }

    function deductions(  uint _amountTax , uint _tAmountTax, uint _amountLiq, uint _tAmountLiq, uint _amountCamp, uint _tAmountCamp ) private {
         _reflectFee(_amountTax, _tAmountTax);
         _setLiquidity( _amountLiq.add(_amountCamp), _tAmountLiq.add(_tAmountCamp));
        //  _setCompany(_amountCamp, _tAmountCamp );
    }

    function _reflectFee(uint256 _amount, uint256 _tAmount) private {
        _totalBottomSupply = _totalBottomSupply.sub( _amount );
        _totalFees = _totalFees.add( _tAmount );
    }
    
    function _setLiquidity(uint256 _amount, uint _tAmount ) private {
        _totalTopSupply[address(this)] = _totalTopSupply[address(this)].add(_amount);
        if(_isExcluded[address(this)]){
            _totalMiddleSupply[address(this)] = _totalMiddleSupply[address(this)].add(_tAmount);
        }        
    }
    
    // SWAP CONCERNS //
    
    // Creates a Withdraw function to fixed a bad behavior from the Swap logic legacy 
    // More about this error in our legacy code SSS-O3 Page 11 -> https://certik-public-assets.s3.amazonaws.com/CertiK+Audit+Report+for+SafeMoon.pdf
    
    // An event is emitted and the withdraw resources is set at liquidity pool manually.
    // How the execution of each transaction already sends the balances direct to the pool liquidity, doesnt
    // have the risk of acummulates a lot BNB's on the contract and only the remains of BNB, which were not able to enter the pool
    
    function withdrawToManualLiquify() external onlyOwner() {
        (bool success,) = _msgSender().call{ value: address(this).balance }("");
        require(success, "Withdraw failed.");
        emit ManualWithdrawToLiquify( _msgSender() , address(this).balance );
    }
    
     function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

        function setSwapAndEarnEnabled(bool _enabled) public onlyOwner {
        swapAndEarnEnabled = _enabled;
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockToSwapping {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance.div(2));

        (bool success,) = _companyAddress.call{ value: newBalance.div(2)}("");
        //
        require(success,"FAILED TO TRANSFER ETH FOR COMPANY");
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    


    // NOT MISSING MORE!!
    function setRouterAddress(address newRouter) public onlyOwner() {
     
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        
        uniswapV2Router = _newPancakeRouter;
    }

   


    

}
