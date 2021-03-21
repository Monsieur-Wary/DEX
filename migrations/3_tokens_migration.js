const Polygon = artifacts.require("Polygon");
const Wallet = artifacts.require("Wallet");

module.exports = async (deployer, network, accounts) => {
    deployer.deploy(Polygon);

    const wallet = await Wallet.deployed();
    const polygon = await Polygon.deployed();
    const POLYGON_SYMBOL = web3.utils.fromUtf8("MATIC")
    await polygon.approve(wallet.address, 500);
    await wallet.addToken(POLYGON_SYMBOL, polygon.address);
    await wallet.deposit(100, POLYGON_SYMBOL);
    const polygonBalance = (await wallet.balances(accounts[0], POLYGON_SYMBOL)).toNumber();
    console.log(`### Account 0 polygon balance in wallet: ${polygonBalance}`);
};
