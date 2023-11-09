const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { abi } = require("../artifacts/contracts/IERC20.sol/IERC20.json");
const provider = waffle.provider;

describe("FlashloanTriangularArbitrage Contract", () => {
    let FLASHLOANTRIANGULARARBITRAGE, BORROW_AMOUNT, FUND_AMOUNT, initialFundingHuman, txArbitrage;

    const DECIMALS = 18;
    const BUSD_WHALE = "0xF977814e90dA44bFA03b6295A0616a897441aceC";
    const BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";

    const busdInstance = new ethers.Contract(BUSD, abi, provider);

    beforeEach(async () => {
        const whaleBalance = await provider.getBalance(BUSD_WHALE);

        expect(whaleBalance).not.equal("0");

        const FlashloanTriangularArbitrage = await ethers.getContractFactory("FlashloanTriangularArbitrage");
        FLASHLOANTRIANGULARARBITRAGE = await FlashloanTriangularArbitrage.deploy();
        await FLASHLOANTRIANGULARARBITRAGE.deployed();

        const borrowAmountHuman = "1";
        BORROW_AMOUNT = ethers.utils.parseUnits(borrowAmountHuman, DECIMALS);

        initialFundingHuman = "100";
        FUND_AMOUNT = ethers.utils.parseUnits(initialFundingHuman, DECIMALS);

        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [BUSD_WHALE],
        });
        const whale = await ethers.getSigner(BUSD_WHALE);
        const contractSigner = busdInstance.connect(whale);
        await contractSigner.transfer(FLASHLOANTRIANGULARARBITRAGE.address, FUND_AMOUNT);
    });

    describe("Arbitrage Execution", () => {
        it("ensures the contract is funded", async () => {
            const flashloanTriangularArbitrage = await FLASHLOANTRIANGULARARBITRAGE.getContractTokenBalance(BUSD);
            const flashloanTriangularArbitrageHuman = ethers.utils.formatUnits(flashloanTriangularArbitrage, DECIMALS);

            expect(Number(flashloanTriangularArbitrageHuman)).equal(Number(initialFundingHuman));
        });

        it("executes the arbitrage", async () => {
            txArbitrage = await FLASHLOANTRIANGULARARBITRAGE.initiateArbitrage(BUSD, BORROW_AMOUNT);

            assert(txArbitrage);

            const busdContractTokenBalance = await FLASHLOANTRIANGULARARBITRAGE.getContractTokenBalance(BUSD);
            const busdContractTokenBalanceHuman = ethers.utils.formatUnits(busdContractTokenBalance, DECIMALS);
            console.log("Balance of BUSD: " + busdContractTokenBalanceHuman);

            const cakeContractTokenBalance = await FLASHLOANTRIANGULARARBITRAGE.getContractTokenBalance(BUSD);
            const cakeContractTokenBalanceHuman = ethers.utils.formatUnits(cakeContractTokenBalance, DECIMALS);
            console.log("Balance of CAKE: " + cakeContractTokenBalanceHuman);

            const croxContractTokenBalance = await FLASHLOANTRIANGULARARBITRAGE.getContractTokenBalance(BUSD);
            const croxContractTokenBalanceHuman = ethers.utils.formatUnits(croxContractTokenBalance, DECIMALS);
            console.log("Balance of CROX: " + croxContractTokenBalanceHuman);
        })
    })
})