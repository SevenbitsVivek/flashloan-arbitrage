This is a project all about flashloan-arbitrage in which two types of arbitrage which is as follows:- 
1. Spatial Arbitrage
2. Triangular Arbitrage

Steps to run this project is as follows:- 
1. npm install
2. npx hardhat test(To run all the test files)
3. npx hardhat test FOLDER_NAME/FILE_NAME(To run specific test file)

Flashloan:-

1. Flashloan is a most important concepts in blockchain.
2. Flashloan is a concept in which user will borrow the loan and repay the loan in the same blockchain transaction without giving any collateral assets.
3. In flashloan user can borrow then do some arbitrage to earn some profits and will repay the borrow amount in the same transaction.

Arbitrage:- 

1. Arbitrage is the concept in the blockchain where traders will buy assets with low prices from one market and will sell the same assests with high prices in another market.
2. The difference between selling price - buying price the traders earns called as the arbitrage 
3. In flashloan-arbitrage user will not have to face loss during arbitrage because if the arbitrage is not successfull then it will revert the transaction.
4. There are various types of arbitrage such as:- 

    a. Spatial Arbitrage:- In this type of arbitrage traders will buy and sell assests between two different markets to earn some profits out of it.

    b. Triangular Arbitrage:- In this type of arbitrage traders will buy and sell 3 assets to form  a triangle and earn some profits out of it.

    c. Statistical Arbitrage:- In this type of arbitrage traders will buy and sell assets based on the statistics of the assets like past, present and future performance of the assets.

    d. Temporal Arbitrage:- In this type of arbitrage traders will buy and sell the assets based on the time like traders will buy the assets and will sell the assets after some specific period of time.

In this project I am using ethereum and bsc mainnet account addresses by using hardhat's impersonate accounts concepts where we can use mainnet's account to do any operation to our smart contract right from deploying smart contract to transfer any tokens, ethers to some destination addresses but on a temporary basis. 
In actual it will not do any realtime operation on mainnet but it will fork the mainnet blockchain state for testing purposes.
