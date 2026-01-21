//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NftMarketplace} from "../src/NftMarketplace.sol";

contract DeployNftMarketplace is Script {
    function run() external returns (NftMarketplace) {
        vm.startBroadcast();
        NftMarketplace nftMarketplace = new NftMarketplace();
        vm.stopBroadcast();
        console.log("NftMarketplace deployed at:", address(nftMarketplace));
        return nftMarketplace;
    }
}
