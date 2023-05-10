import {HardhatUserConfig} from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

require('@openzeppelin/hardhat-upgrades');
require("dotenv").config({path: ".env"});

const QUICKNODE_HTTP_URL = process.env.QUICKNODE_HTTP_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY || '';

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.12",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    networks: {
        mumbai: {
            url: QUICKNODE_HTTP_URL,
            accounts: [PRIVATE_KEY],
        },
    },
    paths: {
        sources: './contracts',
        tests: './test',
    }
};

export default config;
