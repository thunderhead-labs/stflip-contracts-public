// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../MainMigration.sol";
import "../../src/mock/SnapshotFlip.sol";

contract TokenGas is MainMigration {
    address[] public addresses;

    SnapshotFlip snapshot;
    function setUp() public {
        vm.startPrank(owner);
            snapshot = new SnapshotFlip(100_000*10**18);
            snapshot.mint(address(uint160(1)), 1000*10**18);
            snapshot.mint(address(uint160(2)), 1000*10**18);
            snapshot.mint(address(uint160(3)), 1000*10**18);

        vm.stopPrank();

        snapshot.snapshot();
            vm.prank(address(uint160(1)));
            _gas();
            snapshot.transfer(address(uint160(2)), 10**18);
            gas_();
    }

    function test_FirstTransfer() public {
        vm.prank(address(uint160(1)));
            _gas();
            snapshot.transfer(address(uint160(2)), 10**18);
            gas_();
    }

    function test_SecondTransfer() public {
        snapshot.snapshot();
        vm.startPrank(address(uint160(3)));
            _gas();
            snapshot.transfer(address(uint160(2)), 10**18);
            gas_();
            snapshot.transfer(address(uint160(2)), 10**18);


    }

    // function test_FirstMint() public {
    //     vm.prank(address(uint160(100)));
    //         _gas();
    //         wrappedMinterProxy.mint(address(uint160(100)), 10**18);
    //         gas_();
    // }

    // function test_SecondMint() public {
    //     vm.prank(addresses[2]);
    //         _gas();
    //         wrappedMinterProxy.mint(addresses[2], 10**18);
    //         gas_();
    // }

}

