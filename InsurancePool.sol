pragma solidity 0.5.0;

import "./owned.sol";
import "./Token.sol";
import "./Claim.sol";
import "./InsurancePolicy.sol";
import "./SafeMath.sol";

contract InsurancePool is owned, SafeMath {
    
    uint public numInsurers=0;
    mapping(address => uint) private insurers;
    address[] public insurerList;
    mapping (address => bool) isInsurer;
    mapping (address => mapping (address => bool)) voted;
    
    
    mapping (address => mapping (address => uint)) isAuthorized;
    mapping (address => mapping (address => uint)) isNotAuthorized;
    
    address public tokenAdr;
    uint256 lockInTime;
    mapping(address => uint) private deductibleAmount;
    mapping(address => uint) private claimedAmount;

    address[] public deployedPolicies;
    bool private b=false;
    
    modifier onlyInsurer()
    {
        require( isInsurer[msg.sender]);
        _;
    }
    
    constructor (uint _initialSupply, uint256 _lockInTime) public{
        Token t= new Token(address(this), _initialSupply);
        tokenAdr= address(t);
        lockInTime= _lockInTime;
    }

    function payContribution(uint value) payable public onlyInsurer() returns (bool){
        b= Token(tokenAdr).transferFrom(address(this), msg.sender, 100);
        
        b= Token(tokenAdr).transfer(address(this), value);
        if (b){
            numInsurers++;
            insurers[msg.sender] += value;
            claimedAmount[msg.sender]= mul(value, numInsurers);
            deductibleAmount[msg.sender]= value;
            insurerList.push(msg.sender);
            isInsurer[msg.sender] = true;
        }
        return b;
    }
    
    function updateAPI(address _insurancePolicy, string memory _APILink) public onlyInsurer() returns (bool){
        InsurancePolicy p= InsurancePolicy(_insurancePolicy);
        return p.updateClaimDetectionURL(_APILink);
    }
    
    function voteToAuthorize(address _claimAdr, bool _isAuthorized, string memory _reasonURI) public onlyInsurer() returns (bool){
        require(!voted[msg.sender][_claimAdr], "Already voted.");
        voted[msg.sender][_claimAdr] = true;
        if (_isAuthorized){
            isAuthorized[msg.sender][_claimAdr] += 1;
        }else{
            isNotAuthorized[msg.sender][_claimAdr] += 1;
        }
        
        if (isAuthorized[msg.sender][_claimAdr] + isNotAuthorized[msg.sender][_claimAdr]  == numInsurers){
            b= isAuthorized[msg.sender][_claimAdr] > isNotAuthorized[msg.sender][_claimAdr];
            Claim c= Claim(_claimAdr);
            return c.authorizeOpen(b, _reasonURI, deductibleAmount[c.getInsured()], claimedAmount[c.getInsured()]);
        }
        else{
            return true;
        }
    }
    
    function distributeSurplus() public onlyOwner() returns (bool){
        require (now >= lockInTime);
        
        uint256 surplus= mul(Token(tokenAdr).getBalanceOf(address(this)), div(8,10));
        for (uint i=0; i<insurerList.length; i++){
            uint bonus= mul( div(surplus, numInsurers), div(insurers[insurerList[i]], surplus) );
            b= Token(tokenAdr).transfer(insurerList[i], bonus);
        }
        return b;
    }
}
