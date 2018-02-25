* контракт BlackBoxController
  - event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  - event logRes(string res); - для тестов, уберем
  - event LogNewOraclizeQuery(string description); - собитие ораклиза, не несет полезной информации, надо заменить на что-то другое

* contract UnicornBreeding 
  - event Pause(); - не импользуется
  - event Unpause(); - не используется

  - event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  - event Transfer(address indexed _from, address indexed _to, uint256 _unicornId);  - стандартный event ERC721
  - event Approval(address indexed _owner, address indexed _approved, uint256 _unicornId); - стандартный event ERC721
        
  - event HybridizationAdded(uint indexed lastHybridizationId, uint indexed UnicornId, uint price);
  - event HybridizationAccepted(uint indexed HybridizationId, uint indexed UnicornId, uint  NewUnicornId);
  - event HybridizationCancelled(uint indexed HybridizationId);
  - event FundsTransferred(address dividendManager, uint value); - перечисление средств на didvidendmanager
  - event CreateUnicorn(address indexed owner, uint indexed UnicornId); - создание уникорна
  - event UnicornBirth(address owner, uint256 unicornId); - по логике дублирует CreateUnicorn - можно убрать 
      
* contract Crowdsale 
  - event UnicornPurchase( address indexed beneficiary, uint256 unicornId);
  - event UnicornSale( address indexed beneficiary, uint256 unicornId);
  