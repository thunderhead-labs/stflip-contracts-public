// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";
// import "@test/frax-governance/mock/FxsMock.sol";
// import "@governance/src/interfaces/IVeFxs.sol";
// import "test/utils/VyperDeployer.sol";
import {stFlip} from "@src/token/stFlip.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


function deployMockFxs(address multisig, address proxyAdmin) returns (address _address, bytes memory _constructorParams, string memory _contractName) {
    _contractName = "MockFxs";
    string memory _symbol = "FXSM";
    _constructorParams = abi.encode(_contractName, _symbol);
    TransparentUpgradeableProxy stflipProxy = new TransparentUpgradeableProxy(address(new stFlip()), address(proxyAdmin), "");
    stFlip stflip = stFlip(address(stflipProxy));
    stflip.initialize("StakedFlip", "stFLIP", 18, address(multisig), 0, address(0), address(0),address(0));
    _address = address(stflipProxy);
}

// Deploy through remix for testnet deploys. See README.
function deployVeFxs(
    address vyperDeployer,
    address _mockFxs
) returns (address _address, bytes memory _constructorParams, string memory _contractName) {
    _contractName = "veFxs";
    _constructorParams = abi.encode(_mockFxs, _contractName, "1");
    // _address = address(vyperDeployer.deployContract(_contractName, _constructorParams));
}

contract DeployTestFxs is BaseScript {
    function run()
        external
        broadcaster
        returns (address _address, bytes memory _constructorParams, string memory _contractName)
    {
        // (_address, _constructorParams, _contractName) = deployMockFxs();
    }
}
