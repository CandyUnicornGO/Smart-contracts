pragma solidity ^0.4.18;


contract ERC721 {
    // ERC20 compatible functions
    //function name() constant returns (string name);
    //function symbol() constant returns (string symbol);
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint balance);
    // Functions that define ownership
    function ownerOf(uint256 _tokenId) public constant returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function allowance(address _claimant, uint256 _tokenId) public view returns (bool);
    //TODO function takeOwnership(uint256 _tokenId);
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    //function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint tokenId);
    // Token metadata
    //function tokenMetadata(uint256 _tokenId) constant returns (string infoUrl);
    // Events
    //event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}


contract UnicornBase {

    event Birth(address owner, uint256 unicornId, uint256 genes);

    event Transfer(address from, address to, uint256 tokenId);

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
    //0xA76A95918C39eE40d4a43CFAF19C35050E32E271
    //0xC4B86bb4A4467e9F7Ed336A75308F766A37a9B2e

    Unicorn[] public unicorns;

    mapping (uint256 => address) public unicornIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public unicornIndexToApproved;
    //mapping(address => mapping(uint256 => uint256)) private ownerTokens;



    function _transfer(address _from, address _to, uint256 _unicornId) internal {
        ownershipTokenCount[_to]++;
        unicornIndexToOwner[_unicornId] = _to;
        // When creating new kittens _from is 0x0, but we can't account that address.
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

}


contract UnicornOwnership is UnicornBase, ERC721 {

    string public constant name = "UnicornGO";
    string public constant symbol = "UNG";

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


contract UnicornBreeding is UnicornOwnership {
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


    function makeHybridization(uint _unicornId, uint _price)  public returns (uint HybridizationId)
    {
        require(owns(msg.sender, _unicornId));
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
        require(owns(msg.sender, _unicorn_id));
        require(msg.value == h.price);
        require(isReadyForHybridization(_unicorn_id));

        //предусмотреть смену владельца первого токена.
        //h.token_id owner может быть овнером h.second_token_id ????

        h.second_unicorn_id = _unicorn_id;

        uint newGen = blackBox(unicorns[h.unicorn_id].gen,unicorns[h.second_unicorn_id].gen);
        createUnicorn(newGen,msg.sender);

        address own = ownerOf(h.unicorn_id);
        own.transfer(msg.value);

        _setFreezing(unicorns[_unicorn_id]);

        h.accepted = true;
        HybridizationAccepted(hybridizationId, _unicorn_id);
    }


    function blackBox(uint gen1, uint gen2) internal pure returns(uint256 newGen)
    {
        return gen1 + gen2;
    }

    function createUnicorn(uint _gen, address _owner) public returns(uint256)
    {
        uint256 unicornId = _createUnicorn(_gen, _owner);
        return unicornId;
    }


    function newBirth(address _owner) public returns(uint256)
    {
        uint256 gen = createGen();
        uint256 unicornId = _createUnicorn(gen, _owner);
        return unicornId;
    }

    function createGen()  internal pure returns(uint256) {
        return 1;
    }


    function isReadyForHybridization(uint _unicornId) public view returns (bool) {
        return (unicorns[_unicornId].freezingEndTime <= uint64(now));
    }


    function _setFreezing(Unicorn storage _unicorn) internal {
        _unicorn.freezingEndTime = uint64((freezing[_unicorn.freezingIndex]) + uint64(now));
    }
}

contract Crowdsale {

    UnicornBreeding public token;
    
    uint price = 100000000000000000;
    
    mapping (uint256 => uint256) public prices; // if prices[id] = 0 then not for sale

    event TokenPurchase( address indexed beneficiary, uint256 unicornId);
    event TokenSale( address indexed beneficiary, uint256 unicornId);

    function Crowdsale(address _token) public {
        token = UnicornBreeding(_token);
    }
    
    function saleUnicorn(uint unicornId, uint price) public {
        prices[unicornId] = price;
    } 
    
    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(msg.value == price);

        uint unicornId = token.newBirth(beneficiary);
        TokenPurchase(msg.sender, unicornId);

        //forwardFunds();
    }

    function buyUnicorn(uint unicornId) public payable {
        require(msg.value >= prices[unicornId]);
        uint dif = msg.value - prices[unicornId];
        address own = token.ownerOf(unicornId);
        require(token.allowance(this,unicornId));
        token.transferFrom(own, msg.sender,unicornId);
        own.transfer(prices[unicornId]);
        msg.sender.transfer(dif);  // give change
        prices[unicornId] = 0; // unicorn sold
        TokenSale(msg.sender, unicornId);
    }
    
}
