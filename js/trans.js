//用途：通过账号和私钥签名的方式进行转账操作示例
//使用方法:
//node trans.js [w3fs_rpc] [minerAccount] [minerminerPrivateKey] [reciptAccount接收账号] [w3fs_chain_id] [amount转账金额]
var Web3 = require('web3');  // 导入web3模块
const args = process.argv.slice(2);
if (args.length < 6) {
    console.log('Bash：node trans.js [w3fs_rpc] [minerAccount] [minerminerPrivateKey] [reciptAccount接收账号] [w3fs_chain_id] [amount转账金额]');
    process.exit(0);
}
const w3fs_rpc=args[0];   //w3fs_rpc
const minerAccount=args[1]; //账号
const minerPrivateKey=args[2]; //账号对应的私钥
const reciptAccount=args[3]; //给账号转
const chain_id=args[4]; //nela链ID
const txValue = args[5]; //要转的金额

web3 = new Web3(new Web3.providers.HttpProvider(w3fs_rpc));

const APP = {
    minerAccount : minerAccount,
    minerPrivateKey : minerPrivateKey,
    reciptAccount : reciptAccount,
    chain_id : chain_id,
    txValue : txValue,
    // //获取指定账户地址的交易数
	nonce : async function(minerAccount){
		return await web3.eth.getTransactionCount(this.minerAccount);
	},
    txParms: async function(minerAccount,reciptAccount,txValue){
        let nonce = await this.nonce(this.minerAccount);
        let amount = await web3.utils.toWei(this.txValue,'ether');
        let gas_price = await web3.eth.getGasPrice();
        return {
            from: this.minerAccount,
            to: this.reciptAccount,
            nonce: web3.utils.toHex(nonce++),
            chainId: this.chain_id,
            gasLimit: web3.utils.toHex('50000'), //gasLimit限制
            //gasPrice: web3.utils.toHex('55000'),
            gasPrice: gas_price,
            data: '', // 当使用代币转账或者合约调用时，0x00
            value: amount // value 是转账金额
            }
    },
    sendsign  : async function () {
        let txObject = await this.txParms(this.minerAccount);
        // 用密钥对账单进行签名
        let signTx = await web3.eth.accounts.signTransaction(txObject,this.minerPrivateKey)
        await web3.eth.sendSignedTransaction(signTx.rawTransaction,(res,error)=>{
            if (!error) {
                console.log(res);
            } else {
                console.log(error);
                return
            }
        })
    }

}

APP.sendsign()