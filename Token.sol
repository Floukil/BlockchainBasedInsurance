pragma solidity 0.5.0;

import "./owned.sol";
import {ERC20} from "./ERC20.sol";
import {SafeMath} from "./SafeMath.sol";

contract Token is ERC20, SafeMath {
    uint public totalSupply;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    constructor (address _owner, uint initialSupply) public {
        totalSupply = initialSupply;
        balanceOf[_owner] = initialSupply;
    }

    function transfer(address receiver, uint value) public returns (bool ok) ;

    function transferFrom(address from, address to, uint value) public returns (bool ok) ;
    
    function getBalanceOf(address who) public returns (uint value){
        return balanceOf[who];
    }
}
