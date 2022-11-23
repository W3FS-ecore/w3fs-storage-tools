# w3fs-storage-tools

主要存放验证存储上传下载及常用的工具使用。

本文档demo默认W3FS链ID为15678，如有改动，请自行修改脚本。

```
#脚本说明：
storage_test.sh   #存储上传下载验证脚本
test.sh           #存储上传下载模拟入口，主要用于模拟storage_test.sh操作
ori_storage_test.sh #分体存储上传下载验证脚本
ori_test.sh         #分体存储上传下载模拟入口，主要用于模拟ori_storage_test.sh操作
keystore_file.sh  #根据带0x私钥和密码生成UTC文件工具
stake_pubkey.sh   #根据带0x私钥生成公钥工具
transfer.sh		  #批量转账工具

#其他目录说明
bin     #存放脚本需要用到的命令，需要自行替换最新的w3fs命令
build   #存放编译合约后的json文件，如有修改存储合约，需要重新覆盖
js      #存放脚本需要用到的js文件

#其他文件说明
trans     #将sha256sum的十六进制转成十进制工具
accounts  #存放所有要转账的账号信息
```

## 使用前准备工作

```
1、使用脚本所在机器需要提前安装好node、npm、jq命令
2、安装相关依赖包
npm install --registry https://registry.npm.taobao.org

3、将genesis-contracts创世合约部署后的build目录拷贝覆盖到当前build目录
```

## 存储上传下载验证

### 存储多个上传下载验证：

使用说明：

```
bash test.sh [up_rpc_ip:port] [down_rpc_ip:port] [user_address] [user_private]

up_rpc_ip:是上传文件对应的IP地址
down_rpc_ip:是要检索文件对应的IP地址
user_address:要操作的用户，如果没传，默认账号：0x211fA1DDbE3d000e1a42921eC56bBE7A923A6BeD
user_private:操作用户对应私钥，如果没传，默认账号私钥：808bd06647a3673d26f309b6c802790bdcfc5480d0221f2a275ce2bd0220f443

```

存储单个示例：

> bash test.sh 192.168.80.132:8545 192.168.80.132:8545



存储多个示例：

>bash test.sh 192.168.80.132:8545 192.168.80.132:8545



整体文件存储示例参考：

> bash test.sh 192.168.80.132:8545 192.168.80.132:8545

```
user_address:0x211fA1DDbE3d000e1a42921eC56bBE7A923A6BeD
user_priv:808bd06647a3673d26f309b6c802790bdcfc5480d0221f2a275ce2bd0220f443
账号0x211fA1DDbE3d000e1a42921eC56bBE7A923A6BeD对应的余额为：999.999041767
down_nodeId:0x0ffeb2e287089058b7b7e93284c8107cef04b3ac693e826233aa0c2b802a42a2
status_code:{"file":"0xd6ea978f9da59a473785ea87a35d76bc5f0414ee2f76c660d212f99052cfa2b0"}
status_code:{"file":"0xa7071f606c3807a5560b38e5a12a91a0737e9397645acca2415ab0045794d0d0"}
=====================
oriHash:0x5b668f97882d7e7be441388654ea4ee726e5c68467aab6887445806e08b9b907
user_address:0x211fA1DDbE3d000e1a42921eC56bBE7A923A6BeD
user_priv:808bd06647a3673d26f309b6c802790bdcfc5480d0221f2a275ce2bd0220f443
down_nodeId:0x0ffeb2e287089058b7b7e93284c8107cef04b3ac693e826233aa0c2b802a42a2
fileHash:0xd6ea978f9da59a473785ea87a35d76bc5f0414ee2f76c660d212f99052cfa2b0
bodyHash:0xa7071f606c3807a5560b38e5a12a91a0737e9397645acca2415ab0045794d0d0
transactionHash：0xec15bd3061bbbab7eea8fb6806f22274cfb229b4c0978ddf333933b1c3a0f80f
============eth_clientSend head============
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"bafkqaljyhayvi6dyivkfgwd2ifsxm4jrfmvugmdzgrgu652qgbevmrdej55e2tcjkrdxok3ngvet2cq","Timestamp":"2022-05-30T09:28:46.997010329Z"}}
等待2s后执行eth_clientSend body...
============eth_clientSend body============
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"bafkqaljxme2u4mcigbddkrrwmzzeu5ddmrbw6mkwkm3dcv2go5egcockpi2ewk22f5ego43jlfit2cq","Timestamp":"2022-05-30T09:28:50.118123539Z"}}
等待3s后查询存储状态...
============eth_getStorageStatus head============
{"jsonrpc":"2.0","id":1,"result":{"Status":100,"Message":"deal being processed","Timestamp":"2022-05-30T09:28:53.214779489Z"}}
{"jsonrpc":"2.0","id":1,"result":{"Status":100,"Message":"deal being processed","Timestamp":"2022-05-30T09:28:56.308082055Z"}}
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"success","Timestamp":"2022-05-30T09:28:59.516681203Z"}}
eth_getStorageStatus head重试2次
============eth_getStorageStatus body============
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"success","Timestamp":"2022-05-30T09:28:59.606514797Z"}}
============eth_clientRetrieval head============
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"{\"FileExt\":\"txt\",\"FileSize\":1234}","Timestamp":"2022-05-30T09:28:59.699883024Z"}}
============eth_clientRetrieval body============
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"{\"FileExt\":\"txt\",\"FileSize\":1234}","Timestamp":"2022-05-30T09:28:59.83288734Z"}}
等待3s后查询检索状态...
============eth_getRetrievalStatus head============
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"","Timestamp":"2022-05-30T09:29:03.015083892Z"}}
============eth_getRetrievalStatus body============
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"","Timestamp":"2022-05-30T09:29:03.096567643Z"}}
finish!
```

分体文件存储示例参考：

> bash ori_test.sh 192.168.80.132:8545 192.168.80.132:8545

```
user_address:0x211fA1DDbE3d000e1a42921eC56bBE7A923A6BeD
user_priv:808bd06647a3673d26f309b6c802790bdcfc5480d0221f2a275ce2bd0220f443
账号0x211fA1DDbE3d000e1a42921eC56bBE7A923A6BeD对应的余额为：499.993202407
down_nodeId:0xb129d671e54299b20152005309610360bd88aae2e44f78fb7c3302fb36f5e437
====>randstr:94d6f2b12aa54228bde3ab28bbf1b533e9505308006e1a5a129d49920d2d0b08
=====================
oriHash:0xfe6b2b0bb2dd40163925f5b002e6a5043c4fa83b9ff5a9af7df428f5afc427d8
oriHashStr:0x211fA1DDbE3d000e1a42921eC56bBE7A923A6BeD53eafb273d3ea0beaf4c8e7036345cbd78c8d35be7b86282a00edc5713ad96a9
user_address:0x211fA1DDbE3d000e1a42921eC56bBE7A923A6BeD
user_priv:808bd06647a3673d26f309b6c802790bdcfc5480d0221f2a275ce2bd0220f443
down_nodeId:0xb129d671e54299b20152005309610360bd88aae2e44f78fb7c3302fb36f5e437
fileHash:0x53eafb273d3ea0beaf4c8e7036345cbd78c8d35be7b86282a00edc5713ad96a9
=====================
transactionHash：0xf2d2e98c9fc1623715e823068c42bd89194f81fa80a9626c5182be8cc3db9f66
============w3fs_clientSend4Entire============
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"bafkqallfjqxvoyszhbrdk52ygnxew4lqnnvfasdjkvmvuq3nkjdgkrjsirjgwwtsnnvei3rzgzxt2cq","Timestamp":"2022-11-18T02:37:28.00367801Z"}}
等待3s后查询存储状态...
============w3fs_getStorageStatus4Entire============
{"jsonrpc":"2.0","id":1,"result":{"Status":100,"Message":"deal being processed","Timestamp":"2022-11-18T02:37:31.214625554Z"}}
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"success","Timestamp":"2022-11-18T02:37:34.436337154Z"}}
w3fs_getStorageStatus4Entire重试1次
============w3fs_clientRetrieval4Entire============
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"{\"FileExt\":\"txt\",\"FileSize\":1234}","Timestamp":"2022-11-18T02:37:34.646298583Z"}}
等待3s后查询检索状态...
============w3fs_getRetrievalStatus4Entire============
{"jsonrpc":"2.0","id":1,"result":{"Status":200,"Message":"","Timestamp":"2022-11-18T02:37:37.858903631Z"}}
finish!
```



## 其他工具使用参考

### 1、UTC文件生成

> bash keystore_file.sh

```
Usage:bash keystore_file.sh [RPC地址] [私钥] [账号对应的密码] [存放位置]
```

示例参考：

>bash keystore_file.sh http://192.168.53.37:8545 0x77f403dc6ab80214d98729681d473b08947eab47b46ae7cfe1321d099dc8d115 'OqnV*12q$' .

```
keystore file create success

[root@localhost shell]# ll UTC*
-rw-r--r-- 1 root root 603 4月  14 03:46 UTC--2022-04-13T19-46-03.324Z--0x0e27299B195cE2d8D9004eCE91da07a93B8499EE
```

### 2、质押公钥生成

> bash stake_pubkey.sh

```
Usage:bash stake_pubkey.sh [私钥]
```

示例参考：

> bash stake_pubkey.sh 0x77f403dc6ab80214d98729681d473b08947eab47b46ae7cfe1321d099dc8d115

```
0x04f12d55c3385a51a8620614e3cb448e17ac922d81caf224e6e372d62b3e54165d4f01380ad495d6c8c8685db169fbdf98530f3148fea709ea5742b55af9a80373
```

### 3、批量转账

需要提前将账号整理到accounts文件中

> bash transfer.sh

```
Usage:bash transfer.sh [RPC地址] [转出账号] [金额]
```

示例参考：

> bash transfer.sh http://192.168.53.37:8545 f37df4D1Ab164B706656A34d8dfe7849e1075700 100

```
"0x3271682cffa433c5e099d3abfd0a9690a27db3a2cdd8499e6eeee0376bb91acd"
"0xe6a147e1d15daf9122b4eb994299cf97ead27016480b5db9fb49bde30af5b442"
"0x49cb2261b53e45fbafde58ea81158da964914336d5ca14225ff51e7328728af7"
"0x76879a118ed32a5a000e40e4655cdc818b93bf7836f4ba975817169dad83b3c2"
"0xb0c0ad419285bcdc64a346d20908f4e696905955ea018ac51e876f4caffcac79"
"0x137c8c87ac9bbffbbb91bc0e5b9c094ec28e49050975842dd35685a5270cfa0b"
"0xb1b51f659c5a07c0a551908dd4eaac9fe941861575010a1ce8a2815c10dc3773"
"0x816e97cda3f2058a69b805289cfaff4e9e27c458968e6d332efeca6567ca3fa9"
"0xadfea183ef1202ca9e7cc971d7eea801971e0282cef7249f51949e8c76179a36"
"0xbbf571b9e9ccc21856a727fc2a872cce5634612f95d37cb21970301d95914dcb"
"0x7f50ea9243cb1608820720cbf381acb1837c0094926595c25150ebd52465dd09"
"0x98c30d2c529d7f9e8adc1e84d8a877f7d44a07054d7f950989a4314502a5105e"
"0x8316923c2d5066c8af153aaa1fd86fbad143578485cdc7158c4c4e1e5679ba80"
"0xb2b34963a43037c93d1ea59f294185a4b4fe43edd46b951b8a4019f32a62f3d0"
"0x7899f067117241fbe0bbe8fac10c9bd15275501a120619c535521324552a5895"
finish!
```



