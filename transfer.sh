#!/bin/bash
#脚本主要用于批量转账使用
#使用方法：bash transfer.sh [w3fs_rpc] [from address]
if [ -z "$1" -o -z "$2" -o -z "$3" ];then
    echo "Usage:bash $0 [RPC地址] [转出账号] [金额]"
    exit 1
fi
cur_dir=$(pwd)
w3fs_rpc="$1"
from_addr="$2"
eth_value="$3"
accounts_list=$(grep -Ev "^$|[#;]" accounts)
for to_addr in ${accounts_list}
do
    ${cur_dir}/bin/w3fs attach ${w3fs_rpc} --exec "eth.sendTransaction({from: '${from_addr}', to: '${to_addr}', value: web3.toWei(${eth_value}, 'ether')})"
done
echo "finish!"

