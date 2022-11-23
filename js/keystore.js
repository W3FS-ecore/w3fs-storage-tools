//npm install web3
//node keystore.js [w3fs_rpc] [priv_key] [password] [keystore_dir]
const args = process.argv.slice(2);
const eth_rpc=args[0];
const priv_key=args[1];
const password=args[2];
const keystore_dir=args[3];

var Web3 = require('web3');
var fs = require('fs');
var path = require("path");
const { exit } = require('process');
var web3 = new Web3(new Web3.providers.HttpProvider(eth_rpc));
// var priv_key="0x9b28f36fbd67381120752d6172ecdcf10e06ab2d9a1367aac00cdcd6ac7855d3";
// var password="OqnV*12q$";
// var keystore_dir="/root/testnet/data/keystore";

function getKeystoreFile(priv_key,password){
    const ts = new Date();
    const w = web3.eth.accounts.privateKeyToAccount(priv_key);
    return {
        keystore: web3.eth.accounts.encrypt(priv_key, password),
        keystoreFilename: ['UTC--', ts.toJSON().replace(/:/g, '-'), '--', w.address].join('')
    }
}
const keystoreFileObj=getKeystoreFile(priv_key,password);
// save keystore file
fs.writeFile(
     path.join(keystore_dir, keystoreFileObj.keystoreFilename),
     JSON.stringify(keystoreFileObj.keystore, null, 2),(err)=>{
     console.log("keystore file create success");
})
