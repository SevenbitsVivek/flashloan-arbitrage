// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.6;

import "hardhat/console.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FlashloanTriangularArbitrage {
    address private constant PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant BEP20Ethereum = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant CROX = 0x2c094F5A7D1146BB93850f629501eB749f6Ed491;

    uint256 deadline = block.timestamp + 1 days;

    uint256 MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    function checkProfitability(uint256 _acquiredTokenAmount, uint256 _repayTokenAmount) pure private returns (bool) {
        return (_acquiredTokenAmount > _repayTokenAmount);
    }

    function getContractTokenBalance(address _tokenAdress) external view returns (uint256) {
        return (IERC20(_tokenAdress).balanceOf(address(this)));
    }

    function placeTrade(address _fromToken, address _toToken, uint256 _amountIn) private returns (uint256) {
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(_fromToken, _toToken);
        require(pair != address(0), "Pool does not exists");

        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router02(PANCAKE_ROUTER).getAmountsOut(_amountIn, path)[1];
        uint256 amountReceived = IUniswapV2Router02(PANCAKE_ROUTER).swapExactTokensForTokens(_amountIn, amountRequired, path, address(this), deadline)[1];

        require(amountReceived > 0, "Transaction Abort");
        return amountReceived;
    }

    function initiateArbitrage(address _busdBorrow, uint256 _amount) external {
        IERC20(BUSD).approve(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(CAKE).approve(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(CROX).approve(address(PANCAKE_ROUTER), MAX_INT);

        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(_busdBorrow, BEP20Ethereum);
        require(pair != address(0), "Pool does not exists");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint256 amount0Out = _busdBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _busdBorrow == token1 ? _amount : 0;

        bytes memory data = abi.encode(_busdBorrow, _amount, msg.sender);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function pancakeCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(token0, token1);
        require(pair == msg.sender, "The sender needs to match the pair");
        require(_sender == address(this), "The sender should match the contract");

        (address _busdBorrow, uint256 _amount, address _myAddress) = abi.decode(_data, (address, uint256, address));

        uint256 fees = ((_amount * 3) / 997) + 1;
        uint256 repayAmount = _amount + fees;
        uint256 loanAmount = _amount0 > 0 ? _amount0 : _amount1;

        uint256 tradeToken1 = placeTrade(BUSD, CAKE, loanAmount);
        uint256 tradeToken2 = placeTrade(CAKE, CROX, tradeToken1);
        uint256 tradeToken3 = placeTrade(CROX, BUSD, tradeToken2);

        console.log("loanAmount ===>", loanAmount);
        console.log("tradeToken1 ===>", tradeToken1);
        console.log("tradeToken2 ===>", tradeToken2);
        console.log("tradeToken3 ===>", tradeToken3);

        bool isArbitrageProfitable = checkProfitability(tradeToken3, repayAmount);
        require(isArbitrageProfitable, "Arbitrage is not profitable");

        IERC20(_busdBorrow).transfer(_myAddress, tradeToken3 - repayAmount);
        IERC20(_busdBorrow).transfer(pair, repayAmount);
    }
}