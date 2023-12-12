// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../MainMigration.sol";
import "forge-std/console.sol";

contract InvariantHandler is MainMigration {
    /**
     * forge-config: default.invariant.runs = 20
     * forge-config: default.invariant.depth = 50
     * forge-config: default.invariant.fail-on-revert = true
    */
    uint256 public stflipSupply;

    address[] public actors;

    address internal currentActor;
    address internal otherActor;

    struct Validator {
        uint256 operatorId;
        uint256 balance;
        bytes32 nodeID;
    }

    Validator[] public validators;

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
        otherActor = actors[bound(uint256(keccak256(abi.encode(actorIndexSeed, block.timestamp))), 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }


    function setUp() public {
        address user;
        for (uint i = 0; i < 20; i++) {
            user = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
            actors.push(user);
            vm.prank(owner);
                flip.mint(user, 100_000*10**18);
            vm.startPrank(user);
                flip.approve(address(wrappedMinterProxy), 50_000 * 10**18);
                wrappedMinterProxy.mint(user, 50_000 * 10**18);
                stflipSupply += 50_000 * 10**18;
            vm.stopPrank();
        
        }

        bytes4[] memory selectors = new bytes4[](3);

        selectors[0] = this.transfer.selector;
        selectors[1] = this.mint.selector;
        selectors[2] = this.burn.selector;

        targetContract(
            address(this)
        );
        targetSelector(
            FuzzSelector({addr: address(this), selectors: selectors})
        );

        
    }


    function transfer(uint256 amount_, uint256 index) useActor(index) external {
        uint256 amount = bound(amount_, 0, stflip.balanceOf(currentActor) );
        if (amount > stflip.balanceOf(currentActor)) {
            vm.expectRevert();
        }
        stflip.transfer(otherActor, amount);

    } 

    function mint(uint256 amount_, uint256 index) useActor(index) external {
        uint256 amount = bound(amount_, 0, flip.balanceOf(currentActor) );

        if (amount > flip.balanceOf(currentActor)) {
            vm.expectRevert();
        }
        flip.approve(address(wrappedMinterProxy), amount);
        wrappedMinterProxy.mint(currentActor, amount);
        stflipSupply += amount;
    }

    function burn(uint256 amount_, uint256 index) useActor(index) external {
        uint256 amount = bound(amount_, 0, stflip.balanceOf(currentActor) );

        if (amount > stflip.balanceOf(currentActor)) {
            vm.expectRevert();
        }
        stflip.approve(address(wrappedBurnerProxy), amount);
        wrappedBurnerProxy.burn(currentActor, amount);
        stflipSupply -= amount;

    }


    function invariant_TotalSupply() external {
        assertEq(stflipSupply, stflip.totalSupply());

        uint256 allBalances;

        for (uint i = 0; i < actors.length; i++) {
            allBalances += stflip.balanceOf(actors[i]);
        }

        assertEq(allBalances, stflip.totalSupply());

        console.log("Invariant Total Supply Passed: ", stflip.totalSupply() / 10**18);
    }

}


// contract Handler is StdCheats, StdUtils {

//     InvariantHandler public ih;
//     function setUp() public {
//         ih = new InvariantHandler();
//         targetContract(address(ih));
//     }

//     function Invariant_TotalSupply() {
//         assertEq(ih.stflip.getPastTotalSupply(block.timestamp) * ih.stflip.yamsScalingFactor() / 10**24 , ih.stflip.totalSupply());
//     }
// }

// contract ActorManager is StdCheats, StdUtils {
//     Handler[] public handlers;

//     constructor(Handler[] memory _handlers) {
//         handlers = _handlers;
//     }


    
//     function transfer(uint256 handlerIndex, address user1, uint256 amount) {
//         uint256 index = bound(handlerIndex, 0, handlers.length - 1);
//         handlers[index].wrappedMinterProxy.transfer(user1, amount);
//     } 

//     function mint(uint256 handlerIndex, address user1, uint256 amount) {
//         uint256 index = bound(handlerIndex, 0, handlers.length - 1);
//         handlers[index].wrappedMinterProxy.mint(user1, amount);
//     }

//     function burn(uint256 handlerIndex, address user1, uint256 amount) {
//         uint256 index = bound(handlerIndex, 0, handlers.length - 1);

//         handlers[index].wrappedMinterProxy.burn(user1, amount);
//     }
// }


