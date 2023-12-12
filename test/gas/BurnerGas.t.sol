// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../MainMigration.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BurnerGasTest is MainMigration {
    using stdStorage for StdStorage;

    function setUp() public {
        vm.startPrank(owner);
            flip.mint(address(uint160(1)), 100_000*10**18);

        vm.startPrank(address(uint160(1)));
            flip.approve(address(minter), 2**256 - 1);
            wrappedMinterProxy.mint(address(uint160(1)), 100_000*10**18);
            wrappedBurnerProxy.burn(address(uint160(1)), 50_000*10**18);
        vm.stopPrank();
    }

    function testGas_Burn() public {
        vm.prank(address(uint160(1)));
        _gas();
        wrappedBurnerProxy.burn(address(uint160(1)), 25_000*10**18);
        gas_();
    }

    function testGas_Redeem() public {
        vm.prank(address(uint160(1)));
        _gas();
        wrappedBurnerProxy.redeem(1);
        gas_();
    }

}
