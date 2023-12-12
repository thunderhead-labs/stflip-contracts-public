pragma solidity ^0.8.19;

import "./FraxGovernorTestBase.t.sol";
import {OutputV1} from "@src/utils/RebaserV1.sol";
import {RebaserV1} from "@src/utils/RebaserV1.sol";
import {MinterV1} from "@src/utils/MinterV1.sol";
import {BurnerV1} from "@src/utils/BurnerV1.sol";
import {AggregatorV1} from "@src/utils/AggregatorV1.sol";

contract OutputUpgraded is OutputV1 {
    function upgraded() public pure returns (bool) {
        return true;
    }
}
contract RebaserUpgraded is RebaserV1 {
    function upgraded() public pure returns (bool) {
        return true;
    }
}
contract MinterUpgraded is MinterV1 {
    function upgraded() public pure returns (bool) {
        return true;
    }
}
contract BurnerUpgraded is BurnerV1 {
    function upgraded() public pure returns (bool) {
        return true;
    }
}
contract AggregatorUpgraded is AggregatorV1 {
    function upgraded() public pure returns (bool) {
        return true;
    }
}

contract TestGovernorChanges is FraxGovernorTestBase {

    function setUp() public override {
        super.setUp();
        vm.startPrank(owner);
            admin.transferOwnership(address(multisig));

            wrappedRebaserProxy.beginDefaultAdminTransfer(address(multisig2));
            wrappedOutputProxy.beginDefaultAdminTransfer(address(multisig2));
            wrappedMinterProxy.beginDefaultAdminTransfer(address(multisig2));
            wrappedBurnerProxy.beginDefaultAdminTransfer(address(multisig2));
            wrappedAggregatorProxy.beginDefaultAdminTransfer(address(multisig2));
            
            stflip.beginDefaultAdminTransfer(address(multisig2));
        vm.stopPrank();

        vm.warp(block.timestamp + wrappedRebaserProxy.defaultAdminDelay());
        require(admin.owner() == address(multisig), "proxy admin owner should be msig1");

        address[] memory contracts = new address[](5);
        contracts[0] = address(wrappedRebaserProxy);
        contracts[1] = address(wrappedOutputProxy);
        contracts[2] = address(wrappedMinterProxy);
        contracts[3] = address(wrappedBurnerProxy);
        contracts[4] = address(wrappedAggregatorProxy);

        GenericOptimisticProposalReturn[] memory ret = new GenericOptimisticProposalReturn[](5);

        for(uint i = 0; i < contracts.length; i++) {
            ret[i] = createGenericOptimisticProposal(
                GenericOptimisticProposalParams(
                    address(multisig2),
                    fraxGovernorOmega,
                    address(this),
                    contracts[i],
                    abi.encodeWithSignature("acceptDefaultAdminTransfer()"),
                    getSafe(address(multisig)).safe.nonce() + i
                )
            );
        }

        mineBlocksBySecond(fraxGovernorOmega.votingDelay() + fraxGovernorOmega.votingPeriod()+ 1);

        for (uint i = 0; i < contracts.length; i++) {
            fraxGovernorOmega.execute(ret[i].targets, ret[i].values, ret[i].calldatas , keccak256(bytes("")));
        }

        vm.startPrank(eoaOwners[0]);

            for (uint i = 0; i < contracts.length; i++) {
                getSafe(address(multisig2)).safe.execTransaction(
                    address(contracts[i]),
                    0,
                    abi.encodeWithSignature("acceptDefaultAdminTransfer()"),
                    Enum.Operation.Call,
                    0,
                    0,
                    0,
                    address(0),
                    payable(address(0)),
                    generateEoaSigs(3, ret[i].txHash)
                );
            }

            for (uint i = 0; i < contracts.length; i++) {
                require(ProxyAdmin(contracts[i]).owner() == address(multisig2), "contract owner should be msig2");
            }
        vm.stopPrank(); 
    }

    function test_TransferProxyAdminOwnership() external {
        
        createAndExecuteOptimisticProposal(
            GenericOptimisticProposalParams(
                address(multisig),
                fraxGovernorOmega,
                address(this),
                address(admin),
                abi.encodeWithSignature("transferOwnership(address)", address(uint160(10))),
                getSafe(address(multisig)).safe.nonce()
            )
        );
        
        require(address(uint160(10)) == admin.owner(), "admin owner should change");
    }

    function test_AddOperator() public {
        
        address manager = address(uint160(10));
        createAndExecuteOptimisticProposal(
            GenericOptimisticProposalParams(
                address(multisig2),
                fraxGovernorOmega,
                address(this),
                address(wrappedOutputProxy),
                abi.encodeWithSignature("addOperator(address,string,uint256,uint256,uint256)", manager, "test", 100, 300, 3),
                getSafe(address(multisig2)).safe.nonce()
            )
        );
        
        (address actualManager,) = wrappedOutputProxy.getOperatorAddresses(1);
        require(manager == actualManager, "operator not created");
    }

    function test_WhitelistValidators() external {
        test_AddOperator();

        bytes32[] memory validators = new bytes32[](1);
        validators[0] = bytes32(uint256(100));

        vm.prank(address(uint160(10)));
            wrappedOutputProxy.addValidators(validators, 1);
        

        createAndExecuteOptimisticProposal(
            GenericOptimisticProposalParams(
                address(multisig2),
                fraxGovernorOmega,
                address(this),
                address(wrappedOutputProxy),
                abi.encodeWithSignature("setValidatorsStatus(bytes32[],bool,bool)", validators, true, true),
                getSafe(address(multisig2)).safe.nonce()
            )
        );

        (uint256 id, bool whitelist, bool trackBalance) = wrappedOutputProxy.validators(validators[0]);
        // OutputV1.Validator memory validator = wrappedOutputProxy.validators(validators[0]);
        require(id == 1);
        require(whitelist == true);
        require(trackBalance == true);
    }

    function test_UpgradeContracts() external {
        address[] memory contracts = new address[](5);
        contracts[0] = address(new OutputUpgraded());
        contracts[1] = address(new RebaserUpgraded());
        contracts[2] = address(new MinterUpgraded());
        contracts[3] = address(new BurnerUpgraded());
        contracts[4] = address(new AggregatorUpgraded());

        TransparentUpgradeableProxy[] memory proxies = new TransparentUpgradeableProxy[](5);
        proxies[0] = output;
        proxies[1] = rebaser;
        proxies[2] = minter;
        proxies[3] = burner;
        proxies[4] = aggregator;

        for (uint i = 0; i < contracts.length; i++) {
            createAndExecuteOptimisticProposal(
                GenericOptimisticProposalParams(
                    address(multisig),
                    fraxGovernorOmega,
                    address(this),
                    address(admin),
                    abi.encodeWithSignature("upgrade(address,address)", proxies[i], contracts[i]),
                    getSafe(address(multisig)).safe.nonce()
                )
            );
        }

        for (uint i = 0; i < contracts.length; i++) {
            require(OutputUpgraded(contracts[i]).upgraded() == true);
        }
    }

    function test_SnapshotTime() external {
        uint256 currentTime = block.timestamp;
        createAndExecuteOptimisticProposal(
            GenericOptimisticProposalParams(
                address(multisig),
                fraxGovernorOmega,
                address(0),
                address(0),
                abi.encodeWithSignature(""),
                getSafe(address(multisig)).safe.nonce()
            )
        );

        require(stflip.lastSnapshotTime() == currentTime + fraxGovernorOmega.votingDelay(), "snapshot time should be updated");
        require(fraxGovernorOmega.lastSnapshotTime() == currentTime + fraxGovernorOmega.votingDelay(), "snapshot time should be updated");
        
        uint256 newTime = block.timestamp;
        createAndExecuteOptimisticProposal(
            GenericOptimisticProposalParams(
                address(multisig),
                fraxGovernorOmega,
                address(0),
                address(admin),
                abi.encodeWithSignature("upgrade(address,address)", address(stflip), address(stflipV1)),
                getSafe(address(multisig)).safe.nonce()
            )
        );

        
        require(stflip.lastSnapshotTime() == newTime + fraxGovernorOmega.votingDelay(), "snapshot time should be updated");
        require(fraxGovernorOmega.lastSnapshotTime() == newTime + fraxGovernorOmega.votingDelay(), "snapshot time should be updated");

        vm.startPrank(owner);
            stflip.revokeRole(stflip.GOVERNOR_ROLE(), address(fraxGovernorOmega));
        vm.stopPrank();

        uint256 newTime1 = block.timestamp;
        createAndExecuteOptimisticProposal(
            GenericOptimisticProposalParams(
                address(multisig),
                fraxGovernorOmega,
                address(0),
                address(admin),
                abi.encodeWithSignature("upgrade(address,address)", address(stflip), address(stflipV1)),
                getSafe(address(multisig)).safe.nonce()
            )
        );

        
        require(stflip.lastSnapshotTime() == newTime + fraxGovernorOmega.votingDelay(), "snapshot time should be updated");
        require(fraxGovernorOmega.lastSnapshotTime() == newTime1 + fraxGovernorOmega.votingDelay(), "snapshot time should be updated"); 
    }

    // function test_Parameters() external {
    //     console.log("quorumNumerator", fraxGovernorOmega.quorumNumerator());
    //     console.log("quorumDenominator", fraxGovernorOmega.quorumDenominator());
    //     console.log("shortCircuitNumerator", fraxGovernorOmega.shortCircuitNumerator(block.timestamp - 1));
    //     console.log("shortCircuitThreshold", fraxGovernorOmega.shortCircuitThreshold(block.timestamp - 1));
    //     console.log("votingDelay", fraxGovernorOmega.votingDelay());
    //     console.log("votingPeriod", fraxGovernorOmega.votingPeriod());

    // }
}

