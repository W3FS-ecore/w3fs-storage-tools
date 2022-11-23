const args = process.argv.slice(2);
const private_key=args[0];
var Wallet = require('ethereumjs-wallet');
var EthUtil = require('ethereumjs-util');
const e_toBuffer = EthUtil.toBuffer(private_key);
const e_privateToPublic = EthUtil.privateToPublic(e_toBuffer);
const pubKey = EthUtil.bufferToHex(e_privateToPublic).replace('0x', '0x04');
//const pubKey = EthUtil.bufferToHex(e_privateToPublic);
console.log(pubKey)