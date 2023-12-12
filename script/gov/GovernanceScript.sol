pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../../src/deploy/DeployV1.sol";
import "../../src/token/stFlip.sol";
import "../../src/token/stFlip.sol";
import "../../src/utils/AggregatorV1.sol";
import "../../src/utils/MinterV1.sol";
import "../../src/utils/BurnerV1.sol";
import "../../src/utils/OutputV1.sol";
import "../../src/utils/RebaserV1.sol";
import "@src/governance/GovernanceOperations.sol";
import "@governance/src/FraxGovernorOmega.sol";
import "@governance/src/interfaces/IFraxGovernorOmega.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";
// import {optimisticTxProposalHash} from "@test/frax-governance/FraxGovernorTestBase.t.sol";

import { LibSort } from "@governance/node_modules/solady/src/utils/LibSort.sol";

contract GovernanceScript is Script, GovernanceOperations {

    IFraxGovernorOmega governor = IFraxGovernorOmega(payable(vm.envAddress("GOVERNOR")));
    
    address multisig;

    GenericOptimisticProposalParams params;
    bytes signatures;
    
    stFlip stflip;

    constructor() {

        multisig = 0x30A66D9f0A7B77D8a8FeE033fcF96741132CA967;
        stflip = stFlip(0x06592F75ed5E30C156190fd6B3E353af37770276);
        params = GenericOptimisticProposalParams(
            multisig,
            governor,
            address(0),
            0x8a85CBb160A44b0eEdB9D5eA25a035Fa80b3BBFB,
            abi.encodePacked(hex"99a88ec4000000000000000000000000b4cc04d6fa9a5da2d8714518c35fb3ed3eafd2c500000000000000000000000050f3bd802760c8ac264ef26b9c6ead4192ccf0d9"),//abi.encodeWithSignature("addOperator(address,string,uint256,uint256,uint256)", 0x4347F866A3019540e5304ded6c11F21102d6FE14, "First Operator", 1000, 1500, 5),
            DeployedSafe(payable(multisig)).nonce()+1
        );
        console.log("nonce:", DeployedSafe(payable(multisig)).nonce());
        bytes memory sig1 = abi.encodePacked(hex"e20ab8394e12efc134580e3d033d45a7ec3801429db74307d8bae0714dbbf9827ecc7d7c416502cee11bc268cfd0c55e98cafa0724d809aae2cdf7ba6d325c7f1c");
        // bytes memory sig2 = abi.encodePacked(hex"91ee97cd2c03538c7c7bc6df5f1ca04911d2319f4fe4c5919e8ec98f04ce1f080e3f8fb2b5fc84501a701aacf761df59ff9bb2cba26ffc87988d13cb953160901c");
        // bytes memory sig3 = abi.encodePacked(hex"8f24c2f4c86e612565e4b2b6c54e7419fdb266f882d4b823dcac22aaeaa7efc43788786250c4048b0c41842d07ccd4288044c9f0218729d25cfb9db527a7c7791c");

        signatures = abi.encodePacked(sig1);

    }
    
    // function rearrangeSig() public {
    //     bytes memory sig = abi.encodePacked(hex"4ba6ea2a51f41b8e528bfad625bb198cd80fa6d9943b3f89ba0165267e5383ee328735af7f6158a828be0e6fa7a4941358cad60b10ab2504ed5a017ddf1413d71b");
    //     console.log("Rearranging:");
    //     console.logBytes(sig);
    //     // (uint8 v, bytes32 r, bytes32 s) = abi.decode(sig,(uint8,bytes32,bytes32));
    //     require(sig.length == 65, "invalid signature length");
    //     uint8 v;
    //     bytes32 r;
    //     bytes32 s;
    //      assembly {
    //         // first 32 bytes, after the length prefix and v
    //         r := mload(add(sig, 33))
    //         // second 32 bytes
    //         s := mload(add(sig, 65))
    //         // first byte
    //         v := byte(0, mload(add(sig, 32)))
    //     }

    //     // Adjust for Ethereum's v value
    //     if (v < 27) {
    //         v += 27;
    //     }
    //     console.log(v);
    //     console.log("To:");
    //     console.logBytes(abi.encodePacked(r, s, v));
    // }

    function addTransaction() public {
        vm.startBroadcast(vm.envUint("GOVPK"));

            console.logBytes(signatures);
            GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);
            console.log("PID:    ", ret.pid);
            console.log("Txhash: ");
            console.logBytes32(ret.txHash);
        vm.stopBroadcast();

    }

    function executeProposal() public {
        vm.startBroadcast();
            executeOptimisticProposal(params, signatures);
    }



    function getProposalId() public {
        GenericOptimisticProposalReturn memory ret = optimisticProposalInfo(params);

        console.log("PID: ", ret.pid);
    }

    function safeTxHash() public {
        console.log("Safe Txhash: ");
        console.logBytes32( safeTxHash(params));
    }

    function proposalStatus() public {
        GenericOptimisticProposalReturn memory ret = optimisticProposalInfo(params);
        proposalStatus(ret.pid);
    }

    function allProposals() public {
        
        for (uint i = 3; i < 20; i++) {
            (bytes32 txhash, uint256 pid ) = nonceToProposalData(governor, multisig, i);
            if (txhash != bytes32(0)) {
                proposalStatus(pid);
            } else {
                console.log("=== Empty ===");
            }
            console.log("Nonce:       ", i);
            console.logBytes32(txhash);
            console.log();
        }
    }

    function proposalStatus(uint256 proposalId) internal view {
        IGovernor.ProposalState status = IGovernor.ProposalState(governor.state(proposalId));        
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);
        (address proposer, uint40 voteStart, uint40 voteEnd, bool executed, bool canceled) = governor.proposals(proposalId);

        string memory statusStr = "";
        if (status == IGovernor.ProposalState.Pending) {
            statusStr = "Pending";
        } else if (status == IGovernor.ProposalState.Active) {
            statusStr = "Active";
        } else if (status == IGovernor.ProposalState.Canceled) {
            statusStr = "Canceled";
        } else if (status == IGovernor.ProposalState.Defeated) {    
            statusStr = "Defeated";
        } else if (status == IGovernor.ProposalState.Succeeded) {
            statusStr = "Succeeded";
        } else if (status == IGovernor.ProposalState.Queued) {
            statusStr = "Queued";
        } else if (status == IGovernor.ProposalState.Expired) {
            statusStr = "Expired";
        } else if (status == IGovernor.ProposalState.Executed) {
            statusStr = "Executed";
        } 

        console.log("=== Status ===");
        console.log("Proposal state: ", statusStr);
        console.log("Against: ", againstVotes);
        console.log("For:     ", forVotes);
        console.log("Abstain: ", abstainVotes);

        console.log("=== INFO ===");
        console.log("Proposer:    ", proposer);
        console.log("Vote Started:", block.timestamp > voteStart ? block.timestamp - voteStart: voteStart - block.timestamp, block.timestamp > voteStart ? "ago. actual:" : "in future. actual:", voteStart);
        console.log("Vote End:    ", block.timestamp > voteEnd   ? block.timestamp - voteEnd:   voteEnd   - block.timestamp, block.timestamp > voteEnd   ? "ago. actual:" : "in future. actual:", voteEnd);
        console.log("Executed:    ", executed);
        console.log("Cancelled:   ", canceled);
        console.log("PID:         ", proposalId);


    }


    function castVote() external  {
        uint256 pk = vm.envUint("USERKEY");
        address user = vm.addr(pk);
        GenericOptimisticProposalReturn memory ret = optimisticProposalInfo(params);

        vm.broadcast(pk);
            governor.castVote(ret.pid, 1);
    }

    function rejectTransaction() external {
        
            
        uint256 currentNonce = DeployedSafe(payable(multisig)).nonce();


        GenericOptimisticProposalParams memory rejectParams = GenericOptimisticProposalParams(
            multisig,
            governor,   
            address(0),
            multisig,
            bytes(""),
            currentNonce
        );
        vm.startBroadcast(addressToPk[0x2f9900C7678b31F6f292F8F22E7b47308f614043]);

            governor.rejectTransaction(multisig, currentNonce);

            DeployedSafe(payable(multisig)).execTransaction(
                multisig,
                0,
                bytes(""),
                Enum.Operation.Call,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                generateEoaSigs(3, safeTxHash(rejectParams))
            );
    }

    function abortTransaction() external {
        
        uint256 nonce = DeployedSafe(payable(multisig)).nonce();
        GenericOptimisticProposalParams memory abortParams = GenericOptimisticProposalParams(
            multisig,
            governor,   
            address(0),
            multisig,
            bytes(""),
            nonce
        );
        // uint256 pk = vm.envUint("USER_PK");
        // address user = vm.addr(pk);
        bytes memory abortSignatures = generateEoaSigs(3, safeTxHash(abortParams));
        vm.startBroadcast(addressToPk[0x2f9900C7678b31F6f292F8F22E7b47308f614043]);


            governor.abortTransaction(multisig, abortSignatures);
            
            DeployedSafe(payable(multisig)).execTransaction(
                multisig,
                0,
                bytes(""),
                Enum.Operation.Call,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                generateEoaSigs(3, safeTxHash(abortParams))
            );
    }

}