* контракт BlackBoxController
  - uint public queueSize; - размер очереди необработанных запросов е генному ядру
  
* contract UnicornBreeding 
  - стандарт ERC721
  - address public owner;
  - address public managerAddress;
  - address public communityAddress;
  - address public dividendManagerAddress; //onlyCommunity
  - bool public paused = false;
  - mapping(address => bool) tournaments;//address 1 exists
  - uint32[14] public freezing = [];
  - BlackBoxInterface public blackBoxContract; //onlyOwner
  - address public blackBoxAddress; //onlyOwner
  - CandyCoinInterface public token; //SET on deploy
  - uint public subFreezingPrice; //onlyCommunity price in CandyCoins
  - uint public subFreezingTime; //onlyCommunity 
  - uint public dividendPercent; //OnlyManager 4 digits. 10.5% = 1050
  - uint public createUnicornPrice; //OnlyManager price in weis
  - uint public createUnicornPriceInCandy; //OnlyManager price in CandyCoin
  - uint public gen0Count;
  - uint public oraclizeFee;
  - uint public lastHybridizationId;
  - mapping (uint => Hybridization) public hybridizations;

* contract Crowdsale 
  - Unicorn public token;
  - uint public dividendPercent; //OnlyManager 4 digits. 10.5% = 1050
  - mapping (uint256 => uint256) public prices;
  
* contract UnicornDividendToken
  - стандарт ERC20
  
* contract DividendManager
  - нет, ??? можно сделать публичным адрес двивдент токена