
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/utils/BurnerV1.sol";
import "./MainMigration.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


contract MigrationTest is MainMigration {

    function setUp() public {
        MainMigration migration = new MainMigration();
    }

    function test_CanUpgrade() public {
        BurnerV1 newBurner = new BurnerV1();
        vm.prank(admin.owner());
        admin.upgrade(ITransparentUpgradeableProxy(payable(burner)), address(newBurner));

        MinterV1 newMinter = new MinterV1();
        vm.prank(admin.owner());
        admin.upgrade(ITransparentUpgradeableProxy(payable(minter)), address(newMinter));

        AggregatorV1 newAggregator = new AggregatorV1();
        vm.prank(admin.owner());
        admin.upgrade(ITransparentUpgradeableProxy(payable(aggregator)), address(newAggregator));
    }

    function test_OnlyInitializeOnce() public {
        vm.expectRevert("Initializable: contract is already initialized");
        wrappedBurnerProxy.initialize(address(stflip), address(this), address(flip), address(output));

        vm.expectRevert("Initializable: contract is already initialized");
        wrappedMinterProxy.initialize(address(stflip), address(output), address(owner), address(flip));

        vm.expectRevert("Initializable: contract is already initialized");
        wrappedAggregatorProxy.initialize(address(stflip), address(output), address(canonicalPool), address(owner), address(flip), owner);
    }

}
