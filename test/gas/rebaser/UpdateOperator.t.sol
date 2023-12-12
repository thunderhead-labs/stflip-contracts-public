// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../MainMigration.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract RebaserGasTest is MainMigration {
    using stdStorage for StdStorage;
    struct Params {
        uint256 staked;
        uint256 unstaked;
        uint256 serviceFeeBps;
        uint256 validatorFeeBps;
        uint256 rewards;
        uint256 slashCounter;
        uint256 operatorId;
        uint256 operatorBalance;
        uint256 initialBalance;
        uint256 initialTotalOperatorPendingFee;
        uint256 initialServicePendingFee;
    }
    Params params;
    function setUp() public {

        Params memory p;
        p.rewards = 1_000_000*10**18;
        p.slashCounter = 2_000_000 * 10**18;
        p.staked = 2_000_000 * 10**18;

        p.unstaked = (p.staked + p.rewards - p.slashCounter) / 2;

        p.serviceFeeBps = 5000;
        p.validatorFeeBps = 10000 - p.serviceFeeBps;
        // p.operatorBalance = 1_00_000 * 10**18;
        
        bytes32[] memory inp = new bytes32[](5);

        for (uint i = 1; i < 5; i++) {
            vm.startPrank(owner);
                wrappedOutputProxy.addOperator(owner, "owner", p.serviceFeeBps, p.validatorFeeBps, 20);
                for (uint j = 0; j < 5; j++) {
                    inp[j] = keccak256(abi.encodePacked(i, j));
                    // console.logBytes32(inp[j]);
                }
                wrappedOutputProxy.addValidators(inp, i);
                wrappedOutputProxy.setValidatorsStatus(inp, true, true);
            vm.stopPrank();

            wrappedOutputProxy.Harness_setOperator(p.staked, p.unstaked, p.serviceFeeBps, p.validatorFeeBps, i);
            wrappedRebaserProxy.Harness_setOperator(p.rewards, p.slashCounter, 1, i);
            wrappedRebaserProxy.Harness_setPendingFee(1);
            // console.log(p.staked, p.unstaked, p.rewards, p.slashCounter);

            // uint256 initialBalance = (staked - (unstaked - rewards)) - slashCounter;
            p.initialBalance = p.staked + p.rewards - p.unstaked - p.slashCounter;

            params = p;

        }
        console.log();
    }

    function testGas_UpdateOperator() public {
        _gas();
        wrappedRebaserProxy.Harness_updateOperator(550_000 * 10**18, 1, true);
        gas_();
    }

    // function testGas_UpdateOperator2() public {
    //     _gas();
    //     wrappedRebaserProxy.Harness_updateOperator2(550_000 * 10**18, 1, true);
    //     gas_();
    // }

    function testGas_UpdateOperators() public {
        uint256 amount = 5;
        bytes32[] memory addresses = new bytes32[]((amount - 1) * 5);
        uint256[] memory amounts = new uint256[]((amount - 1) * 5);
        for (uint i = 1; i < amount; i++) {
            for (uint j = 0; j < 5; j++) {
                addresses[(i-1) * 5 + j] = keccak256(abi.encodePacked(i, j));
                amounts[(i-1) * 5 + j] = 101_000 * 10**18;
                // console.logBytes32(addresses[(i-1) * 5 + j]);
            }

        } 

        _gas();
        wrappedRebaserProxy.Harness_updateOperators(amounts, addresses, true);
        gas_();

    }

   

    function testGas_Rebase() public {
        uint256 amount = 5;
        bytes32[] memory addresses = new bytes32[]((amount - 1) * 5);
        uint256[] memory amounts = new uint256[]((amount - 1) * 5);
        uint256 total;
        for (uint i = 1; i < amount; i++) {
            for (uint j = 0; j < 5; j++) {
                addresses[(i-1) * 5 + j] = keccak256(abi.encodePacked(i, j));
                amounts[(i-1) * 5 + j] = 100_001 * 10**18;
                // console.logBytes32(addresses[(i-1) * 5 + j]);
                total += 100_000 * 10**18;
            
            }

        } 

        vm.startPrank(owner);
            flip.mint(address(this), 4*500_000 * 10**18);
            stflip.mint(address(this),total);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 5 days);
        vm.prank(owner);
        _gas();
        wrappedRebaserProxy.rebase(0,amounts, addresses, true);
        gas_();
    }

}
