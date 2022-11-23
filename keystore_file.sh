#!/bin/bash
#脚本主要用于通过私钥和密码生成对应的keystore文件
#priv_key需要带0x开头
#使用方法：bash keystore_file.sh [w3fs_rpc] [priv_key] [password] [keystore_dir]
if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" ];then
    echo "Usage:bash $0 [RPC地址] [私钥] [账号对应的密码] [存放位置]"
    exit 1
fi
cur_dir=$(pwd)
w3fs_rpc="${1}"
priv_key="${2}"
user_password="${3}"
keystore_dir="${4}"

node ${cur_dir}/js/keystore.js ${w3fs_rpc} ${priv_key} ${user_password} ${keystore_dir}
