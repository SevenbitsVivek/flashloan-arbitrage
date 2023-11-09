const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { abi } = require("../artifacts/contracts/IERC20.sol/IERC20.json");
const provider = waffle.provider;

describe("FlashloanSpatialArbitrage Contract", () => {
    let FLASHLOANSPATIALARBITRAGE, BORROW_AMOUNT, FUND_AMOUNT, initialFundingHuman, txArbitrage;

    const DECIMALS = 6;
    const USDC_WHALE = "0xa9d1e08c7793af67e9d92fe308d5697fb81d3e43";
    const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const LINK = "0x514910771AF9Ca656af840dff83E8264EcF986CA";

    const usdcInstance = new ethers.Contract(USDC, abi, provider);

    beforeEach(async () => {
        const whaleBalance = await provider.getBalance(USDC_WHALE);

        expect(whaleBalance).not.equal("0");

        const FlashloanSpatialArbitrage = await ethers.getContractFactory("FlashloanSpatialArbitrage");
        FLASHLOANSPATIALARBITRAGE = await FlashloanSpatialArbitrage.deploy();
        await FLASHLOANSPATIALARBITRAGE.deployed();

        const borrowAmountHuman = "1";
        BORROW_AMOUNT = ethers.utils.parseUnits(borrowAmountHuman, DECIMALS);

        initialFundingHuman = "100";
        FUND_AMOUNT = ethers.utils.parseUnits(initialFundingHuman, DECIMALS);

        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [USDC_WHALE],
        });
        const whale = await ethers.getSigner(USDC_WHALE);
        const contractSigner = usdcInstance.connect(whale);

        await contractSigner.transfer(FLASHLOANSPATIALARBITRAGE.address, FUND_AMOUNT, { gasLimit: 5000000 });
    });

    describe("Arbitrage Execution", () => {
        it("ensures the contract is funded", async () => {
            const FlashloanSpatialArbitrage = await FLASHLOANSPATIALARBITRAGE.getContractTokenBalance(USDC);
            const FlashloanSpatialArbitrageHuman = ethers.utils.formatUnits(FlashloanSpatialArbitrage, DECIMALS);

            expect(Number(FlashloanSpatialArbitrageHuman)).equal(Number(initialFundingHuman));
        });

        it("executes the arbitrage", async () => {
            txArbitrage = await FLASHLOANSPATIALARBITRAGE.initiateArbitrage(USDC, BORROW_AMOUNT);

            assert(txArbitrage);

            const usdcContractTokenBalance = await FLASHLOANSPATIALARBITRAGE.getContractTokenBalance(USDC);
            const usdcContractTokenBalanceHuman = ethers.utils.formatUnits(usdcContractTokenBalance, DECIMALS);
            console.log("Balance of USDC: " + usdcContractTokenBalanceHuman);

            const linkContractTokenBalance = await FLASHLOANSPATIALARBITRAGE.getContractTokenBalance(LINK);
            const linkContractTokenBalanceHuman = ethers.utils.formatUnits(linkContractTokenBalance, DECIMALS);
            console.log("Balance of LINK: " + linkContractTokenBalanceHuman);
        })
    })
})