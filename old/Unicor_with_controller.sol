pragma solidity ^0.4.18;

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract ERC721 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint balance);

    function ownerOf(uint256 _tokenId) public constant returns (address owner);
    function owns(address _claimant, uint256 _tokenId) public view returns (bool);
    function approve(address _to, uint256 _tokenId) public;
    function allowance(address _claimant, uint256 _tokenId) public view returns (bool);

    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

}


contract UnicornBase is ERC721  {

    event Birth(address owner, uint256 unicornId, uint256 genes);

    struct Unicorn {
        uint256 gen;
        uint64 birthTime;

        uint64 freezingEndTime;
        uint16 freezingIndex;
    }

    uint32[14] public freezing = [
    uint32(1 minutes),
    uint32(2 minutes),
    uint32(5 minutes),
    uint32(10 minutes),
    uint32(30 minutes),
    uint32(1 hours),
    uint32(2 hours),
    uint32(4 hours),
    uint32(8 hours),
    uint32(16 hours),
    uint32(1 days),
    uint32(2 days),
    uint32(4 days),
    uint32(7 days)
    ];

    Unicorn[] public unicorns;

    mapping (uint256 => address) public unicornIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public unicornIndexToApproved;
    //mapping(address => mapping(uint256 => uint256)) private ownerTokens;



    function _transfer(address _from, address _to, uint256 _unicornId) internal {
        ownershipTokenCount[_to]++;
        unicornIndexToOwner[_unicornId] = _to;
        // When creating new
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete unicornIndexToApproved[_unicornId];
        }

        Transfer(_from, _to, _unicornId);
    }

    function _createUnicorn(uint256 _gen, address _owner) internal returns (uint)
    {
        Unicorn memory _unicorn = Unicorn({
            gen: _gen,
            birthTime: uint64(now),
            freezingEndTime: 0,
            freezingIndex: 1//GET FROM GEN
            });

        uint256 newUnicornId = unicorns.push(_unicorn) - 1;

        require(newUnicornId == uint256(uint32(newUnicornId)));

        Birth(_owner,newUnicornId,_gen);

        _transfer(0, _owner, newUnicornId);

        return newUnicornId;
    }



    function owns(address _claimant, uint256 _unicornId) public view returns (bool) {
        return unicornIndexToOwner[_unicornId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _unicornId) internal view returns (bool) {
        return unicornIndexToApproved[_unicornId] == _claimant;
    }

    function _approve(uint256 _unicornId, address _approved) internal {
        unicornIndexToApproved[_unicornId] = _approved;
    }

    function allowance(address _claimant, uint256 _unicornId) public view returns (bool) {
        return _approvedFor(_claimant,_unicornId);
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(address _to, uint256 _unicornId) public
    {
        require(_to != address(0));
        require(owns(msg.sender, _unicornId));
        _transfer(msg.sender, _to, _unicornId);
    }


    function approve(address _to, uint256 _unicornId) public
    {
        require(owns(msg.sender, _unicornId));
        _approve(_unicornId, _to);
        Approval(msg.sender, _to, _unicornId);
    }


    function transferFrom(address _from, address _to, uint256 _unicornId) public
    {
        require(_to != address(0));
        require(_to != address(this));

        require(_approvedFor(msg.sender, _unicornId));
        require(owns(_from, _unicornId));

        _transfer(_from, _to, _unicornId);
    }


    function totalSupply() public constant returns (uint) {
        return unicorns.length;
    }


    function ownerOf(uint256 _unicornId) public constant returns (address owner)
    {
        owner = unicornIndexToOwner[_unicornId];
        require(owner != address(0));
    }

    //function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint tokenId)
    //{
    // return ownerTokens[_owner][_index];
    //}

}

contract Unicorn is UnicornBase {

    string public constant name = "Unicorn";
    string public constant symbol = "UNG";

    function getGen(uint _unicornId) public returns (uint) {
        return unicorns[_unicornId].gen;
    }

    function getBirthTime(uint _unicornId) public returns (uint) {
        return unicorns[_unicornId].birthTime;
    }

    function setBirthTime(uint _unicornId, uint64 _bt) internal {
        unicorns[_unicornId].birthTime = _bt;
    }

    function getFreezingEndTime(uint _unicornId) public returns (uint) {
        return unicorns[_unicornId].freezingEndTime;
    }

    function setFreezingEndTime(uint _unicornId, uint64 _freezingEndTime) internal {
        unicorns[_unicornId].freezingEndTime = _freezingEndTime;
    }

    function getFreezingIndex(uint _unicornId) internal returns (uint) {
        return unicorns[_unicornId].freezingIndex;
    }

    function setFreezingIndex(uint _unicornId, uint16 _freezingIndex) internal {
        unicorns[_unicornId].freezingIndex = _freezingIndex;
    }

}



contract UnicornController is Ownable  {

    struct Controller {
        address addr;
        bool isControlled;
        bool isInitialized;
    }

    mapping (bytes32 => Controller) public contracts;
    bytes32[] public contractIds;

    function UnicornController() public {
        registerContract(address(this), "UG.Controller", false);
    }

    /**
    * Store address of one contract in mapping.
    * @param _addr       Address of contract
    * @param _id         ID of contract
    */
    function setContract(address _addr, bytes32 _id, bool _isControlled) internal {
        contracts[_id].addr = _addr;
        contracts[_id].isControlled = _isControlled;
    }

    /**
    * Get contract address from ID. This function is called by the
    * contract's setContracts function.
    * @param _id         ID of contract
    * @return The address of the contract.
    */
    function getContract(bytes32 _id) internal returns (address _addr) {
        _addr = contracts[_id].addr;
    }

    /**
    * Registration of contracts.
    * It will only accept calls of deployments initiated by the owner.
    * @param _id         ID of contract
    * @return  bool        success
    */
    function registerContract(address _addr, bytes32 _id, bool _isControlled) onlyOwner public returns (bool _result) {
        setContract(_addr, _id, _isControlled);
        contractIds.push(_id);
        _result = true;
    }

    /**
    * Deregister a contract.
    * In future, contracts should be exchangeable.
    * @param _id         ID of contract
    * @return  bool        success
    */
    function deregister(bytes32 _id) onlyOwner public returns (bool _result) {
        if (getContract(_id) == 0x0) {
            return false;
        }
        setContract(0x0, _id, false);
        _result = true;
    }

    /**
    * After deploying all contracts, this function is called and calls
    * setContracts() for every registered contract.
    * This call pulls the addresses of the needed contracts in the respective contract.
    * We assume that contractIds.length is small, so this won't run out of gas.
    */
    function setAllContracts() onlyOwner public {
        UnicornControlledContract controlledContract;
        // TODO: Check for upper bound for i
        // i = 0 is FD.Owner, we skip this. // check!
        for (uint i = 0; i < contractIds.length; i++) {
            if (contracts[contractIds[i]].isControlled == true) {
                controlledContract = UnicornControlledContract(contracts[contractIds[i]].addr);
                controlledContract.setContracts();
            }
        }
    }

    function setOneContract(uint i) onlyOwner public {
        UnicornControlledContract controlledContract;
        // TODO: Check for upper bound for i
        controlledContract = UnicornControlledContract(contracts[contractIds[i]].addr);
        controlledContract.setContracts();
    }

    /**
    * Destruct one contract.
    * @param _id         ID of contract to destroy.
    */
    /*  function destructOne(bytes32 _id) onlyOwner {
          address addr = getContract(_id);
          if (addr != 0x0) {
              UnicornControlledContract(addr).destruct();
          }
      }*/

    /*    *//**
    * Destruct all contracts.
    * We assume that contractIds.length is small, so this won't run out of gas.
    * Otherwise, you can still destroy one contract after the other with destructOne.
    *//*
    function destructAll() onlyOwner {
        // TODO: Check for upper bound for i
        for (uint i = 0; i < contractIds.length; i++) {
            if (contracts[contractIds[i]].isControlled == true) {
                destructOne(contractIds[i]);
            }
        }

        selfdestruct(owner);
    }*/
}


contract UnicornControllerInterface {

    function isOwner(address _addr) public returns (bool _isOwner);

    function selfRegister(bytes32 _id) public returns (bool result);

    function getContract(bytes32 _id) public returns (address _addr);
}


contract UnicornControlledContract /*is UnicornDatabaseModel*/ {

    address public controller;
    UnicornControllerInterface UD_CI;

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    function setController(address _controller) internal returns (bool _result) {
        controller = _controller;
        UD_CI = UnicornControllerInterface(_controller);
        _result = true;
    }

    /*function destruct() onlyController {
        selfdestruct(controller);
    }*/

    function setContracts() public onlyController {}

    function getContract(bytes32 _id) internal returns (address _addr) {
        _addr = UD_CI.getContract(_id);
    }
}



contract BlackBoxController is UnicornControlledContract{
    //OraclizeControllerInterface UG_Oraclize;

    function BlackBoxController(address _controller) public {
        setController(_controller);
    }

    function setContracts() public onlyController {
        //UG_Oraclize = OraclizeControllerInterface(getContract("UG.Oraclize"));
    }

    function blackBox(uint gen1, uint gen2) public returns (uint gen) {
        return gen1 + gen2;
    }
}


contract BlackBoxControllerInterface {
    function blackBox(uint gen1, uint gen2) public returns (uint gen);
}


contract HybridizationController is UnicornControlledContract{
    //OraclizeControllerInterface UG_Oraclize;

    function HybridizationController(address _controller) public {
        setController(_controller);
    }

    function setContracts() public onlyController {
        //UG_Oraclize = OraclizeControllerInterface(getContract("UG.Oraclize"));
    }

}


contract HybridizationControllerInterface {
    //
}


contract UnicornBreeding is UnicornControlledContract, Ownable{
    Unicorn public unicorn_token;

    BlackBoxControllerInterface UG_BlackBox;
    HybridizationControllerInterface UG_Hybridization;

    event HybridizationAdded(uint indexed lastHybridizationId, uint indexed unicorn_id, uint price);
    event HybridizationAccepted(uint indexed HybridizationId, uint indexed unicorn_id);

    uint public lastHybridizationId;

    struct Hybridization{
        uint unicorn_id;
        uint price;
        uint second_unicorn_id;
        bool accepted;
        bytes32 hash;
    }

    mapping (uint => Hybridization) public hybridizations;

    function UnicornBreeding(address _controller, address _unicorn) public {
        setController(_controller);
        unicorn_token = Unicorn(_unicorn);
    }

    function setContracts() public onlyController {
        UG_BlackBox = BlackBoxControllerInterface(getContract("UG.BlackBox"));
        UG_Hybridization = HybridizationControllerInterface(getContract("UG.Hybridization"));
    }


    function makeHybridization(uint _unicornId, uint _price)  public returns (uint HybridizationId)
    {
        require(unicorn_token.owns(msg.sender, _unicornId));
        //предусмотреть смену владельца первого токена.

        lastHybridizationId += 1;
        Hybridization storage h = hybridizations[lastHybridizationId];

        h.unicorn_id = _unicornId;
        h.price = _price;

        h.second_unicorn_id = 0;
        h.accepted = false;

        h.hash = keccak256(lastHybridizationId,h.unicorn_id,h.price);

        HybridizationAdded(lastHybridizationId, h.unicorn_id,h.price);

        return lastHybridizationId;
    }

    function acceptHybridization (uint hybridizationId, uint _unicorn_id) public payable
    {
        Hybridization storage h = hybridizations[hybridizationId];
        require (!h.accepted);
        require (keccak256(hybridizationId,h.unicorn_id,h.price)==h.hash);
        require(unicorn_token.owns(msg.sender, _unicorn_id));
        require(msg.value == h.price);
        require(isReadyForHybridization(_unicorn_id));

        //предусмотреть смену владельца первого токена.
        //h.token_id owner может быть овнером h.second_token_id ????

        h.second_unicorn_id = _unicorn_id;

        uint gen1 = unicorn_token.getGen(h.unicorn_id);
        uint gen2 = unicorn_token.getGen(h.second_unicorn_id);
        uint newGen = blackBox(gen1,gen2);
        createUnicorn(newGen,msg.sender);

        address own = unicorn_token.ownerOf(h.unicorn_id);
        own.transfer(msg.value);

        _setFreezing(_unicorn_id);

        h.accepted = true;
        HybridizationAccepted(hybridizationId, _unicorn_id);
    }


    function blackBox(uint gen1, uint gen2) internal pure returns(uint256 newGen)
    {
        return UG_BlackBox.blackBox(gen1,gen2);
    }

    function createUnicorn(uint _gen, address _owner) public returns(uint256)
    {
        uint256 unicornId = unicorn_token._createUnicorn(_gen, _owner);
        return unicornId;
    }


    function newBirth(address _owner) public returns(uint256)
    {
        uint256 gen = createGen();
        uint256 unicornId = unicorn_token._createUnicorn(gen, _owner);
        return unicornId;
    }

    function createGen()  internal pure returns(uint256) {
        return 1;
    }


    function isReadyForHybridization(uint _unicornId) public view returns (bool) {
        uint64 freezingEndTime = unicorn_token.getFreezingEndTime(_unicornId);
        return freezingEndTime <= uint64(now);
    }


    function _setFreezing(uint _unicornId) internal {
        uint16 freezingIndex = unicorn_token.getFreezingIndex(_unicornId);
        uint64 FreezingEndTime = uint64(freezingIndex + uint64(now));
        unicorn_token.setFreezingEndTime(_unicornId,FreezingEndTime);
    }
}












