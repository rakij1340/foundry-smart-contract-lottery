//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();
        (
            uint64 subscriptionId,
            bytes32 gasLane,
            uint256 automationUpdateInterval,
            uint256 raffleEntranceFee,
            uint32 callbackGasLimit,
            address vrfCoordinatorV2,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            // we are going to need to create a subscription!
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinatorV2,
                deployerKey
            );

            //Fund it!
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinatorV2,
                subscriptionId,
                link,
                deployerKey
            );
        }

        vm.startBroadcast(deployerKey);

        Raffle raffle = new Raffle(
            subscriptionId,
            gasLane,
            automationUpdateInterval,
            raffleEntranceFee,
            callbackGasLimit,
            vrfCoordinatorV2
        );

        vm.stopBroadcast();

        addConsumer.addConsumer(
            address(raffle),
            vrfCoordinatorV2,
            subscriptionId,
            deployerKey
        );

        return (raffle, helperConfig);
    }
}
