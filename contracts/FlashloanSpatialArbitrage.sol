// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.6;

import "hardhat/console.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FlashloanSpatialArbitrage {
    address private constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private constant SUSHISWAP_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address private constant SUSHISWAP_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    uint256 deadline = block.timestamp + 1 days;

    uint256 MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    function checkProfitability(uint256 _acquiredTokenAmount, uint256 _repayTokenAmount) pure private returns (bool) {
        return (_acquiredTokenAmount > _repayTokenAmount);
    }

    function getContractTokenBalance(address _tokenAdress) external view returns (uint256) {
        return (IERC20(_tokenAdress).balanceOf(address(this)));
    }

    function placeTrade(address _fromToken, address _toToken, uint256 _amountIn, address factory, address router) private returns (uint256) {
        address pair = IUniswapV2Factory(factory).getPair(_fromToken, _toToken);
        require(pair != address(0), "Pool does not exists");

        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router02(router).getAmountsOut(_amountIn, path)[1];
        uint256 amountReceived = IUniswapV2Router02(router).swapExactTokensForTokens(_amountIn, amountRequired, path, address(this), deadline)[1];

        require(amountReceived > 0, "Transaction Abort");
        return amountReceived;
    }

    function initiateArbitrage(address _tokenBorrow, uint256 _amount) external {
        IERC20(WETH).approve(address(UNISWAP_ROUTER), MAX_INT);
        IERC20(USDC).approve(address(UNISWAP_ROUTER), MAX_INT);
        IERC20(LINK).approve(address(UNISWAP_ROUTER), MAX_INT);

        IERC20(WETH).approve(address(SUSHISWAP_ROUTER), MAX_INT);
        IERC20(USDC).approve(address(SUSHISWAP_ROUTER), MAX_INT);
        IERC20(LINK).approve(address(SUSHISWAP_ROUTER), MAX_INT);

        address pair = IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenBorrow, WETH);
        require(pair != address(0), "Pool does not exists");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;

        bytes memory data = abi.encode(_tokenBorrow, _amount, msg.sender);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        address pair = IUniswapV2Factory(UNISWAP_FACTORY).getPair(token0, token1);
        require(pair == msg.sender, "The sender needs to match the pair");
        require(_sender == address(this), "The sender should match the contract");

        (address _tokenBorrow, uint256 _amount, address _myAddress) = abi.decode(_data, (address, uint256, address));

        uint256 fees = ((_amount * 3) / 997) + 1;
        uint256 repayAmount = _amount + fees;
        uint256 loanAmount = _amount0 > 0 ? _amount0 : _amount1;

        uint256 tradeToken1 = placeTrade(USDC, LINK, loanAmount, UNISWAP_FACTORY, UNISWAP_ROUTER);
        uint256 tradeToken2 = placeTrade(LINK, USDC, tradeToken1, SUSHISWAP_FACTORY, SUSHISWAP_ROUTER);

        console.log("loanAmount ===>", loanAmount);
        console.log("tradeToken1 ===>", tradeToken1);
        console.log("tradeToken2 ===>", tradeToken2);

        bool isArbitrageProfitable = checkProfitability(tradeToken2, repayAmount);
        require(isArbitrageProfitable, "Arbitrage is not profitable");

        IERC20(_tokenBorrow).transfer(_myAddress, tradeToken2 - repayAmount);
        IERC20(_tokenBorrow).transfer(pair, repayAmount);
    }
}