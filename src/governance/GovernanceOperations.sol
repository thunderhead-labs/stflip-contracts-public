pragma solidity ^0.8.20;

import { DeployedSafe } from "safe-tools/SafeTestTools.sol";
import { IFraxGovernorOmega } from "@governance/src/interfaces/IFraxGovernorOmega.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
import { Enum, ISafe } from "@governance/src/interfaces/ISafe.sol";
import { LibSort } from "solady/utils/LibSort.sol";
import { Test } from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
contract GovernanceOperations is Test {
    using LibSort for address[];

    struct GenericOptimisticProposalParams {
        address _safe;
        IFraxGovernorOmega _fraxGovernorOmega;
        address caller;
        address to; // address to call
        bytes _txdata;
        uint256 nonce;
    }

    struct GenericOptimisticProposalReturn {
        uint256 pid;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        bytes32 txHash;
    }


    address[] accounts;
    address[] eoaOwners;

    mapping(address => uint256) addressToPk;

    function safeTxData(
        GenericOptimisticProposalParams memory params
    ) internal returns (bytes memory txData) {
        txData = DeployedSafe(payable(params._safe)).encodeTransactionData(
            address(params.to),
            0,
            params._txdata,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            address(0),
            params.nonce //getSafe(params._safe).safe.nonce()
        );
    }

    function safeTxHash(
        GenericOptimisticProposalParams memory params
    ) internal returns (bytes32 txhash) {
        txhash = keccak256(safeTxData(params));
    }

    function optimisticProposalInfo(GenericOptimisticProposalParams memory params) 
        internal returns (GenericOptimisticProposalReturn memory ret) {
        bytes memory txData = safeTxData(params);

        ret.txHash = keccak256(txData);

        (ret.pid, ret.targets, ret.values, ret.calldatas) = optimisticTxProposalHash(params._safe, params._fraxGovernorOmega, txData);

    }

    function optimisticTxProposalHash(
        address _safe,
        IFraxGovernorOmega _fraxGovernorOmega,
        bytes memory txData
    ) internal  returns (uint256, address[] memory, uint256[] memory, bytes[] memory) {
        bytes memory data = abi.encodeCall(ISafe.approveHash, keccak256(txData));

        address[] memory targets = new address[](1);
        targets[0] = address(_safe);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = data;
        return (
            _fraxGovernorOmega.hashProposal(targets, values, calldatas, keccak256(bytes(""))),
            targets,
            values,
            calldatas
        );
    }

    function createGenericOptimisticProposal(
        GenericOptimisticProposalParams memory params,
        bytes memory signatures
    ) internal returns (GenericOptimisticProposalReturn memory ret) {
        ret = optimisticProposalInfo(params);

        IFraxGovernorOmega.TxHashArgs memory args = IFraxGovernorOmega.TxHashArgs(
            address(params.to),
            0,
            params._txdata,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            address(0),
            params.nonce //getSafe(params._safe).safe.nonce()
        );

        params._fraxGovernorOmega.addTransaction(address(params._safe), args, signatures);
    }
    
    function createGenericOptimisticProposal(
        GenericOptimisticProposalParams memory params
    ) internal returns (GenericOptimisticProposalReturn memory ret) {
        ret = createGenericOptimisticProposal(params, generateEoaSigs(3, safeTxHash(params)));
    }
    
    function executeOptimisticProposal(
        GenericOptimisticProposalParams memory params,
        bytes memory signatures
    ) internal {
        GenericOptimisticProposalReturn memory ret = optimisticProposalInfo(params);

        console.log("here");
        for (uint i = 0; i < ret.targets.length; i++) {
            console.log("targets   ", ret.targets[i]);
        }
        console.log("here");

        for (uint i = 0; i < ret.values.length; i++) {
            console.log("values    ", ret.values[i]);
        }

        for (uint i = 0; i < ret.calldatas.length; i++) {
            console.log("calldatas ");
            console.logBytes( ret.calldatas[i]);
        }

        console.log("desc.     ");
        console.logBytes32(keccak256(bytes("")));
        params._fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas , keccak256(bytes("")));

        
        console.log("to", params.to);
        console.logBytes(params._txdata);
        DeployedSafe(payable(params._safe)).execTransaction(
            address(params.to),
            0,
            params._txdata,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            signatures
        );
    }

    function executeOptimisticProposal(
        GenericOptimisticProposalParams memory params
    )  internal {
        executeOptimisticProposal(params, generateEoaSigs(3, safeTxHash(params)));
    }

    function generateEoaSigs(uint256 amount, bytes32 txHash) public view returns (bytes memory sigs) {
        address[] memory sortedEoas = sortEoaOwners();
        console.log("Signing txhash:");
        console.logBytes32(txHash);
        for (uint256 i = 0; i < amount; ++i) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(addressToPk[sortedEoas[i]], txHash);

            sigs = abi.encodePacked(sigs, r, s, v);

            console.log("Signature of ", sortedEoas[i]);
            console.logBytes(abi.encodePacked(r, s, v));
        }

        console.logBytes(sigs);
    }

    function sortEoaOwners() public view returns (address[] memory sortedEoas) {
        sortedEoas = new address[](eoaOwners.length);
        for (uint256 i = 0; i < eoaOwners.length; ++i) {
            sortedEoas[i] = eoaOwners[i];
        }
        LibSort.sort(sortedEoas);
    }

    function _optimisticProposalArgs(
        address safe,
        bytes32 txHash
    ) internal pure returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) {
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);

        targets[0] = safe;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(ISafe.approveHash.selector, txHash);
    }

    function hashProposal(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash) internal returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    function nonceToProposalData(IFraxGovernorOmega governor, address multisig, uint256 nonce) internal returns (bytes32, uint256) {
        bytes32 txhash = governor.$gnosisSafeToNonceToTxHash(multisig, nonce);
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _optimisticProposalArgs(multisig, txhash);
        uint256 pid = hashProposal(targets, values, calldatas, keccak256(bytes("")));

        return (txhash, pid);
    }
}