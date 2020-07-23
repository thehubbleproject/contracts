const fs = require('fs');
const path = require('path');

const truffleContract = require("@truffle/contract");
const Web3 = require('web3');

var provider = new Web3.providers.HttpProvider("http://localhost:8545");

export async function deployAndUpdate(contractName: string, libs: any) {
    return await new Promise(async (resolve, reject) => {
        var networkId = await web3.eth.net.getId()
        let contractArtifacts = artifacts.require(contractName);
        let links:any = {}

        const filePath = path.resolve(__dirname, '../../build/contracts/', `${contractName}.json`);
        let _libs = Object.keys(libs);
        for (let i = 0; i < _libs.length; i++) {
            const name = _libs[i];
            const address = libs[_libs[i]]
            await contractArtifacts.link(name, address);
            links[name] =address;
        }
        let contractInstance = await contractArtifacts.new();
        console.log(`${contractName}Addr: ${contractInstance.address}`)
        let updatedContractInstance: any = await updateArtifacts(filePath, networkId, contractInstance, links);
        let updatedInstance = await updatedContractInstance.deployed();
        resolve(updatedInstance)
    })
}

async function updateArtifacts(filePath: string, networkId: number, contractInstance: any, links: any) {
    return await new Promise(async (resolve, reject) => {
        let updatedContractInstance: any;
        fs.readFile(filePath, {encoding: 'utf8'}, (err: any,data:any) => {
            var abi = JSON.parse(data);
            abi.networks[networkId] = { 
                events: {},
                links: links,
                address: contractInstance.address,
                transactionHash: contractInstance.transactionHash 
            }
            var string = JSON.stringify(abi, null, '\t');
            fs.writeFile(filePath, string, (err: any) => {
                if(err) return console.error(err);
                updatedContractInstance = truffleContract(abi);
                updatedContractInstance.setProvider(provider);
                resolve(updatedContractInstance)
            })
        })
    })
}