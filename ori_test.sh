#!/bin/bash


#Usage:bash ori_test.sh [up_rpc_ip:port] [down_rpc_ip:port] [user_address] [user_private]
cur_dir=$(pwd)
cur_time=$(date +%Y%m%d%H%S)
up_w3fs="$1"
down_w3fs="$2"
user_address="$3"
user_priv="$4"
if [ -z "$1" -o -z "$2" ];then
    echo "Usage:bash $0 [up_rpc_ip:port] [down_rpc_ip:port] [user_address] [user_private]"
    exit 1
fi
if [ -z "$3" -o -z "$4" ];then
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

#转出账号
#manager_user_addr="0x0e27299b195ce2d8d9004ece91da07a93b8499ee"
manager_user_addr="0x9fB29AAc15b9A4B7F17c3385939b007540f4d791"
chain_id="15678"
#转出金额
eth_value="500"
#================================================================
#开发环境信息
if [ "${up_ip}" == "192.168.54.20" ];then
    manager_user_addr="0x9fB29AAc15b9A4B7F17c3385939b007540f4d791"
     chain_id="15889"
fi

#example
if [ "${up_ip}" == "192.168.10.204" ];then
    manager_user_addr="0x9fB29AAc15b9A4B7F17c3385939b007540f4d791"
    chain_id="15001"
fi

if [ "${up_w3fs}" == "192.168.10.204:8546" ];then
    manager_user_addr="0xef2634301669df1e852aed96cb1c276203ee52c1"
    chain_id="15001"
fi

#=================================================================
#测试环境信息
if [ "${up_ip}" == "192.168.53.42" ];then
    manager_user_addr="0x35C7F64a1649D3191588fB558a93a1f138418836"
     chain_id="15678"
fi

#Wei换算成以太币
user_balance=$(${cur_dir}/bin/w3fs attach ${up_w3fs_rpc} --exec "web3.fromWei(eth.getBalance('${user_address}'),'ether')")

echo "账号${user_address}对应的余额为：${user_balance}"
if [ $(echo "${user_balance} < 10" | bc) -eq 1 ];then
    echo "${user_address}账号的余额不足10，正在充值："
    ${cur_dir}/bin/w3fs attach ${up_w3fs_rpc} --exec "eth.sendTransaction({from: '${manager_user_addr}', to: '${user_address}', value: web3.toWei(${eth_value}, 'ether')})"
    tmp_balance=`echo "$user_balance + $eth_value"|bc`
    sleep 10
    echo "已为${user_address}账号充值${eth_value},账户当前余额为：${tmp_balance}"
fi

#=================================================================
#需要修改
#生成nodeid
down_nodeId_value=$(${cur_dir}/bin/w3fs attach ${down_w3fs_rpc} --exec admin.nodeInfo|grep " id:"|awk -F "\"" '{print $2}')
down_nodeId="0x${down_nodeId_value}"
echo "down_nodeId:$down_nodeId"
# down_minerId=$(./trans ${down_nodeId_value})
#====================================

bash ori_storage_test.sh  ${up_w3fs} ${user_address} ${user_priv} ${down_nodeId} ${chain_id}

