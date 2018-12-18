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
        uint256 id;
    }

    ERC20 public ERC20Interface;

    // Escrow data storage maps depositor addresses to Escrow struct array
    mapping(address => Escrow[]) private escrow;

    // Iterable list of escrow depositors
    address[] public escrowDepositorList;

    event EscrowSucceeded(uint256 indexed _id, address indexed _depositor, address indexed _recipient, uint256 _amount);
    event EscrowFailed(address indexed _depositor, address indexed _recipient, uint256 _amount);

    /**
    * @dev allow contract to receive funds
    */
    function() public payable {}

    /**
    *
    */
    function initialize() public initializer {
        // TODO is this needed?
    }

    /**
    *
    */
    function createDepositorEscrow(
        address _tokenContract,
        address _recipient,
        uint256 _amount
    ) public whenNotPaused {
        // TODO validation

        createEscrow(
            msg.sender,
            _recipient,
            _tokenContract,
            0x0,
            EscrowTypes.DepositorAcceptance,
            _amount,
            0
        );
    }

    /**
    *
    */
    function createTimeBasedEscrow(
        address _tokenContract,
        address _recipient,
        uint256 _amount,
        uint256 _endTimestamp
    ) public whenNotPaused {
        // TODO validation

        createEscrow(
            msg.sender,
            _recipient,
            _tokenContract,
            0x0,
            EscrowTypes.TimeBased,
            _amount,
            _endTimestamp
        );
    }

    /**
    *
    */
    function createThirdPartyEscrow(
        address _tokenContract,
        address _recipient,
        uint256 _amount,
        address _thirdParty
    ) public whenNotPaused {
        // TODO validation

        createEscrow(
            msg.sender,
            _recipient,
            _tokenContract,
            _thirdParty,
            EscrowTypes.ThirdPartyAcceptance,
            _amount,
            0
        );
    }

    /**
    *
    */
    function confirmEscrow(address _recipient, uint256 _id) public whenNotPaused {
        // TODO implement
    }

    /**
    *
    */
    function cancelEscrow(address _recipient, uint256 _id) public whenNotPaused {
        // TODO implement
    }

    /**
    * @dev Dump all escrow accounts for depositor
    */
    function cancelAllEscrowsForDepositor(address _depositor) public onlyOwner {
        // TODO implement
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
        // TODO test

        // validations
        require(_amount > 0, "Amount must be > 0");

        // initialize token contract
        ERC20Interface = ERC20(_tokenContract);

        // this contract must be allowed to transfer the amount specified
        if(_amount > ERC20Interface.allowance(_depositor, address(this))) {
            emit EscrowFailed(_depositor, _recipient, _amount);
            revert("Xcrow is not authorized to transfer the amount specified");
        }

        // only executed if transfer was successful
        if(ERC20Interface.transferFrom(_depositor, address(this), _amount)) {

            uint256 id = escrow[_depositor].length;

            if(escrow[_depositor].length == 0) {
                // add depositor to list if this is their first escrow
                escrowDepositorList.push(_depositor);
            }

            // add escrow data
            escrow[_depositor].push(
                Escrow(
                    _recipient,
                    _tokenContract,
                    _thirdParty,
                    _escrowType,
                    _amount,
                    _endTimestamp,
                    now,
                    id)
            );

            emit EscrowSucceeded(id, _depositor, _recipient, _amount);

        } else {
            emit EscrowFailed(_depositor, _recipient, _amount);
        }
    }

    /**
    * @dev Escrow finder function
    */
    function findEscrow(
        address _depositor,
        address _recipient,
        uint256 _id
    ) private view returns(Escrow) {

        for(uint i = 0; i < escrow[_depositor].length; i++) {
            if(escrow[_depositor][i].recipient == _recipient && escrow[_depositor][i].id == _id) {
                return escrow[_depositor][i];
            }
        }
    }
}