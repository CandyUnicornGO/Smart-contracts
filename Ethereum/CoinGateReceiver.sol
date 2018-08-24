pragma solidity 0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public manager;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
        manager = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function setManager(address _newManager) public onlyOwner {
        require(_newManager != address(0));
        manager = _newManager;
    }
}

contract DividendManagerInterface {
    function payDividend() external payable;
}

contract CoinGateReceiver is Ownable {
    address public dividendManagerAddress;

    constructor(address _dividendManager) public {
        require(_dividendManager != address(0));
        dividendManagerAddress = _dividendManager;
    }

    function() payable public {}


    function setDividendManager(address _dividendManager) onlyOwner public {
        require(_dividendManager != address(0));
        dividendManagerAddress = _dividendManager;
    }


    function transferDividends() onlyManager public {
        require(address(this).balance >= 0);
        DividendManagerInterface dividendManager = DividendManagerInterface(dividendManagerAddress);
        dividendManager.payDividend.value(address(this).balance)();
    }

}

