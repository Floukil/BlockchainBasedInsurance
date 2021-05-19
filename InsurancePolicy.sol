pragma solidity 0.5.0;

import "./owned.sol";
import "./Token.sol";
import "./Claim.sol";
import "./provableAPI_0.5.sol";

contract InsurancePolicy is owned, usingProvable {
    
    enum Status {
        Open,
        Canceled
    }
    Status public policyStatus;
    
    address public policyholder;
    address public insurancePool;
    uint public premiumPaymentAmount;
    
    bool private b= false;
    address public tokenAdr;
    
    string public APILink;
    uint public numClaims;
    mapping (uint => address) public claims;
    
    modifier onlyPool()
    {
        require( insurancePool == msg.sender);
        _;
    }
    
    constructor (address _insurancePool, uint _premiumPaymentAmount, address _tokenAdr) public {
        policyholder= msg.sender;
        insurancePool= _insurancePool;
        premiumPaymentAmount= _premiumPaymentAmount;
        
        numClaims=0;
        policyStatus= Status.Open;
        tokenAdr= _tokenAdr;
    }
    
    function payPremium() payable public onlyOwner() returns (bool){
        b= Token(tokenAdr).transfer(address(this), premiumPaymentAmount);
        return b;
    }
    
    function updateClaimDetectionURL(string memory _APILink) public onlyPool() returns (bool){
        APILink= _APILink;
        update();
        return true;
    }
    
    function createClaim() internal returns (address){
        Claim c= new Claim(insurancePool, policyholder, tokenAdr);
        numClaims++;
        claims[numClaims]= address(c);
        return address(c);
    }
    
    event PolicyWasCanceled(address _policyAdr);
    function cancelPolicy() public onlyOwner() returns (bool){ 
        require( policyStatus == Status.Open);
        policyStatus = Status.Canceled;
        emit PolicyWasCanceled(address(this));
    }
    
    string public delay;
    event newProvableQuery(string description);
    event newClaim(bytes32 myid, string delay);
    
    function __callback(bytes32 myid, string memory result) public{
        require (msg.sender == provable_cbAddress()) ;
        emit newClaim(myid, result);
        delay = result; 
        // do something after the result
        createClaim();
    }
    
    //_APILink= https://www.fueleconomy.gov/ws/rest/fuelprices
    function update() payable public {
        emit newProvableQuery("Provable query was sent, standing by for the answer..");
        string memory url= string(abi.encodePacked("xml(", APILink, ").fuelPrices.diesel"));
        provable_query("URL", url);
    }
}
