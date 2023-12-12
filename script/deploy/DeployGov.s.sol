// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import {
    GovernorCompatibilityBravo
} from "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
// import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
import { IGovernorTimelock } from "@openzeppelin/contracts/governance/extensions/IGovernorTimelock.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "frax-std/FraxTest.sol";
import { SafeTestTools, SafeTestLib, SafeInstance, DeployedSafe, ModuleManager } from "safe-tools/SafeTestTools.sol";
import "safe-contracts/GnosisSafe.sol";
import "safe-contracts/proxies/GnosisSafeProxyFactory.sol";
import "safe-tools/CompatibilityFallbackHandler_1_3_0.sol";
import { SignMessageLib } from "safe-contracts/examples/libraries/SignMessage.sol";
import { LibSort } from "solady/utils/LibSort.sol";
import { FraxGovernorAlpha, ConstructorParams } from "@governance/src/FraxGovernorAlpha.sol";
import { FraxGovernorOmega } from "@governance/src/FraxGovernorOmega.sol";
import "@governance/src/VeFxsVotingDelegation.sol";
import "@governance/src/FraxGuard.sol";
// import "./mock/FxsMock.sol";
// import "./utils/VyperDeployer.sol";
import "@governance/src/interfaces/IFraxGovernorAlpha.sol";
import "@governance/src/interfaces/IFraxGovernorOmega.sol";
import { FraxGovernorBase } from "@governance/src/FraxGovernorBase.sol";
import { deployFraxGuard } from "@script-deploy/DeployFraxGuard.s.sol";
// import { deployVeFxsVotingDelegation } from "@script-deploy/DeployVeFxsVotingDelegation.s.sol";
// import { deployFraxGovernorAlpha, deployTimelockController } from "@script-deploy/DeployFraxGovernorAlphaAndTimelock.s.sol";
import { deployFraxGovernorOmega } from "@script-deploy/DeployFraxGovernorOmega.s.sol";
import { deployFraxCompatibilityFallbackHandler } from "@script-deploy/DeployFraxCompatibilityFallbackHandler.s.sol";
// import { deployMockFxs, deployVeFxs } from "@script-deploy/test/DeployTestFxs.s.sol";
import { FraxCompatibilityFallbackHandler } from "@governance/src/FraxCompatibilityFallbackHandler.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { stFlip } from "@src/token/stFlip.sol";
import {Script} from"forge-std/Script.sol";
import {GovernanceOperations} from "@src/governance/GovernanceOperations.sol";

contract DeployGovScript is GovernanceOperations, Script {

    SafeInstance safe;
    SafeInstance safe2;
    ISafe multisig;
    ISafe multisig2;
    stFlip veFxsVotingDelegation;
    // ISafe fraxGovernorAlpha;
    // TimelockController timelockController;
    IFraxGovernorOmega fraxGovernorOmega;
    FraxGuard fraxGuard;
    FraxCompatibilityFallbackHandler fraxCompatibilityFallbackHandler;
    SignMessageLib signMessageLib;

    address deployer;
    address governor;
    
    function _setState() internal {
        multisig = ISafe(vm.envAddress("ALPHASIG"));
        multisig2 = ISafe(vm.envAddress("CONTRACTSIG"));
        deployer = vm.envAddress("DEPLOYER");

    }
    function deployOmegaAndConfigure() public {
        _setState();

        vm.startBroadcast();

            console.log("DEPLOYER", address(this));
            signMessageLib = new SignMessageLib();
            console.log("DEPLOYED SIGNMESSAGELIB:", address(signMessageLib));

            address[] memory _safeAllowlist = new address[](2);
            _safeAllowlist[0] = address(multisig);
            _safeAllowlist[1] = address(multisig2);

            address[] memory _delegateCallAllowlist = new address[](1);
            _delegateCallAllowlist[0] = address(signMessageLib);

            (address payable _fraxGovernorOmega, , ) = deployFraxGovernorOmega(
                vm.envAddress("STFLIP"),
                vm.envAddress("STFLIP"),
                _safeAllowlist,
                _delegateCallAllowlist,
                payable(address(multisig)),
                60,
                2 minutes,
                95,
                95
            );
            console.log("DEPLOYED OMEGA:", _fraxGovernorOmega);

            fraxGovernorOmega = IFraxGovernorOmega(_fraxGovernorOmega);
            (address _fraxCompatibilityFallbackHandler, ) = deployFraxCompatibilityFallbackHandler();
            console.log("DEPLOYED FALLBACKHANDLER:", _fraxCompatibilityFallbackHandler);
            fraxCompatibilityFallbackHandler = FraxCompatibilityFallbackHandler(_fraxCompatibilityFallbackHandler);

            setupFraxFallbackHandler({
                _safe: address(multisig),
                _handler: _fraxCompatibilityFallbackHandler
            });
            setupFraxFallbackHandler({
                _safe: address(multisig2),
                _handler: _fraxCompatibilityFallbackHandler
            });

            (address _fraxGuard, , ) = deployFraxGuard(_fraxGovernorOmega);
            console.log("DEPLOYED FRAXGUARD", _fraxGuard);
            fraxGuard = FraxGuard(_fraxGuard);

            addSignerToSafe({
                _safe: address(multisig),
                newOwner: address(fraxGovernorOmega),
                threshold: 1,
                nonce: 1
            });
            addSignerToSafe({
                _safe: address(multisig2),
                newOwner: address(fraxGovernorOmega),
                threshold: 1,
                nonce: 1
            });

            // call setGuard on Safe
            setupFraxGuard({ _safe: address(multisig), _fraxGuard: address(fraxGuard) });
            setupFraxGuard({ _safe: address(multisig2), _fraxGuard: address(fraxGuard) });
        vm.stopBroadcast();
    }

    function addSigners() public {
        fraxGovernorOmega = IFraxGovernorOmega(vm.envAddress("GOVERNOR"));

        _setState();

        eoaOwners.push(vm.envAddress("SIGNER2"));
        eoaOwners.push(vm.envAddress("SIGNER3"));
        eoaOwners.push(vm.envAddress("SIGNER4"));
        eoaOwners.push(vm.envAddress("SIGNER5"));
        vm.startBroadcast(vm.envUint("SIGNER1KEY"));
        for (uint i; i < eoaOwners.length; i++) {
            addSignerToSafe({
                _safe: address(multisig),
                newOwner: eoaOwners[i],
                threshold: 1,
                nonce: 2 + i
            });
            addSignerToSafe({
                _safe: address(multisig2),
                newOwner: eoaOwners[i],
                threshold: 1,
                nonce: 2 + i
            });
        }
    }

    function increaseThreshold() public {
        fraxGovernorOmega = IFraxGovernorOmega(vm.envAddress("GOVERNOR"));

        vm.startBroadcast(vm.envUint("SIGNER1KEY"));

        _setState();
            setSafeThreshold({
                _safe: address(multisig),
                threshold: 3,
                nonce: 3
            });

            setSafeThreshold({
                _safe: address(multisig2),
                threshold: 3,
                nonce: 3
            });
    }

    function setupFraxGuard(address _safe, address _fraxGuard) public {
        bytes memory data = abi.encodeWithSignature("setGuard(address)", address(_fraxGuard));
        DeployedSafe _dsafe = DeployedSafe(payable(_safe));

        _dsafe.execTransaction(
            address(_dsafe),
            0,
            data,
            Enum.Operation.Call,
            0,
            0,
            0,
            payable(address(0)),
            payable(address(0)),
            abi.encodePacked(bytes32(uint256(uint160(deployer))), bytes32(0), uint8(1))
        );
    }

    function setupFraxFallbackHandler(address _safe, address _handler) public {
        bytes memory data = abi.encodeWithSignature("setFallbackHandler(address)", address(_handler));
        DeployedSafe _dsafe = DeployedSafe(payable(_safe));

        _dsafe.execTransaction(
            address(_dsafe),
            0,
            data,
            Enum.Operation.Call,
            0,
            0,   
            0,
            payable(address(0)),
            payable(address(0)),
            abi.encodePacked(bytes32(uint256(uint160(deployer))), bytes32(0), uint8(1))
        );
    }

    function addSignerToSafe(address _safe, address newOwner, uint256 threshold, uint256 nonce) internal {
        bytes memory data = abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", newOwner, threshold);
        bytes memory sig = abi.encodePacked(bytes32(uint256(uint160(deployer))), bytes32(0), uint8(1));

        if (newOwner == address(fraxGovernorOmega)) {
            DeployedSafe(payable(_safe)).execTransaction(
                address(_safe),
                0,
                data,
                Enum.Operation.Call,
                0,
                0,
                0,
                payable(address(0)),
                payable(address(0)),
                abi.encodePacked(bytes32(uint256(uint160(deployer))), bytes32(0), uint8(1))
            );
        } else {
            GenericOptimisticProposalParams memory params = GenericOptimisticProposalParams(
                _safe,
                fraxGovernorOmega,
                address(0),
                _safe,
                data,
                nonce
            );

            DeployedSafe(payable(_safe)).approveHash(safeTxHash(params));

            createGenericOptimisticProposal(
                params,
                sig
            );
        }

    }

    function setSafeThreshold(address _safe, uint256 threshold, uint256 nonce) internal {
        bytes memory data = abi.encodeWithSignature("changeThreshold(uint256)", threshold);
        bytes memory sig = abi.encodePacked(bytes32(uint256(uint160(deployer))), bytes32(0), uint8(1));

        GenericOptimisticProposalParams memory params = GenericOptimisticProposalParams(
            _safe,
            fraxGovernorOmega,
            address(0),
            _safe,
            data,
            nonce
        );

        DeployedSafe(payable(_safe)).approveHash(safeTxHash(params));

        createGenericOptimisticProposal(
            params,
            sig
        );
    }
}
