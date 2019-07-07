pragma solidity >=0.4.22 <0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

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

contract SuperOwner {
    address public superowner;

    constructor () public {
        superowner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == superowner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            superowner = newOwner;
        }
    }
}

contract ERC20 is IERC20, SuperOwner {
    using SafeMath for uint256;
    uint256 fee = 5e4;
    address private ownerFee;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _blackList;
    mapping (address => bool) private _admin;
    bool _pause = false;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    
    function changeOwnerFee(address newOwnerFee) public returns (bool){
        require(msg.sender == superowner, "Status: your address not process");
        ownerFee = newOwnerFee;
        return true;
    }
    function showOwnerFee() public view returns (address){
        require(msg.sender == superowner, "Status: your address not process");
        return ownerFee;
    }
    function changeFee(uint256 _changeFee) public returns (bool) {
        require(msg.sender == ownerFee, "Status: your address not process");
        fee = _changeFee;
        return true;
    }
    function showFee() public view returns (uint256){
        return fee;
    }
    function addAdmin(address admin) public returns (bool) {
        require(msg.sender == superowner && admin != superowner, "Status: cannot add");
        return _admin[admin] = true;
    }
    function deleteAdmin(address admin) public returns (bool) {
        require(msg.sender == superowner && admin != superowner, "Status: cannot add");
        return _admin[admin] = false;
    }
    function showAdmin(address admin) public view returns (bool) {
        require(msg.sender == superowner, "Status: your address not process");
        return _admin[admin];
    }
    function pause() public returns (bool) {
        require(msg.sender == superowner, "Status: your address not process");
        return _pause = true;
    }
    function unpause() public returns (bool) {
        require(msg.sender == superowner, "Status: your address not process");
        return _pause = false;
    }
    function statusPause() public view returns (bool) {
        return _pause;
    }
    function blackListAdress(address stopAddress) public returns (bool) {
        require(msg.sender == superowner || _admin[msg.sender] == true, "Status: your address not proccess");
        return _blackList[stopAddress] = true;
    }
    function deleteBlackListAddress(address activeAddress) public returns (bool) {
        require(msg.sender == superowner || _admin[msg.sender] == true, "Status: your address not proccess");
        return _blackList[activeAddress] = false;
    }
    function showBlackListAddress(address lookAddress) public view returns (bool) {
        return _blackList[lookAddress];
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function addTotalSupply(uint256 addsupply) public returns (bool) {
        require(msg.sender == superowner, "Status: your address not process");
        _mint(msg.sender, addsupply);
        return true;
    }
    function burnToken(uint256 burnValue) public returns (bool) {
        require(msg.sender == superowner, "Status: your address not process");
        _burn(msg.sender, burnValue);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Status: transfer from the zero address");
        require(recipient != address(0), "Status: transfer to the zero address");
        require(_pause == false, "Status: not proccess, but any problem or any change smart contract");
        require(_blackList[sender] != true, "Status: not process, but your address any problem");
        require(_blackList[recipient] != true, "Status: not process, but your address any problem");
        if(sender == superowner || sender == ownerFee){
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
        else{
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add((amount-fee));
            _balances[recipient] = _balances[ownerFee].add(fee);
            emit Transfer(sender, recipient, (amount-fee));
            emit Transfer(sender, ownerFee, fee);
        }
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Status: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "Status: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "Status: approve from the zero address");
        require(spender != address(0), "Status: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract tokenERC20 is ERC20, ERC20Detailed {
    uint private INITIAL_SUPPLY = 100000000000e4;
    constructor () public
    ERC20Detailed("exampleToken", "EXT", 4) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}