#!/bin/bash
#脚本主要用于通过私钥生成对应的公钥(质押和heimdall创世文件需要用的pubKey的值)
#priv_key需要带0x开头
#使用方法：bash stake_pubkey.sh [priv_key]
if [ -z "$1" ];then
    echo "Usage:bash $0 [私钥]"
    exit 1
fi
cur_dir=$(pwd)
priv_key="${1}"

node ${cur_dir}/js/stake_pubkey.js ${priv_key}