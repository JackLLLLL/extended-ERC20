pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

/**
 * @title Standard ERC20 contract
 */
contract ERC20 {
    // variables determined when deploy
    string public name;             
    string public symbol; 
    uint256 public totalSupply;
    uint8 public decimals = 18; 
    uint256 constant private MAX_UINT256 = 2**256 - 1;

    // mapping
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _from, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);

    function ERC20(
        uint256 _initialSupply,
        string _tokenName,
        string _tokenSymbol
    ) public {                         
        totalSupply = _initialSupply * 10 ** uint256(decimals);     // Update total supply
        balanceOf[this] = totalSupply;

        name = _tokenName;                                          // Set the name for display purposes
        symbol = _tokenSymbol;                                      // Set the symbol for display purposes
    }

    /**
     * transfer from one address to other
     * with extra from address but not msg.sender by default
     * so it must be a private function
     * @param _from address token from this address
     * @param _to address token to this address
     * @param _value uint256 token amount
     */
    function _transfer(address _from, address _to, uint256 _value) internal {

        // check balance enough or not
        require (balanceOf[_from] >= _value);

        // check overflow
        require (balanceOf[_to] + _value > balanceOf[_to]);

        // do the transfer 
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        // emit Transfer
        emit Transfer(_from, _to, _value);
    }

    /**
     * transfer from sender
     * @param _to address token to this address
     * @param _value uint256 token amount
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // transfer from sender to _to
        _transfer(msg.sender, _to, _value);

        //
        return true;
    }

    /**
     * transfer used by smart contract
     * @param  _from address 
     * @param  _to address
     * @param  _value uint256 
     * @return success
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(allowance[_from][msg.sender] >= _value);   // Check allowance

        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * set the amount of token approved to be use by _spender
     *
     * @param _spender address who may use the tokens
     * @param _value uint256
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * set the amount of token approved to be use by _spender then callback
     * @param _spender address
     * @param _value uint256
     * @param _extraData bytes
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {

        tokenRecipient spender = tokenRecipient(_spender);
        // spender get the money
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * burn(reduce) the tokens forever
     * @param _value uint256
     */
    function burn(uint256 _value) public returns (bool success) {

        // check balance
        require(balanceOf[msg.sender] >= _value); 

        // burn
        balanceOf[msg.sender] -= _value;

        // reduce from totalSupply
        totalSupply -= _value;

        // event
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * burn tokens in other wallet
     * @param _from address
     * @param _value uint256
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {

        // check balance
        require(balanceOf[_from] >= _value);

        // check allowance
        require(allowance[_from][msg.sender] >= _value);

        // burn the token
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;

        // update
        totalSupply -= _value;

        emit Burn(_from, _value);
        return true;
    }

    // Prevents accidental sending of ether to this contract
    function() internal {
        return;     
    }
}

/**
 * Admin of contract, who can set he price of token and retrive Ether
 */
contract owned {

    // admin stores wallet address of admin
    address public admin;

     /**
      * initialization
      */
    function owned() public {
        admin = msg.sender;
    }

    /**
     * check whether sender is admin
     */
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    /**
     * assign a new admin
     * @param _newAdmin address of new admin
     */
    function transferAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }
}

/**
 * @title BeerCoin based on ERC20
 */
contract CoinCC is owned, ERC20 {

    // the price of token from Ether when ICO
    uint256 public ICOPrice;

    event AddMoney(address _from, uint256 _value, bytes32 _message);

    /**
     * initialization of CoinCC
     * @param _initialSupply uint256 amount of initial supply 
     * @param _tokenName string name of token
     * @param _tokenSymbol string symbol of token
     * @param _price uint256 price of token from ETH
     */
    function CoinCC(
        uint256 _initialSupply, 
        string _tokenName, 
        string _tokenSymbol, 
        uint256 _price
    ) ERC20 (_initialSupply, _tokenName, _tokenSymbol) public {
        // set display info

        // set ICO price
        ICOPrice = _price;
        // set admin wallet
        admin = msg.sender;                  
    }

    /**
     * transfer from one address to other
     * with extra from address but not msg.sender by default
     * so it must be a private function
     * @param _from address token from this address
     * @param _to address token to this address
     * @param _value uint256 token amount
     */
    function _transfer(address _from, address _to, uint256 _value) internal {

        // check balance enough or not
        require (balanceOf[_from] >= _value);

        // check overflow
        require (balanceOf[_to] + _value > balanceOf[_to]);

        // do the transfer 
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        // emit Transfer
        emit Transfer(_from, _to, _value);
    }

    /**
     * mint some tokens for someone in case of token lost
     * @param _target address 
     * @param _amount uint256 
     */
    function mintToken(address _target, uint256 _amount) public onlyAdmin {

        // increase token
        balanceOf[_target] += _amount;
        totalSupply += _amount;

        // token comes from somewhere
        emit Transfer(0, _target, _amount);
    }

    /**
     * buy BeerCoin directly using Ether
     */
    function buy() payable public {
        // get the amount of token
        uint256 amount = msg.value * ICOPrice;

        // transfer
        _transfer(this, msg.sender, amount);
    }

    /**
     * retrive all Ether from contract address to admin address
     */
    function retriveAllEther() public onlyAdmin {
        // get balance of contract
        uint256 amount = address(this).balance;

        //
        require(amount > 0);

        // transfer all ehter
        msg.sender.transfer(amount);
    }

    /**
     * add token into admin account, with a message for authentic
     * @param _value uint256 token amount to add into beer platform
     * @param _message bytes32
     */
    function addMoney(uint256 _value, bytes32 _message) public {
        // check if is empty message
        require(_message.length > 0);
        
        // transfer token to admin
        _transfer(msg.sender, admin, _value);

        // event
        emit AddMoney(msg.sender, _value, _message);
    }
}