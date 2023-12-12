// // SPDX-License-Identifier: ISC
// pragma solidity ^0.8.19;

// import { BaseScript } from "frax-std/BaseScript.sol";
// import { console } from "frax-std/FraxTest.sol";
// import { VeFxsVotingDelegation } from "@governance/src/VeFxsVotingDelegation.sol";

// function deployVeFxsVotingDelegation(
//     address _veFxs
// ) returns (address payable _address, bytes memory _constructorParams, string memory _contractName) {
//     string memory version = "1";
//     _constructorParams = abi.encode(_veFxs);
//     _contractName = "VeFxsVotingDelegation";
//     _address = payable(_veFxs);//payable(address(new VeFxsVotingDelegation(_veFxs, _contractName, version)));
// }

// contract DeployVeFxsVotingDelegation is BaseScript {
//     function run()
//         external
//         broadcaster
//         returns (address payable _address, bytes memory _constructorParams, string memory _contractName)
//     {
//     }
// }
