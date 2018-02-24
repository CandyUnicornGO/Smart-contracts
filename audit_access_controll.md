* контракт **BlackBox**
  - public 
    * function() - fallback для принятия ether
    * function __callback - возврат ответа от ораклиза
    * function isBlackBox - для проверки, что вызываемый контракт именно BlackBox
  - роль owner
    * function setBreeding - установить адрес контракта UnicornBreeding
    * function transferOwnership
    * function setGasPrice - установить цену за газ для Ораклайз
  - роль onlyBreeding - только контракт UnicornBreeding
    * function genCore
    * function createGen0
    
* контракт **UnicornBreeding**
  - public
    * function makeHybridization - только владелец уникорна + другие условия
    * function acceptHybridization - только владелец уникорна + другие условия
    * function cancelHybridization - только владелец уникорна + другие условия
    * function createUnicorn - создать уникорна за эфир
    * isReadyForHybridization - готов ли уникорн к продолжениям)
    * doSubFreezingTime - только тот, у кого достатчно candy токенов
  - роль onlyOwner
    * function setManager - установить адрес manager
    * function transferOwnership
    * function pause - ставит на паузу (пока нигде не используется)
    * function unpause - снять с паузы (пока нигде не используется)
    * function setBlackBoxAddress - установить адрес BlackBox
  - роль onlyManager
    * function setDividendPercent - проент на дивиденды
    * function setCreateUnicornPrice - цена создания
    * function setOraclizeFee - сумма комисии для ораклайза
    * function withdrawTokens - перевести candy токены с контракта
    * function transferEthersToDividendManager - перевести эфир на контракт dividendmanager
  - роль onlyCommunity
    * function onlyCommunity - новый адрес community
    * function setDividendManagerAddress - устнановить адрес контракта dividendmanager
    * function setSubFreezingPrice - установить цену за уменьшение времени "заморозки"
    * function setSubFreezingTime - установить время на которое уменьшается время "заморозки"
  - роль onlyOLevel - доступ любой из owner, manager
    * пока ничего не определено
  - роль onlyBlackBox - только контракт BlackBoxController
    * function setGen - устнавить ген уникорна
