pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/*
Xcrow provides opinionated escrow-as-a-service using ERC20 tokens. The
seminal use case is using stablecoins to enable escrow without volatility.

There are 3 types of escrow accounts:
- DepositorAcceptance: escrow is released when depositor indicates acceptance
- TimeBased: either user can trigger escrow release once end date is reached
- ThirdPartyAcceptance: depositor delegates acceptance to a third party

Escrow can be returned to depositor without acceptance if:
- recipient cancels transaction via cancelEscrow
- contract owner returns escrow deposits via dumpEscrow
*/

contract Xcrow is Initializable, Ownable, Pausable {
    using SafeMath for uint256;

    // Escrow type definitions
    enum EscrowTypes { DepositorAcceptance, TimeBased, ThirdPartyAcceptance }

    // Escrow data struct
    struct Escrow {
        address recipient;
        address tokenContract;
        address thirdParty;
        EscrowTypes escrowType;
        uint256 amount;
        uint256 endTimestamp;
        uint256 creationTimestamp;
    }

    ERC20 public ERC20Interface;

    // Escrow data storage maps depositor addresses to Escrow struct array
    mapping(address => Escrow[]) private escrow;

    // Iterable list of escrow depositors
    address[] public escrowDepositorList;

    event EscrowSucceeded(address indexed _depositor, address indexed _recipient, uint256 _amount);
    event EscrowFailed(address indexed _depositor, address indexed _recipient, uint256 _amount);

    /**
    * @dev allow contract to receive funds
    */
    function() public payable {}

    /**
    *
    */
    function initialize() public initializer {
        //
    }

    /**
    *
    */
    function createDepositorEscrow(
        address _recipient,
        uint256 _amount)
    public whenNotPaused returns(uint256) {
        //
    }

    /**
    *
    */
    function createTimeBasedEscrow(address _recipient, uint256 _amount, uint256 _endTimestamp) public whenNotPaused {
        //
    }

    /**
    *
    */
    function createThirdPartyEscrow(address _recipient, uint256 _amount, address _thirdParty) public whenNotPaused {
        //
    }

    /**
    *
    */
    function confirmEscrow(address _recipient) whenNotPaused public {
        //
    }

    /**
    *
    */
    function cancelEscrow(address _recipient) whenNotPaused public {
        //
    }

    /**
    * @dev Dump all escrow accounts for depositor
    */
    function dumpEscrow(address _owner) public onlyOwner {
        //
    }

    /**
    * @dev Master createEscrow function
    */
    function createEscrow(
        address _depositor,
        address _recipient,
        address _tokenContract,
        address _thirdParty,
        EscrowTypes _escrowType,
        uint256 _amount,
        uint256 _endTimestamp)
    private whenNotPaused {

        require(_amount > 0, "Amount must be > 0");

        // initialize token contract
        ERC20Interface = ERC20(_tokenContract);

        // this contract must be allowed to transfer the amount specified
        if(_amount > ERC20Interface.allowance(_depositor, address(this))) {
            emit EscrowFailed(_depositor, _recipient, _amount);
            revert("Xcrow is not authorized to transfer the amount specified");
        }

        if(ERC20Interface.transferFrom(_depositor, address(this), _amount)) {
            // only executed if transfer was successful

            // add index
            escrowDepositorList.push(_depositor);

            // add escrow data
            escrow[_depositor].push(
                Escrow(
                    _recipient,
                    _tokenContract,
                    _thirdParty,
                    _escrowType,
                    _amount,
                    _endTimestamp,
                    now)
            );

            emit EscrowSucceeded(_depositor, _recipient, _amount);

        } else {
            emit EscrowFailed(_depositor, _recipient, _amount);
        }
    }
}