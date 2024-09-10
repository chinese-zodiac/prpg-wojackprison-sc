// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {ILocation} from "../../interfaces/ILocation.sol";
import {Timers} from "../../libs/Timers.sol";

struct MovementPreparation {
    Timers.Timestamp readyTimer;
    ILocation destination;
}
