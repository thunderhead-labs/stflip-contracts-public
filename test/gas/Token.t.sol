// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../MainMigration.sol";


contract TokenGas is MainMigration {
    address[] public addresses;

    function setUp() public {
        MainMigration migration = new MainMigration();

        vm.prank(owner);
            flip.mint(owner, 100_000*10**18);
        for (uint i = 1; i < 30; i++) {
            addresses.push(address(uint160(i)));

            vm.startPrank(owner);
                wrappedMinterProxy.mint(addresses[i-1], 100*10**18);
                flip.mint(addresses[i-1], 100*10**18);
            vm.stopPrank();

            vm.prank(addresses[i-1]);
                flip.approve(address(wrappedMinterProxy), 2**256 - 1);

        }

        vm.prank(owner);
            flip.mint(address(uint160(100)), 10**18);

        vm.prank(address(uint160(100)));
            flip.approve(address(wrappedMinterProxy), 10**18);

    }

    function test_FirstTransfer() public {
        vm.prank(address(uint160(1)));
            _gas();
            stflip.transfer(address(uint160(1000)), 10**18);
            gas_();
    }

    function test_SecondTransfer() public {


        vm.prank(addresses[1]);
            _gas();
            stflip.transfer(addresses[2], 10**18);
            gas_();
    }

    function test_FirstMint() public {
        vm.prank(address(uint160(100)));
            _gas();
            wrappedMinterProxy.mint(address(uint160(100)), 10**18);
            gas_();
    }

    function test_SecondMint() public {
        vm.prank(addresses[2]);
            _gas();
            wrappedMinterProxy.mint(addresses[2], 10**18);
            gas_();
    }

}

