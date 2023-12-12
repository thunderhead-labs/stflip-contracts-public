// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../MainMigration.sol";
// import {FraxGovernorOmega} from "@governance/src/FraxGovernorOmega.sol";
// import {FraxGuard} from "@governance/src/FraxGuard.sol";
// import {FraxCompatibilityFallbackHandler} from "@governance/src/FraxCompatibilityFallbackHandler.sol";
// import "../../src/mock/IGnosisSafe.sol";
// import "../../src/mock/IGnosisSafeProxyFactory.sol";
// import { deployFraxGovernorOmega } from  "@script-deploy/DeployFraxGovernorOmega.s.sol";
// import { deployFraxCompatibilityFallbackHandler } from "@script-deploy/DeployFraxCompatibilityFallbackHandler.s.sol";
// import { deployFraxGuard } from "@script-deploy/DeployFraxGuard.s.sol";
// // import { SignMessageLib } from "@governance/node_modules/@gnosis.pm/safe-contracts/contracts/examples/libraries/SignMessage.sol";

// import "safe-tools/SafeTestTools.sol";

// contract GovernanceTest is MainMigration, SafeTestTools {
//     address[] public addresses;
//     using SafeTestLib for SafeInstance;
//     FraxGovernorOmega fraxGovernorOmega;
//     FraxGuard fraxGuard;
//     FraxCompatibilityFallbackHandler fraxCompatibilityFallbackHandler;
//     SignMessageLib signMessageLib;
//     function setUp() public {
//         // _makePersistent();

//         // uint256 mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"));


//         // vm.selectFork(mainnetFork);
//         // vm.rollFork(17698215); 

//         // address singleton = 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552;

//         // IGnosisSafeProxyFactory factory = IGnosisSafeProxyFactory(address(0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2));

//         // factory.createProxy(singleton, "");
//         SafeInstance memory safeInstance = _setupSafe();
//         IGnosisSafe multisig = IGnosisSafe(payable(address(getSafe().safe)));

//         address[] memory _safeAllowlist = new address[](1);
//         _safeAllowlist[0] = address(multisig);

//         signMessageLib = new SignMessageLib();
//         address[] memory _delegateCallAllowlist = new address[](1);
//         _delegateCallAllowlist[0] = address(signMessageLib);


//         (address payable _fraxGovernorOmega, , ) = deployFraxGovernorOmega(
//             address(stflip),
//             _safeAllowlist,
//             _delegateCallAllowlist,
//             payable(address(uint160(0)))
//         );

//         (address _fraxGuard, , ) = deployFraxGuard(_fraxGovernorOmega);
//         (address _fraxCompatibilityFallbackHandler, ) = deployFraxCompatibilityFallbackHandler();

//         fraxGovernorOmega = FraxGovernorOmega(_fraxGovernorOmega);
//         fraxCompatibilityFallbackHandler = FraxCompatibilityFallbackHandler(_fraxCompatibilityFallbackHandler);
//         fraxGuard = FraxGuard(_fraxGuard);


//         setupFraxFallbackHandler({
//             _safe: address(multisig),
//             signer: eoaOwners[0],
//             _handler: _fraxCompatibilityFallbackHandler
//         });
//     }   

//     function _makePersistent() internal {
//         vm.makePersistent(address(flip));

//         vm.makePersistent(address(stflipProxy));
//         vm.makePersistent(address(stflipV1));

//         vm.makePersistent(address(minter));
//         vm.makePersistent(address(minterV1));

//         vm.makePersistent(address(burner));
//         vm.makePersistent(address(burnerV1));

//         vm.makePersistent(address(aggregator));
//         vm.makePersistent(address(aggregatorV1));

//         vm.makePersistent(address(output));
//         vm.makePersistent(address(outputV1));

//         vm.makePersistent(address(rebaser));
//         vm.makePersistent(address(rebaserV1));

//         vm.makePersistent(address(owner));
//         vm.makePersistent(address(admin));
//     }
//     function test_VotesMint() public {

//     }
    
//     function setupFraxFallbackHandler(address _safe, address signer, address _handler) public {
//         bytes memory data = abi.encodeWithSignature("setFallbackHandler(address)", address(_handler));
//         DeployedSafe _dsafe = getSafe(_safe).safe;
//         bytes32 txHash = _dsafe.getTransactionHash(
//             address(_dsafe),
//             0,
//             data,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             payable(address(0)),
//             payable(address(0)),
//             _dsafe.nonce()
//         );

//         hoax(signer);
//         _dsafe.execTransaction(
//             address(_dsafe),
//             0,
//             data,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             payable(address(0)),
//             payable(address(0)),
//             generateEoaSigs(4, txHash)
//         );
//     }

//     function setupFraxGuard(address _safe, address signer, address _fraxGuard) public {
//         bytes memory data = abi.encodeWithSignature("setGuard(address)", address(_fraxGuard));
//         DeployedSafe _dsafe = getSafe(_safe).safe;
//         bytes32 txHash = _dsafe.getTransactionHash(
//             address(_dsafe),
//             0,
//             data,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             payable(address(0)),
//             payable(address(0)),
//             _dsafe.nonce()
//         );

//         hoax(signer);
//         _dsafe.execTransaction(
//             address(_dsafe),
//             0,
//             data,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             payable(address(0)),
//             payable(address(0)),
//             generateEoaSigs(4, txHash)
//         );
//     }
//     function addSignerToSafe(address _safe, address signer, address newOwner, uint256 threshold) internal {
//         bytes memory data = abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", newOwner, threshold);
//         bytes memory sig = buildContractPreapprovalSignature(signer);

//         hoax(signer);
//         getSafe(_safe).safe.execTransaction(
//             address(getSafe(_safe).safe),
//             0,
//             data,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             payable(address(0)),
//             payable(address(0)),
//             sig
//         );
//     }

//     function buildContractPreapprovalSignature(address contractOwner) public pure returns (bytes memory) {
//         // GnosisSafe Pre-Validated signature format:
//         // {32-bytes hash validator}{32-bytes ignored}{1-byte signature type}
//         return abi.encodePacked(uint96(0), uint160(contractOwner), uint256(0), uint8(1));
//     }
// }
// // "setup(address[],uint256,address,bytes,address,address,uint256,address)"
// // [0x39424a9c27d44c5d2207C1A9ADE27D42Fb114e1f]
// // 1
// // 0x0000000000000000000000000000000000000000
// // 0x
// // 0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4
// // 0x0000000000000000000000000000000000000000
// // 0
// // 0x0000000000000000000000000000000000000000