// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/utils/BurnerV1.sol";
import "./MainMigration.sol";


contract BurnerTest is MainMigration {
    
    address user1 = 0x0000000000000000000000000000000000000001;
    address user2 = 0x0000000000000000000000000000000000000002;
    address user3 = 0x0000000000000000000000000000000000000003;

    function setUp() public {
        MainMigration migration = new MainMigration();

        vm.startPrank(owner);
        flip.mint(owner, 3000000*decimalsMultiplier);
        wrappedMinterProxy.mint(user1, 1000000*decimalsMultiplier);
        wrappedMinterProxy.mint(user2, 1000000*decimalsMultiplier);
        wrappedMinterProxy.mint(user3, 1000000*decimalsMultiplier);
        vm.stopPrank();

        vm.prank(user1);
        stflip.approve(address(burner),1000000*decimalsMultiplier);
        vm.prank(user2);
        stflip.approve(address(burner),1000000*decimalsMultiplier);
        vm.prank(user3);
        stflip.approve(address(burner),1000000*decimalsMultiplier);


        vm.prank(owner);
        flip.mint(user1,1000000000000);
    }

    using stdStorage for StdStorage;

    function testFail_BurnOrder() public {

        vm.startPrank(address(output));
            flip.transfer(owner, flip.balanceOf(address(output)));
        vm.stopPrank();

        // depositing some flip
        vm.prank(owner);
        flip.transfer(address(output),1000*decimalsMultiplier);
        // wrappedBurnerProxy.deposit(1000*decimalsMultiplier);

        // first user doing an instant burn for all the flip
        vm.startPrank(user1);
        uint256 id1 = wrappedBurnerProxy.burn(user1, 1000*decimalsMultiplier);
        wrappedBurnerProxy.redeem(id1);
        vm.stopPrank();

        // depositing some more flip. 
        vm.prank(owner);
        flip.transfer(address(output),100*decimalsMultiplier);
        // wrappedBurnerProxy.deposit(100*decimalsMultiplier);
        
        // doing a burn for the amount that was just deposited
        vm.prank(user1);
        uint256 id2 = wrappedBurnerProxy.burn(user1,100*decimalsMultiplier);

        // also doing a burn for the amount that was just deposited, except claiming it right after
        vm.startPrank(user2);
        uint256 id3 = wrappedBurnerProxy.burn(user2,100*decimalsMultiplier);
        wrappedBurnerProxy.redeem(id3);
        vm.stopPrank();

        console.log("uh oh");
    }

    function test_Burn() public {
        vm.prank(owner);
        flip.transfer(address(output),1000*decimalsMultiplier);

        vm.prank(user1);
        uint256 id1 = wrappedBurnerProxy.burn(user1,100*decimalsMultiplier);

        vm.prank(user2);
        uint256 id2 = wrappedBurnerProxy.burn(user2,500*decimalsMultiplier);

        vm.prank(user3);
        uint256 id3 = wrappedBurnerProxy.burn(user3,400*decimalsMultiplier);
        
        vm.prank(user3);
        wrappedBurnerProxy.redeem(id3);

        vm.prank(user1);
        wrappedBurnerProxy.redeem(id1);

        vm.prank(user2);
        wrappedBurnerProxy.redeem(id2);

    }


    mapping (uint256 => bool) public claimed;

    function testFuzz_BurnOrder(address[50] memory users, uint16[50] memory amounts_, uint256 claimableIndex_) public {

        uint256 claimableIndex = bound(claimableIndex_, 1, 49); // the index at which burns become not claimable
        uint256 total = 0;
        uint256[50] memory amounts;
        uint256[50] memory claimOrder;
        uint256 claimable;
 
        // we ignore i = 0 so that the index of the user aligns with their burn id
        for (uint i = 1; i < 50; i++) {
            amounts[i] = uint256(amounts_[i]) * 10**18;
            if (amounts[i] < 1000) {
                amounts[i] = 1000;
            }
        }
        
        // creating random order to claim the burnIds
        for (uint i = 1; i < 50; i++) {
            claimOrder[i] = i;
            if (users[i] == address(0)) {
                users[i] = address(uint160(i));
            }
        }
       
        for (uint i = 50 - 1; i > 0; i--) {
            uint j = uint(keccak256(abi.encodePacked(block.timestamp, i))) % (i + 1);

            if (j == 0 || i == 0) {
                continue;
            }
            (claimOrder[i], claimOrder[j]) = (claimOrder[j], claimOrder[i]);
        }


        // ensure claim order shuffle worked
        for (uint i = 0; i < 50; i++) {
            console.log(claimOrder[i]);
        }

        // mint all the users enough stflip, and then burn it
        for (uint i = 1; i < 50; i++) {
            vm.prank(owner);
                flip.mint(users[i], amounts[i] );

                console.log(owner);

            vm.startPrank(users[i]);
                flip.approve(address(minter), 2**256 - 1);
                stflip.approve(address(burner), 2**256 - 1);
                wrappedMinterProxy.mint(users[i], amounts[i]);
                wrappedBurnerProxy.burn(users[i], amounts[i]);
            vm.stopPrank();

            total += uint256(amounts[i]);
        }

        // ensure that the burns entered as expected
        console.log("actual v. expected", wrappedBurnerProxy.totalPendingBurns(), total);
        require(wrappedBurnerProxy.totalPendingBurns() == total, "total pending burns is not correct");

        // deposit the flip needed to satisfy claimableIndex
        for (uint i = 1; i < claimableIndex; i++) {
            claimable += amounts[i];
        }

        vm.startPrank(address(output));
            flip.transfer(address(uint160(6969)), flip.balanceOf(address(output)));
        vm.stopPrank();

        vm.prank(owner);
            flip.mint(address(output), claimable);

        // print initial state for debugging
        uint256 initialFlipBalance;
        uint256 id;
        console.log("claimableIndex", claimableIndex);
        console.log("amount claimable", claimable);
        console.log("output balance", flip.balanceOf(address(output)));
        console.log("initial burn state");
        for (uint i = 0; i < 50; i++) {
            console.log(i, wrappedBurnerProxy.redeemable(i), amounts[i], wrappedBurnerProxy.sums(i));
        }


        // go through the random claimOrder list. Prior to burning if it can, check that all the burns are claimable or not as expected
        for (uint i = 1; i < 50; i++) {
            
            // check all burns
            for (uint j = 1; j < 50; j++) {
                id = claimOrder[j];
                
                // if there are burns at the edge of claimableness, it is still claimable (weird but still satisifes invariant)
                if (amounts[id] == 0) {
                    continue; 
                }
                
                if (id < claimableIndex) {
                    if (claimed[id] == true) {
                        require(wrappedBurnerProxy.redeemable(id) == false, "Claimed claimable burn not reporting unclaimable");
                    } else {
                        require(wrappedBurnerProxy.redeemable(id) == true, "Claimable burn not reporting claimed");
                    }
                } else {
                    require(wrappedBurnerProxy.redeemable(id) == false, "Unclaimable burn not reporting unclaimable");   
                }

            }

            if (claimOrder[i] < claimableIndex) {
                initialFlipBalance = flip.balanceOf(users[claimOrder[i]]);
                vm.prank(users[claimOrder[i]]); // can be from anyone   
                    wrappedBurnerProxy.redeem(claimOrder[i]);
                claimed[claimOrder[i]] = true;
                console.log("actual v. expected balance", flip.balanceOf(users[claimOrder[i]]), initialFlipBalance + amounts[claimOrder[i]]);
                require(initialFlipBalance + amounts[claimOrder[i]] == flip.balanceOf(users[claimOrder[i]]), "FLIP balance incorrect after claiming" );
            }
            
        }


    }


}
