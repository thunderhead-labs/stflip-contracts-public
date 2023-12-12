// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MainMigration.sol";
import "forge-std/console.sol";

contract MinterTest is MainMigration {
    address user1 = 0x0000000000000000000000000000000000000001;
    address user2 = 0x0000000000000000000000000000000000000002;
    address user3 = 0x0000000000000000000000000000000000000003;

    function setUp() public {
        MainMigration migration = new MainMigration();
    }

    function _relativelyEq(uint256 num1, uint256 num2) internal returns (bool) {
        return (num1 > num2) ? (num1 - num2 <= 10**13) : (num2 - num1 <= 10**13);
    }

    function testFuzz_SyncSupply(uint256 oldSupply_, uint256 newSupply_, uint256 interval_, uint256 initialShares_, bool slash) public {
        
        uint256 interval = bound(interval_, 60*60 / 100, 60*60*24*7 / 100) * 100;
        uint256 initialShares = bound(initialShares_, 10**18, 100_000_000*10**18);

        uint256 oldSupply;
        uint256 newSupply;
        if (slash == true) {
            oldSupply = bound(oldSupply_, initialShares * 11 / 10, initialShares*10);
            newSupply = bound(newSupply_, initialShares, oldSupply);
        }  else {
            oldSupply = bound(oldSupply_, initialShares, initialShares*9);
            newSupply = bound(newSupply_, oldSupply, initialShares*10);
        }    

        uint256 user1InitialBalance = oldSupply / 3;
        uint256 user2InitialBalance = oldSupply * 2/ 3;
        uint256 user1Shares = initialShares / 3;
        uint256 user2Shares = initialShares * 2 / 3;

        console.log("oldSupply:           ", oldSupply);
        console.log("newSupply:           ", newSupply);
        console.log("interval:            ", interval);
        console.log("initialShares:       ", initialShares);
        console.log("slash:               ", slash);
        console.log("user1InitialBalance: ", user1InitialBalance);
        console.log("user2InitialBalance: ", user2InitialBalance);
        console.log("user1Shares:         ", user1Shares);
        console.log("user2Shares:         ", user2Shares);

        vm.startPrank(owner);
            flip.mint(user1, user1Shares);
            flip.mint(user2, user2Shares);
        vm.stopPrank();

        vm.startPrank(user1);
            flip.approve(address(minter), 2**256-1);
            wrappedMinterProxy.mint(user1, user1Shares);
        vm.stopPrank();

        vm.startPrank(user2);
            flip.approve(address(minter), 2**256-1);
            wrappedMinterProxy.mint(user2, user2Shares);
        vm.stopPrank();

        vm.prank(owner);
            stflip.syncSupply(0, oldSupply, 0);

        require(_relativelyEq(stflip.balanceOf(user1), user1InitialBalance), "user1 balance changed");
        require(_relativelyEq(stflip.balanceOf(user2), user2InitialBalance), "user2 balance changed");
        require(_relativelyEq(stflip.totalSupply(), oldSupply), "total supply changed");


        console.log("=== Setting new supply === ");
        vm.startPrank(owner);
            stflip.syncSupply(0, newSupply, interval);
        console.log("preSyncSupply:", stflip.preSyncSupply());
        console.log("rewardsToSync:", stflip.rewardsToSync());


        if (slash == true) {
            console.log("=== Checking slash requirements ===");
            console.log("user1 balance:", stflip.balanceOf(user1), newSupply / 3    );
            console.log("user1 balance:", stflip.balanceOf(user2), newSupply * 2 / 3    );

            require(stflip.totalSupply() == newSupply, "newSupply incorrect");
            require(_relativelyEq(stflip.balanceOf(user1),newSupply / 3), "user1 balance incorrect");
            require(_relativelyEq(stflip.balanceOf(user2),newSupply * 2 / 3 )   , "user2 balance incorrect");
        } else {

            uint256 jump = interval / 100; 
            uint256 expectedSupply;
            console.log("=== Checking total supply while linearly increasing time === ");
            for (uint i = 1; i <= 100; i++) {
                vm.warp(jump*i + 1);
                
                if (slash == true) {
                    expectedSupply = oldSupply - (oldSupply - newSupply) * i / 100;

                } else {
                    expectedSupply = oldSupply + (newSupply - oldSupply) * i / 100;
                }

                console.log("iteration:      ", i);
                console.log("expectedSupply: ", expectedSupply);
                console.log("actualSupply:   ", stflip.totalSupply());
                console.log("balancePerShare:", stflip.balancePerShare());
                console.log("totalShares:    ", stflip.totalShares());
                console.log("calc balancePershare:", stflip.totalSupply() * 10**24 / stflip.totalShares());
                console.log("raw balancePershare:", stflip.totalSupplyRaw() * 10**18  / stflip.totalShares());

                require(_relativelyEq(expectedSupply, stflip.totalSupply()), "supply incorrect");
                require(expectedSupply == stflip.totalSupply(), "supply incorrect");
                require(stflip.totalSupplyRaw() *10**18 / stflip.totalShares() == stflip.balancePerShare(), "balance per share wrong");
                // uint256 calcBalancePerShare = stflip.totalSupply() * 10**24 / stflip.initSupply();
            
                // because totalSupply truncates digits its possible that the calculated balance per share would wrong compared to calculating it normally
                // TODO: figure out how to reconcile this 
                // require(stflip.balancePerShare() == calcBalancePerShare || stflip.balancePerShare() == calcBalancePerShare + 1, "balance per share incorrect");
            }

            vm.warp(jump*101 + 1);

            require(newSupply == stflip.totalSupply(), "rebase factor incorrect");
        }
    }

    function testFuzz_InterruptSyncSupply(uint256 supply1_, uint256 supply2_, uint256 supply3_, uint256 interval_,uint256 pctComplete_, uint256 initialShares_, bool slash1, bool slash2) external {
        uint256 interval = bound(interval_, 60*60 / 100, 60*60*24*7 / 100) * 100;
        uint256 initialShares = bound(initialShares_, 10**18, 100_000_000*10**18);
        uint256 pctComplete = bound(pctComplete_, 0, 100);
        uint256 supply1;
        uint256 supply2;
        uint256 supply3;

        if (slash1 == true) {
            supply1 = bound(supply1_, initialShares * 11 / 10, initialShares*10);
            supply2 = bound(supply2_, initialShares, supply1);
        }  else {
            supply1 = bound(supply1_, initialShares, initialShares*9);
            supply2 = bound(supply2_, supply1, initialShares*10);
        }

        if (slash2 == true) {
            supply3 = bound(supply3_, initialShares, supply2);
        }else {
            supply3 = bound(supply3_, supply2, initialShares*10);
        }

        console.log("supply1:           ", supply1);
        console.log("supply2:           ", supply2);
        console.log("supply3:           ", supply3);
        console.log("interval:          ", interval);
        console.log("slash1:            ", slash1);
        console.log("slash2:            ", slash2);
        console.log("pctComplete:       ", pctComplete);
        console.log("initialShares:     ", initialShares);


        vm.startPrank(owner);
            flip.mint(owner, initialShares);
            wrappedMinterProxy.mint(owner, initialShares);
            stflip.syncSupply(0, supply1, 0);
            stflip.syncSupply(0, supply2, interval);
        vm.stopPrank();

        if (slash1 == true) {
            console.log("actual v. expected totalSupply: ", stflip.totalSupply(), supply2);
            require(_relativelyEq(stflip.totalSupply(), supply2), "total supply changed");
        } else {
            console.log("actual v. expected totalSupply: ", stflip.totalSupply(), supply1);
            require(_relativelyEq(stflip.totalSupply(), supply1), "total supply changed");
        }
        

        vm.warp(block.timestamp + interval * pctComplete / 100);
        uint256 totalSupply = stflip.totalSupply();

        vm.startPrank(owner);
            stflip.syncSupply(0, supply3, interval);

        if (supply3 < totalSupply) {
            require(stflip.totalSupply() == supply3, "totalSupply incorrect");
            require(stflip.preSyncSupply() == supply3, "preSyncSupply incorrect");
            require(stflip.rewardsToSync() == 0, "rewardsToSync incorrect");
            require(stflip.syncEnd() == block.timestamp, "syncEnd incorrect");
            require(stflip.syncStart() == block.timestamp, "syncStart incorrect");
        } else {
            require(stflip.totalSupply() == totalSupply, "totalSupply incorrect");
            require(stflip.preSyncSupply() == totalSupply, "preSyncSupply incorrect");
            require(stflip.rewardsToSync() == supply3 - totalSupply, "rewardsToSync incorrect");
            require(stflip.syncEnd() == block.timestamp + interval, "syncEnd incorrect");
            require(stflip.syncStart() == block.timestamp, "syncStart incorrect");
        }

            
    }

    function testFuzz_Transfer(uint256 balancePerShare_, uint256 bal1_, uint256 bal2_, uint256 transfer_) public {
        uint256 balancePerShare = bound(balancePerShare_, 10**17, 10**20);
        uint256 bal1 = bound(bal1_, 1, 1_000_000*10**18);
        uint256 bal2 = bound(bal2_, 1, 1_000_000*10**18);
        uint256 transfer = bound(transfer_, 0, bal1);

        console.log("bal1",bal1);
        console.log("bal2",bal2);
        vm.startPrank(owner);
            stflip.mint(owner, 10**18);
            console.log("supply:", stflip.totalSupply());
            stflip.syncSupply(0, balancePerShare, 0);
            console.log("supply:", stflip.totalSupply());
            console.log("balancepshare:", balancePerShare);
        console.log("big sharetoB ", stflip.sharesToBalance(10**30));

            console.log('user1 balance:', stflip.balanceOf(user1));
            stflip.mint(user1, bal1);
        console.log("big sharetoB ", stflip.sharesToBalance(10**30));
            console.log('user1 balance:', stflip.balanceOf(user1));

            // wrappedBurnerProxy.burn(owner, balancePerShare);
        console.log("big sharetoB ", stflip.sharesToBalance(10**30));
            console.log('user1 balance:', stflip.balanceOf(user1));
            console.log('user2 balance:', stflip.balanceOf(user2));
        vm.stopPrank();



        console.log("user1 balance:", stflip.balanceOf(user1));
        console.log("balance should", bal1);
        console.log("user1 shares: ", stflip.sharesOf(user1));
        console.log("calc shares:  ",bal1 * 10**24/ balancePerShare);
        console.log("calc balance  "  ,bal1 * 10**24 / balancePerShare * balancePerShare / 10**24);
        console.log("reverse       ", stflip.sharesToBalance(stflip.balanceToShares(bal1)));
        require(stflip.sharesOf(user1)  == bal1 * 10**24 / balancePerShare,                            "user1 shares incorrect");
        require(stflip.balanceOf(user1) == bal1 * 10**24 / balancePerShare * balancePerShare / 10**24, "user1 balance incorrect");
        require(stflip.balanceOf(user1) == stflip.sharesToBalance(stflip.balanceToShares(bal1)),       "rounding not right");
        require(stflip.balanceOf(user1) == bal1 || stflip.balanceOf(user1) + 1 == bal1,                "rounding not right 2");
        vm.prank(owner);
            stflip.mint(user2, bal2);   

        console.log("user2 shares:", stflip.sharesOf(user2));
        console.log("calc shares: ", bal2 * 10**24 / balancePerShare);
        console.log("user2 bal    ", stflip.balanceOf(user2));
        console.log("calc bal     ", bal2 * 10**24 / balancePerShare * balancePerShare / 10**24);
        console.log("given bal    ", bal2);
        console.log("bPS          "       ,stflip.balancePerShare());

        console.log("big sharetoB ", stflip.sharesToBalance(10**30));


        require(stflip.sharesOf(user2)  <= bal2 * 10**24 / balancePerShare || stflip.sharesOf(user2)  >= bal2 * 10**24 / balancePerShare - 1,  "user2 shares incorrect");
        require(stflip.balanceOf(user2) == bal2 * 10**24 / balancePerShare * balancePerShare / 10**24 || stflip.balanceOf(user2) == bal2 * 10**24 / balancePerShare * balancePerShare / 10**24 + 1, "user2 balance incorrect");
        require(stflip.balanceOf(user2) == stflip.sharesToBalance(stflip.balanceToShares(bal2)),       "rounding not right");
        require(stflip.balanceOf(user2) == bal2 || stflip.balanceOf(user2) + 1 == bal2,                "rounding not right 2");

        vm.prank(user1);
            stflip.transfer(user2, transfer);
    
        console.log("user1 shares: ", stflip.balanceOf(user1));
        console.log("balance should", bal1 - transfer); 
        require(stflip.balanceOf(user1) == bal1 - transfer || stflip.balanceOf(user1) == bal1 - transfer - 1, "user1 balance incorrect");
        require(stflip.balanceOf(user2) == bal2 + transfer || stflip.balanceOf(user2) == bal2 + transfer - 1, "user2 balance incorrect");
    }

    function testFuzz_AccessControl(address from) public {
        vm.assume(from != address(minter));
        vm.startPrank(from);
            vm.expectRevert();
                stflip.mint(from, 10**18);

            vm.expectRevert();
                stflip.burn(10**18, from);

            vm.expectRevert();
                stflip.pauseTransfer(true);

            vm.expectRevert();
                stflip.pauseTransfer(true);
            vm.expectRevert();
                stflip.pauseTransfer(true);
            vm.expectRevert();
                stflip.rescueTokens(from, from, 10**18);

            vm.expectRevert();
                stflip.syncSupply(0, 10**18, 0);
        vm.stopPrank();
    }

    function test_Pause() public {

        vm.startPrank(owner);
            stflip.mint(owner, 10**18);

            stflip.pauseTransfer(true);
                vm.expectRevert(stFlip.TransferIsPaused.selector);
                    stflip.transfer(user2, 10**18);

                vm.expectRevert(stFlip.TransferIsPaused.selector);
                    stflip.transferFrom(owner, user2, 10**18);

                stflip.syncSupply(0,10**18, 0);
                wrappedBurnerProxy.burn(owner, 1000);
                stflip.mint(owner, 0);

            stflip.pauseRebase(true);
                vm.expectRevert(stFlip.TransferIsPaused.selector);
                    stflip.transfer(user2, 10**18);

                vm.expectRevert(stFlip.TransferIsPaused.selector);
                    stflip.transferFrom(owner, user2, 10**18);

                vm.expectRevert(stFlip.RebaseIsPaused.selector);
                    stflip.syncSupply(0,10**18, 0);

                wrappedBurnerProxy.burn(owner, 1000);
                stflip.mint(owner, 0);

            stflip.pauseBurn(true);
                vm.expectRevert(stFlip.TransferIsPaused.selector);
                    stflip.transfer(user2, 10**18);

                vm.expectRevert(stFlip.TransferIsPaused.selector);
                    stflip.transferFrom(owner, user2, 10**18);

                vm.expectRevert(stFlip.RebaseIsPaused.selector);
                    stflip.syncSupply(0,10**18, 0);

                vm.expectRevert(stFlip.BurnIsPaused.selector);
                    wrappedBurnerProxy.burn(owner, 1000);

                stflip.mint(owner, 0);

            stflip.pauseMint(true);
                vm.expectRevert(stFlip.TransferIsPaused.selector);
                    stflip.transfer(user2, 10**18);

                vm.expectRevert(stFlip.TransferIsPaused.selector);
                    stflip.transferFrom(owner, user2, 10**18);

                vm.expectRevert(stFlip.RebaseIsPaused.selector);
                    stflip.syncSupply(0,10**18, 0);

                vm.expectRevert(stFlip.BurnIsPaused.selector);
                    wrappedBurnerProxy.burn(owner, 1000);
                    
                vm.expectRevert(stFlip.MintIsPaused.selector);
                    stflip.mint(owner, 0);


        vm.stopPrank();
    }

}
