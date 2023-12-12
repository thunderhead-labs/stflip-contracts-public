// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../src/utils/BurnerV1.sol";
// import "./MainMigration.sol";
// import "forge-std/console.sol";

// contract PrecisionTest is MainMigration {
    
//     address user1 = address(uint160(100));
//     function setUp() public {

//     }


//     function testFuzz_Precision(uint256 sharePrice_, uint256 val1_, uint256 supply1_, uint256 share2_) public {

//         uint256 sharePrice = bound(sharePrice_, 10**17, 10**20);
//         uint256 val1 = bound(val1_, 1, 1_000_000*10**18);
//         uint256 supply1 = bound(supply1_, 1, 1_000_000*10**18);
//         uint256 share2 = bound(supply1_, 0, 1_000_000*10**18);

//         vm.startPrank(owner);
//             stflip.mint(owner, 10**18);
//             stflip.syncSupply(0, sharePrice, 0);


//             stflip.mint(user1, val1);

//             require(stflip.sharesOf(user1) == val1, "failed 1");
        
//             _logInfo(user1);

//             stflip.syncSupply(0,supply1,0);

//             _logInfo(user1);

//             stflip.mint(user1, share2);

//             _logInfo(user1);

//             require(stflip.balanceOf(user1) == share2 + supply1, "failed 1");
//             require(stflip.balanceToShares(stflip.balanceOf(user1)) == stflip.sharesOf(user1), "failed 2");
//             require(stflip.totalSupply() == supply1 + share2, "failed 3");

//     }

//     function _logInfo(address user) internal {
//         console.log("stflip.balanceOf(user):                        ", stflip.balanceOf(user));
//         console.log("stflip.balanceToShares(stflip.balanceOf(user)):", stflip.balanceToShares(stflip.balanceOf(user)));
//         console.log("stflip.sharesOf(user):                         ", stflip.sharesOf(user));

//     }

// }
