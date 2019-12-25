const invest2_sETH = artifacts.require('../contracts/synthetix/Invest2_sETH');

module.exports = async function(deployer, networks, accounts) {
 
  deployer.deploy(invest2_sETH).then(async a => {
    console.log('invest2_sETH contract is deployed : '+a.address);
    let con = new web3.eth.Contract(a.abi, a.address, { address: a.address });
    const invest2_sETHAddress = a.address;
    console.log('deployed invest2_sETH with address: '+invest2_sETHAddress);
    });
};