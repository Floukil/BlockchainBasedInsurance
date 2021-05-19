pragma solidity 0.5.0;

import "./owned.sol";
import "./Token.sol";

contract Claim is owned {

   enum Status {
        Created,
        Open,
        Closed,
        Rejected,
        Canceled
    }
    Status public claimStatus;
    
    address public insurancePolicy;
    address public insurancePool;
    address public insured;
    string public reasonURI;
    address tokenAdr;
    
    constructor (address _pool, address _insured, address _tokenAdr) public {
        insurancePolicy= msg.sender;
        insurancePool= _pool;
        insured= _insured;
        tokenAdr= _tokenAdr;
    }
    
    modifier onlyPool()
    {
        require( insurancePool == msg.sender);
        _;
    }
    
    modifier onlyInsured()
    {
        require( insured == msg.sender);
        _;
    }
    
    modifier onlyStatus(Status _status)
    {
        require( claimStatus == _status);
        _;
    }

    event Opened(address _sender);
    event Rejected(address _sender);
    
    function authorizeOpen(bool isAuthorized, string memory _reasonURI, uint _deductibleAmount, uint _claimedAmount) public onlyPool() onlyStatus(Status.Created) returns (bool){
            if (isAuthorized){
                claimStatus = Status.Open;
                reasonURI= _reasonURI;
                emit Opened(msg.sender);
                triggerPayment(_deductibleAmount, _claimedAmount);
            }else{
                claimStatus = Status.Rejected;
                emit Rejected(msg.sender);
            }
    }
    
    function triggerPayment(uint _deductibleAmount, uint _claimedAmount) internal returns (bool){
        bool b= Token(tokenAdr).transferFrom(insured, insurancePool, _deductibleAmount);
        b= Token(tokenAdr).transferFrom(insurancePool, insured, _claimedAmount);
        
        if (b){
          closeClaim();  
        }else{
            return false;
        }
        
    }
    
    event Closed(address _sender);
    function closeClaim() internal onlyStatus(Status.Open) returns (bool){ 
        claimStatus = Status.Closed;
        emit Closed(msg.sender);
    }

    event Canceled(address _sender);
    function cancelClaim(string memory _reasonURI) public onlyInsured onlyStatus(Status.Open) returns (bool){ 
        claimStatus = Status.Canceled;
        reasonURI= _reasonURI;
        emit Canceled(msg.sender);
    }
    
    function getInsured() public view returns(address){
        return insured;
    }
}
