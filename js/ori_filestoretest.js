//使用方法
//node ori_filestoretest.js [w3fs_rpc] [user_address] [user_priv] [oriHash] [nodeId] [fileHash] [chaind_id]
var Web3 = require('web3');  // 导入web3模块
const ethUtils = require('ethereumjs-util')
const contractAddresses = require('../contractAddresses.json')

const FileStoreLogicContract = require('../build/contracts/FileStoreLogic')
const fslogic_abi = FileStoreLogicContract["abi"]

const args = process.argv.slice(2);
const w3fs_rpc=args[0];   //w3fs_rpc
const user_address=args[1]; //账号
const user_priv=args[2]; //账号对应的私钥
const oriHash=args[3]; //oriHash
const nodeId=args[4]; //带0x的
const fileHash=args[5]; //filehash
const chainId=args[6]; //chaind_id
var fileSize = '1234';
var fileExt='txt';//string calldata fileExt

web3 = new Web3(new Web3.providers.HttpProvider(w3fs_rpc));
var getLogicProxyContract = new web3.eth.Contract(fslogic_abi,contractAddresses.fileStoreProxy)

const App = {
    user_address : user_address,
    oriHash : oriHash,
    fileSize : fileSize,
    nodeId : nodeId,
    fileHash : fileHash,
    user_priv : user_priv,
	chainId : chainId,
	fileExt: fileExt,
	nonce : async function(user_address){
		return await web3.eth.getTransactionCount(this.user_address);
	},
	inittxObject: async function(){
		let fileCost = await getLogicProxyContract.methods.getFileCost(this.fileSize).call();
		let nonce = await this.nonce(this.user_address);
		return {
			from: this.user_address,
			value: fileCost,
			// nonce每次++，以免覆盖之前pending中的交易
			nonce: web3.utils.toHex(nonce++),
			gasLimit: web3.utils.toHex("1260000"),//1260000
			gasPrice: web3.utils.toHex("1000000000"),
			to: '0x0000000000000000000000000000000000003002',
			chainId:chainId,
			data: getLogicProxyContract.methods.createFileStoreInfo4Entire(this.oriHash,this.fileSize,this.fileExt,this.nodeId).encodeABI()
		}
	},
	sendsign : async function () {
		let txObject = await this.inittxObject(this.user_address,this.oriHash,this.fileSize,this.nodeId,this.fileHash);
		let tx = await web3.eth.accounts.signTransaction(txObject,this.user_priv)
		web3.eth.sendSignedTransaction(tx.rawTransaction,(res,error)=>{
		if(error){
			console.log(error)
			return
		}else{
			console.log(res)
		}
	})
    }
}

App.sendsign()
