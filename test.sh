#!/bin/bash
#Usage:bash test.sh [up_rpc_ip:port] [down_rpc_ip:port] [sentry|validator] [user_address] [user_private]
cur_dir=$(pwd)
cur_time=$(date +%Y%m%d%H%S)
#oriHash:0x1cfe9248de538f60ba64beb56b2f730ff2009083339eb427007916396514817e
orihash="0x$(openssl rand -hex 32)"
up_w3fs="$1"
down_w3fs="$2"
MODE="$3"
user_address="$4"
user_priv="$5"
if [ -z "$1" -o -z "$2" -o -z "$3" ];then
    echo "Usage:bash $0 [up_rpc_ip:port] [down_rpc_ip:port] [sentry or validator] [user_address(非必传)] [user_private(非必传)]"
    exit 1
fi
if [ -z "$4" -o -z "$5" ];then
    #user_address="0x0e27299b195ce2d8d9004ece91da07a93b8499ee"
    user_address="0x211fA1DDbE3d000e1a42921eC56bBE7A923A6BeD"
    user_priv="808bd06647a3673d26f309b6c802790bdcfc5480d0221f2a275ce2bd0220f443"
    #账号：0x211fA1DDbE3d000e1a42921eC56bBE7A923A6BeD
    #私钥：808bd06647a3673d26f309b6c802790bdcfc5480d0221f2a275ce2bd0220f443
fi
echo "user_address:${user_address}"
echo "user_priv:${user_priv}"
#========================
up_ip=$(echo "$up_w3fs" |awk -F":" '{print $1}')
down_ip="$(echo "$down_w3fs" |awk -F":" '{print $1}')"

up_w3fs_rpc="http://${up_w3fs}"
down_w3fs_rpc="http://${down_w3fs}"

# manager_user_addr="0x0e27299b195ce2d8d9004ece91da07a93b8499ee" #转出账号地址或矿工地址
# manager_user_privateKey="0x77f403dc6ab80214d98729681d473b08947eab47b46ae7cfe1321d099dc8d115" #转出账号地址或矿工地址对应的私钥
manager_user_addr="0x9fB29AAc15b9A4B7F17c3385939b007540f4d791" #转出账号地址或矿工地址
manager_user_privateKey="0x9b28f36fbd67381120752d6172ecdcf10e06ab2d9a1367aac00cdcd6ac7855d3" #转出账号地址或矿工地址对应的私钥
chain_id="15678" #W3FS链ID
eth_value="500" #转出金额
#================================================================
#开发环境信息
# tmp_up_ip=`nslookup ${up_ip}  | egrep 'Address:' |  awk '{if(NR==2) print $NF}'`

if [ "${up_ip}" == "192.168.54.20" ];then
    manager_user_addr="0x9fB29AAc15b9A4B7F17c3385939b007540f4d791"
    manager_user_privateKey="0x9b28f36fbd67381120752d6172ecdcf10e06ab2d9a1367aac00cdcd6ac7855d3"
    chain_id="15889"
fi

#example
if [ "${up_ip}" == "192.168.10.204" ];then
    manager_user_addr="0x9fB29AAc15b9A4B7F17c3385939b007540f4d791"
    manager_user_privateKey="0x9b28f36fbd67381120752d6172ecdcf10e06ab2d9a1367aac00cdcd6ac7855d3"
    chain_id="15001"
fi

if [ "${up_w3fs}" == "192.168.10.204:8546" ];then
    manager_user_addr="0xef2634301669df1e852aed96cb1c276203ee52c1"
    manager_user_privateKey="0x78ed683961847f7c25197c4d42379bb0c2017139ae9b552fa9362952c0dd9dc5"
    chain_id="15001"
fi
#=================================================================
#测试环境信息
if [ "${up_ip}" == "192.168.53.42" ];then
    manager_user_addr="0x35C7F64a1649D3191588fB558a93a1f138418836"
    manager_user_privateKey="0x1723b194effcfeb4061579937446cb34bd21137a48d42b6799db6cffce3ecb8e"
    chain_id="15678"
fi

#Wei换算成以太币
user_balance=$(${cur_dir}/bin/w3fs attach ${up_w3fs_rpc} --exec "web3.fromWei(eth.getBalance('${user_address}'),'ether')")

echo "账号${user_address}对应的余额为：${user_balance}"
if [ $(echo "${user_balance} < 10" | bc) -eq 1 ];then
    echo "${user_address}账号的余额不足10，正在充值："

    #调用trans.js脚本进行签名转账操作
    node ${cur_dir}/js/trans.js ${up_w3fs_rpc} ${manager_user_addr} ${manager_user_privateKey} ${user_address} ${chain_id} ${eth_value}
    #直接通过rpc转账
    # ${cur_dir}/bin/w3fs attach ${up_w3fs_rpc} --exec "eth.sendTransaction({from: '${manager_user_addr}', to: '${user_address}', value: web3.toWei(${eth_value}, 'ether')})"

    tmp_balance=`echo "$user_balance + $eth_value"|bc`
    sleep 10
    echo "已为${user_address}账号充值${eth_value},账户当前余额为：${tmp_balance}"
fi


#=================================================================
#生成nodeid
if [ $MODE == "sentry" ];then
    echo "您正在通过哨兵节点获取矿工的nodeID"
    curl -H "Content-Type:application/json" -sX POST --data '{"jsonrpc":"2.0","method":"w3fs_getMiners","params":[{ "minerNum":4, "oriHash":"1"}],"id":1}' ${up_w3fs_rpc} > miner_messages.log
    down_nodeId=$(jq .result[0].minerId miner_messages.log| sed 's/\"//g')
    echo "down_nodeId:$down_nodeId"
    rm -f miner_messages.log
elif [ $MODE == "validator" ];then
    echo "您正在通过验证器节点获取矿工的nodeID"
    down_nodeId_value=$(${cur_dir}/bin/w3fs attach ${down_w3fs_rpc} --exec admin.nodeInfo|grep " id:"|awk -F "\"" '{print $2}')
    down_nodeId="0x${down_nodeId_value}"
else 
    echo "$MODE参数无效，请输入sentry或validator进行传值"
    exit 1
fi

#====================================

#bash storage_test.sh [oriHash] [up_w3fs_ip:port] [down_w3fs_ip:port] [user_address] [user_priv] [down_nodeId] [chain_id]
bash storage_test.sh ${orihash} ${up_w3fs} ${down_w3fs} ${user_address} ${user_priv} ${down_nodeId} ${chain_id}
