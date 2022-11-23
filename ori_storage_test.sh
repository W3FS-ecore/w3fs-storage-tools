#!/bin/bash
#脚本主要用于非加密整体文件检索上传下载功能是否正常
#使用方法：bash ori_storage_test.sh [oriHash] [up_rpc_ip:port] [user_address] [user_priv] [down rpc nodeId] [chain_id]
cur_dir=$(pwd)
cur_time=$(date +%Y%m%d%H%S)
#========================================
#传参判断
if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5" ];then
    echo "Usage:bash $0 [oriHash] [up rpc ip:port] [user_address] [user_priv] [down rpc nodeId] [chain id]"
    exit 1
fi
#RPC地址
up_w3fs="$1"
up_w3fs_rpc="http://${up_w3fs}"
up_ip=$(echo "$up_w3fs" |awk -F":" '{print $1}')
user_address="$2"
user_priv="$3"
down_nodeId="$4"
chain_id="$5"

# fileSize='1234'
#将生成的文件拷贝到对应的远程服务器上
#上传文件的公共方法
upload(){   
   url=${up_w3fs_rpc}/uploadFile?hash=$1
   myfile=${cur_dir}/$1
   if [ ! -e ${myfile} ]; then
     echo "${myfile} not exist!"
     exit 1
   fi
   curl_status_code=$(curl -s --location --request POST --form "file=@\"${myfile}\"" ${url})
   tmp=upload_${1}_${cur_time}
   #echo "code:$curl_status_code  tmp:${tmp}"
   echo $curl_status_code > ${tmp}.log
   eval ${tmp}_file=$(jq .result.file ${tmp}.log)
   rm -f ${tmp}.log
   rm -f ${myfile}
}

#生成随机文件,并上传
randstr="$(openssl rand -hex 32)"
echo "====>randstr:${randstr}"
fileHashTmp="$(head -c 32 /dev/urandom |base64 >>${randstr}-${cur_time}.txt && sha256sum ${randstr}-${cur_time}.txt|awk '{print $1}')"
fileHash="0x${fileHashTmp}"
oriHashStr="${user_address}${fileHashTmp}"
oriHash=0x`echo -n "${oriHashStr}"|sha256sum|awk '{print $1}'`

mv ${randstr}-${cur_time}.txt ${fileHash}
upload ${fileHash}


echo "====================="
echo "oriHash:${oriHash}"
echo oriHashStr:${oriHashStr}
echo "user_address:${user_address}"
echo "user_priv:${user_priv}"
echo "down_nodeId:${down_nodeId}"
echo "fileHash:${fileHash}"
echo "====================="
# node ori_filestoretest.js [w3fs_rpc] [user_address] [oriHash] [nodeId] [fileHash]
node_status=$(node ${cur_dir}/js/ori_filestoretest.js ${up_w3fs_rpc} ${user_address} ${user_priv} ${oriHash} ${down_nodeId} ${fileHash} ${chain_id})

echo "transactionHash：${node_status}"
if [ "${node_status}X" == "X" ];then
    echo "createFileStoreInfo failed"
    exit 1
fi

#公共方法
post_common_send(){
    method_name="$1"
    fileHash="$2"
    w3fs_rpc="$3"
    minerId="$4"
    # echo "----------------------"
    # echo "method_name:${method_name}"
    # echo "minerId:${minerId}"
    # echo "oriHash:${oriHash}"
    # echo "fileHash:${fileHash}"
    # echo "----------------------"
    if [ ${method_name} == "w3fs_clientSend4Entire" ];then
        params="{\"jsonrpc\":\"2.0\",\"method\":\"${method_name}\",\"params\":[{\"storeKey\":\"${oriHashStr}\",\"minerId\":\"${minerId}\",\"file\":\"${fileHash}\"}],\"id\":1}"
    elif [ ${method_name} == "w3fs_getStorageStatus4Entire" ];then
        params="{\"jsonrpc\":\"2.0\",\"method\":\"${method_name}\",\"params\":[{\"storeKey\":\"${oriHashStr}\",\"minerId\":\"${minerId}\"}],\"id\":1}"
    elif [ ${method_name} == "w3fs_clientRetrieval4Entire" ];then
        params="{\"jsonrpc\":\"2.0\",\"method\":\"${method_name}\",\"params\":[{\"storeKey\":\"${oriHashStr}\"}],\"id\":1}"
    elif [ ${method_name} == "w3fs_getRetrievalStatus4Entire" ];then
        params="{\"jsonrpc\":\"2.0\",\"method\":\"${method_name}\",\"params\":[{\"storeKey\":\"${oriHashStr}\"}],\"id\":1}"
    else
        echo "${method_name}方法目前暂不支持！"
    fi
    # echo "curl -H \"Content-Type:application/json\" -s -X POST --data \"${params}\" ${w3fs_rpc}"
    curl_status_code=$(curl -H "Content-Type:application/json" -s -X POST --data "${params}" ${w3fs_rpc})
    echo $curl_status_code
    echo $curl_status_code > ${oriHash}_${method_name}_${fileHash}_${cur_time}.log

    #get_curl ${method_name} ${params} ${w3fs_rpc} ${oriHash}

    eval ${method_name}_${oriHash}_status=$(jq .result.Status ${oriHash}_${method_name}_${fileHash}_${cur_time}.log)
    eval ${method_name}_${oriHash}_message=$(jq .result.Message ${oriHash}_${method_name}_${fileHash}_${cur_time}.log)
    rm -f ${oriHash}_${method_name}_${fileHash}_${cur_time}.log
}

echo "============w3fs_clientSend4Entire============"
post_common_send w3fs_clientSend4Entire ${fileHash} ${up_w3fs_rpc} ${down_nodeId}
ec_ori_status=$(eval echo '$'w3fs_clientSend4Entire_${oriHash}_status)
ec_ori_message=$(eval echo '$'w3fs_clientSend4Entire_${oriHash}_message)

if [ ! ${ec_ori_status} == 200 ];then
    echo "w3fs_clientSend4Entire执行失败,报错信息如下:${ec_ori_message}"
    exit 1
fi

echo "等待3s后查询存储状态..."
sleep 3
echo "============w3fs_getStorageStatus4Entire============"
post_common_send w3fs_getStorageStatus4Entire ${fileHash} ${up_w3fs_rpc} ${down_nodeId}
gs_ori_status=$(eval echo '$'w3fs_getStorageStatus4Entire_${oriHash}_status)
gs_ori_message=$(eval echo '$'w3fs_getStorageStatus4Entire_${oriHash}_message)

if [ ! $gs_ori_status == 200 ];then
    for((j=1;j<=5;j++))
    do
        sleep 3
        post_common_send w3fs_getStorageStatus4Entire ${fileHash} ${up_w3fs_rpc} ${down_nodeId}
        gs_ori_status2=$(eval echo '$'w3fs_getStorageStatus4Entire_${oriHash}_status)
        gs_ori_message2=$(eval echo '$'w3fs_getStorageStatus4Entire_${oriHash}_message)
        if [ $gs_ori_status2 == 200 ];then
            echo "w3fs_getStorageStatus4Entire重试${j}次"
            break
        fi
    done
    if [ ! $gs_ori_status2 == 200 ];then
            echo "w3fs_getStorageStatus4Entire执行失败,报错信息如下:${gs_ori_message2}"
            exit 1
    fi   
fi

echo "============w3fs_clientRetrieval4Entire============"
post_common_send w3fs_clientRetrieval4Entire ${fileHash} ${up_w3fs_rpc}
cr_ori_status=$(eval echo '$'w3fs_clientRetrieval4Entire_${oriHash}_status)
cr_ori_message=$(eval echo '$'w3fs_clientRetrieval4Entire_${oriHash}_message)

if [ ! $cr_ori_status == 200 ];then
    echo "w3fs_clientRetrieval4Entire执行失败,报错信息如下:${cr_ori_message}"
    exit 1
fi

echo "等待3s后查询检索状态..."
sleep 3
echo "============w3fs_getRetrievalStatus4Entire============"
post_common_send w3fs_getRetrievalStatus4Entire ${fileHash} ${up_w3fs_rpc}
rs_ori_status=$(eval echo '$'w3fs_getRetrievalStatus4Entire_${oriHash}_status)
rs_ori_message=$(eval echo '$'w3fs_getRetrievalStatus4Entire_${oriHash}_message)

if [ $rs_ori_status == 500 ];then
    echo "w3fs_getRetrievalStatus4Entire执行失败,报错信息如下:${rs_ori_message}"
    exit 1
fi
if [ ! $rs_ori_status == 200 ];then
    for((j=1;j<=5;j++))
    do
        sleep 3
        post_common_send w3fs_getRetrievalStatus4Entire ${fileHash} ${up_w3fs_rpc}
        rs_ori_status2=$(eval echo '$'w3fs_getRetrievalStatus4Entire_${oriHash}_status)
        rs_ori_message2=$(eval echo '$'w3fs_getRetrievalStatus4Entire_${oriHash}_message)
        if [ $rs_ori_status2 == 200 ];then
            echo "w3fs_getRetrievalStatus4Entire重试${j}次"
            break
        fi
    done
    if [ ! $rs_ori_status2 == 200 ];then
            echo "w3fs_getRetrievalStatus4Entire执行失败,报错信息如下:${rs_ori_message2}"
            exit 1
    fi   
fi

echo "finish!"
