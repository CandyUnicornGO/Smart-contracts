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
        uint256 genes;
        uint64 birthTime;
    }

    Unicorn[] unicorns;

    mapping (uint256 => address) public unicornIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public unicornIndexToApproved;
    mapping(address => mapping(uint256 => uint256)) private ownerTokens;



    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        unicornIndexToOwner[_tokenId] = _to;
        // When creating new kittens _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete unicornIndexToApproved[_tokenId];
        }

        Transfer(_from, _to, _tokenId);
    }

    function _createUnicorn(uint256 _genes, address _owner) internal returns (uint)
    {
        Unicorn memory _unicorn = Unicorn({
            genes: _genes,
            birthTime: uint64(now)
            });

        uint256 newUnicornId = unicorns.push(_unicorn) - 1;

        require(newUnicornId == uint256(uint32(newUnicornId)));

        Birth(_owner,newUnicornId,_genes);

        _transfer(0, _owner, newUnicornId);

        return newUnicornId;
    }
}


contract UnicornOwnership is UnicornBase, ERC721 {

    string public constant name = "UnicornGO";
    string public constant symbol = "UNG";

    function owns(address _claimant, uint256 _tokenId) public view returns (bool) {
        return unicornIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return unicornIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        unicornIndexToApproved[_tokenId] = _approved;
    }

    function allowance(address _claimant, uint256 _tokenId) public view returns (bool) {
        return _approvedFor(_claimant,_tokenId);
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(address _to, uint256 _tokenId) public
    {
        require(_to != address(0));
        require(owns(msg.sender, _tokenId));
        _transfer(msg.sender, _to, _tokenId);
    }


    function approve(address _to, uint256 _tokenId) public
    {
        require(owns(msg.sender, _tokenId));
        _approve(_tokenId, _to);
        Approval(msg.sender, _to, _tokenId);
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public
    {
        require(_to != address(0));
        require(_to != address(this));

        require(_approvedFor(msg.sender, _tokenId));
        require(owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }


    function totalSupply() public constant returns (uint) {
        return unicorns.length;
    }


    function ownerOf(uint256 _tokenId) public constant returns (address owner)
    {
        owner = unicornIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    //function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint tokenId)
    //{
    // return ownerTokens[_owner][_index];
    //}



}


contract UnicornBreeding is UnicornOwnership {
    event HybridizationAdded(uint indexed lastHybridizationId, uint indexed token_id, uint price);
    event HybridizationAccepted(uint indexed HybridizationId, uint indexed token_id);

    uint public lastHybridizationId;

    struct Hybridization{
        uint token_id;
        uint price;
        uint second_token_id;
        bool accepted;
        bytes32 hash;
    }

    mapping (uint => Hybridization) hybridizations;


    function makeHybridization(uint _token_id, uint _price)  public returns (uint tHybridizationId)
    {
        require(owns(msg.sender, _token_id));
        //предусмотреть смену владельца первого токена.

        lastHybridizationId = lastHybridizationId++;
        Hybridization storage h = hybridizations[lastHybridizationId];

        h.token_id = _token_id;
        h.price = _price;

        h.second_token_id = 0;
        h.accepted = false;

        h.hash = keccak256(lastHybridizationId,h.token_id,h.price);

        HybridizationAdded(lastHybridizationId, h.token_id,h.price);

        return lastHybridizationId;
    }

    function acceptHybridization (uint hybridizationId, uint _token_id) public payable
    {
        Hybridization storage h = hybridizations[hybridizationId];
        require (!h.accepted);
        require (keccak256(hybridizationId,h.token_id,h.price)==h.hash);
        require(owns(msg.sender, _token_id));
        require(msg.value == h.price);
        //предусмотреть смену владельца первого токена.
        //h.token_id owner может быть овнером h.second_token_id ????

        h.second_token_id = _token_id;

        uint newGen = blackBox(unicorns[h.token_id].gen,unicorns[h.second_token_id].gen);
        createUnicorn(newGen,msg.sender);

        address own = ownerOf(h.token_id);
        own.transfer(msg.value);

        h.accepted = true;
        HybridizationAccepted(hybridizationId, _token_id);
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
