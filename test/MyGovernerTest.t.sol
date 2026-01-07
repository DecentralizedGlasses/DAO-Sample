// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {Box} from "../src/Box.sol";
import {GovToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";


contract MyGovernorTest is Test{
    MyGovernor public governor;
    Box public box;
    GovToken public govToken;
    TimeLock public timelock;

    address public USER = makeAddr("user");

    uint256 public constant INITIAL_SUPPLY = 100 ether;

    uint256 public constant MIN_DELAY = 3600; // 1hour -after a vote passes
    uint256 public constant VOTING_DELAY = 1; // how many blocks vote is still active
    uint256 public constant VOTING_PERIOD = 50400; 

    address[] proposers;
    address[] executers;

    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    function setUp() public {
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);
        
        vm.startPrank(USER);
        govToken.delegate(USER);

        timelock = new TimeLock(MIN_DELAY, proposers, executers);
        governor = new MyGovernor(govToken, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, address(this));
        vm.stopPrank();

        box = new Box();

        box.transferOwnership(address(timelock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(12);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 897;
        string memory description = "store 1 in box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        
        targets.push(address(box));
        calldatas.push(encodedFunctionCall);
        values.push(0);

        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // view the state 
        console.log("Proposal state:", uint256(governor.state(proposalId)));

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY +1);
        // assert(uint256(governor.state(proposalId)) == 1); // Active

        console.log("Proposal state:", uint256(governor.state(proposalId)));

        // 2. vote
        string memory reason = "I like this proposal";

        uint8 voteWay = 1; //means voting yes
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD +1);
        // assert(uint256(governor.state(proposalId)) == 4); // Succeeded

        // 3. Queue the Tx
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY +1);

        // 4. Execute the Tx
        governor.execute(targets, values, calldatas, descriptionHash);

        // assert(uint256(governor.state(proposalId)) == 6); // Executed

        console.log("Box Value:", box.getNumber());
        assert(box.getNumber() == valueToStore);
    }

}