// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MainMigration.sol";


contract MinterTest is MainMigration {
    address user1 = 0x0000000000000000000000000000000000000001;
    address user2 = 0x0000000000000000000000000000000000000002;
    address user3 = 0x0000000000000000000000000000000000000003;

    function setUp() public {
        MainMigration migration = new MainMigration();
    }


    /**
     * @notice Fuzz function to ensure minting works as expected
     * @param amountToMint_ Amount to mint
     * @param initialBalancePerShare_ initialbalancepershare
     */
    function testFuzz_OneToOne(uint256 amountToMint_, uint256 initialBalancePerShare_) public {      
        uint256 amountToMint = bound(amountToMint_, 1000, 100_000_000*decimalsMultiplier);
        uint256 initialBalancePerShare = bound(initialBalancePerShare_, 10**17, 10**19);
        

        console.log("amountToMint:               ",amountToMint);
        console.log("initialBalancePerShare:     ",initialBalancePerShare, initialBalancePerShare/10**17);
        vm.startPrank(owner);
            flip.mint(user1, amountToMint);
            stflip.mint(owner, 10**18);
            stflip.syncSupply(0, initialBalancePerShare, 0);
        vm.stopPrank();

        uint256 initialFlipSupply = flip.totalSupply();
        uint256 initialStflipSupply = stflip.totalSupply();
        uint256 initialFlipBalance = flip.balanceOf(user1);
        uint256 initialStflipBalance = stflip.balanceOf(user1);

        vm.startPrank(user1);
            flip.approve(address(minter), 2**256-1);
            console.log("initial share balance: ", stflip.sharesOf(user1));
            console.log("minting shares:", stflip.balanceToShares(amountToMint));
            console.log("share to balance: ", stflip.sharesToBalance(1));
            wrappedMinterProxy.mint(user1,amountToMint);
            console.log("after share balance: ", stflip.sharesOf(user1));
            console.log("share to balance: ", stflip.sharesToBalance(1));
        vm.stopPrank();
        
        require(initialFlipSupply == flip.totalSupply(), "flip supply change");
        require(initialStflipSupply + amountToMint == stflip.totalSupply() || initialStflipSupply + amountToMint -1 == stflip.totalSupply(), "unexpected stflip supply change");
        require(initialFlipBalance - amountToMint == flip.balanceOf(user1), "unexpected flip balance change");
        console.log("stflip.totalSupply():   ", stflip.totalSupply());
        console.log("initialStflipBalance:   " ,initialStflipBalance);
        console.log("stflip.balanceOf(user1):", stflip.balanceOf(user1));
        console.log("stflip.sharesOf(user1): ", stflip.sharesOf(user1));
        console.log("stflip.sharesToBalance(10**6)", stflip.sharesToBalance(10**6));
        console.log("amountToMint:           ", amountToMint);
        if (stflip.sharesOf(user1) <= 10**24 / initialBalancePerShare) {
            require (initialStflipBalance + 0 == stflip.balanceOf(user1), "unexpected stflip balance change 1 ");
        } else  { 
            require(initialStflipBalance + amountToMint == stflip.balanceOf(user1) || initialStflipBalance + amountToMint == stflip.balanceOf(user1) + 1, "unexpected stflip balance change 2");
        }
    }
    
}
