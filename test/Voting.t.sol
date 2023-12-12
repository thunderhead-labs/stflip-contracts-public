// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MainMigration.sol";


contract VotingTest is MainMigration {
    address[] public addresses;

    function setUp() public {
        MainMigration migration = new MainMigration();

        vm.startPrank(owner);
            flip.mint(owner, 100_000*10**18);
            for (uint i = 1; i < 30; i++) {
                addresses.push(address(uint160(i)));
                flip.mint(addresses[i-1], 100*10**18);
            }

        vm.stopPrank();
    }

    function test_VotesMint() public {
        address a = addresses[0];
        uint256 bal = flip.balanceOf(a);
        require(stflip.getVotes(a) == 0);

        vm.warp(3);
        vm.startPrank(a);
            flip.approve(address(wrappedMinterProxy), 2**256 - 1);
            wrappedMinterProxy.mint(a, bal);
        vm.stopPrank();
        vm.warp(4);
        require(stflip.getVotes(a) == stflip.balanceToShares(bal), "current votes should be equal to minted votes");
        require(stflip.getPastVotes(a, 3) == stflip.balanceToShares(bal), "past votes should be equal to minted votes");
        require(stflip.getPastVotes(a, 1) == 0, "pre mint votes should be zero");

    }

    function test_GetVotesTransfer() public {
        address a = addresses[0];
        address b = addresses[1];
        uint256 bal = flip.balanceOf(a);
        require(stflip.getVotes(a) == 0 );
        require(stflip.getVotes(b) == 0 );

        vm.warp(3);
        vm.startPrank(a);
            flip.approve(address(wrappedMinterProxy), 2**256 - 1);
            wrappedMinterProxy.mint(a, bal);
            stflip.transfer(b, bal);
        vm.stopPrank();

        vm.warp(4);
        require(stflip.getVotes(a) == 0);
        require(stflip.getVotes(b) == stflip.balanceToShares(bal));
        require(stflip.getPastVotes(a, 3) == 0);
        require(stflip.getPastVotes(b, 3) == stflip.balanceToShares(bal));
        require(stflip.getPastVotes(a, 2) == 0);
        require(stflip.getPastVotes(b, 2) == 0);
    }
}
