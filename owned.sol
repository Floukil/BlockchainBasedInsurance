pragma solidity 0.5.0;

contract owned {

    address public owner;
    /* Initialise contract creator as owner */
    constructor () public {
        owner = msg.sender;
    }
    
    modifier onlyOwner()
    {
        require( owner == msg.sender);
        _;
    }

     /* Transfer ownership of this contract to someone else */
    event OwnershipTransfer(address _owner, address _newowner);
    function transferOwnership(address _newowner) public {
        require( owner == msg.sender);
        owner = _newowner;
        emit OwnershipTransfer(owner, _newowner);
    }
}
