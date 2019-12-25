const invest2_sETH_StorageProxy = artifacts.require('../contracts/synthetix/Invest2_sETH_StorageProxy');
module.exports = async function(deployer, networks, accounts) {
  deployer.deploy(invest2_sETH_StorageProxy).then(async a => {
    console.log('invest2_sETH_StorageProxy contract is deployed : '+a.address);
    let con = new web3.eth.Contract(a.abi, a.address, { address: a.address });
    const invest2_sETH_StorageProxyAddress = a.address;
    console.log('deployed invest2_sETHStorageProxy with address: '+invest2_sETH_StorageProxyAddress);
    });
};