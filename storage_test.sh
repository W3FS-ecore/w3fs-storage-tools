#!/bin/bash
#脚本主要用于检索上传下载功能是否正常
#使用方法：bash storage_test.sh [oriHash] [up_rpc_ip:port] [down_rpc_ip:port] [user_address] [user_priv] [down rpc nodeId] [chain_id]
cur_dir=$(pwd)
cur_time=$(date +%Y%m%d%H%S)
#========================================
#传参判断
if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5" -o -z "$6" -o -z "$7" ];then
    echo "Usage:bash $0 [oriHash] [up rpc ip:port] [down rpc ip:port] [user_address] [user_priv] [down rpc nodeId] [chain id]"
    exit 1
fi
oriHash="$1"
#RPC地址
up_w3fs="$2"
down_w3fs="$3" #可删除
up_w3fs_rpc="http://${up_w3fs}"
# down_w3fs_rpc="http://${down_w3fs}"
up_ip=$(echo "$up_w3fs" |awk -F":" '{print $1}')
# down_ip="$(echo "$down_w3fs" |awk -F":" '{print $1}')"
user_address="$4"
user_priv="$5"
down_nodeId="$6"
chain_id="$7"
# down_minerId="$7"

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
   curl_status_code=$(curl -s --location --keepalive-time 60 --request POST --form "file=@\"${myfile}\"" ${url})
   echo "status_code:$curl_status_code"
   tmp=upload_${1}_${cur_time}
   #echo "code:$curl_status_code  tmp:${tmp}"
   echo $curl_status_code > ${tmp}.log
   eval ${tmp}_file=$(jq .result.file ${tmp}.log)
   rm -f ${tmp}.log
   rm -f ${myfile}
}

#生成随机文件,并上传
fileHash="0x$(head -c 32 /dev/urandom |base64 >>${oriHash}-${cur_time}.txt && sha256sum ${oriHash}-${cur_time}.txt|awk '{print $1}')"

mv ${oriHash}-${cur_time}.txt ${fileHash}
upload ${fileHash}

fileBody="0x$(head -c 32 /dev/urandom |base64 >>${oriHash}-${cur_time}-2.txt && sha256sum ${oriHash}-${cur_time}-2.txt|awk '{print $1}')"
mv ${oriHash}-${cur_time}-2.txt ${fileBody}
upload ${fileBody}

echo "====================="
echo "oriHash:${oriHash}"
echo "user_address:${user_address}"
echo "user_priv:${user_priv}"
echo "down_nodeId:${down_nodeId}"
# echo "down_minerId:${down_minerId}"
echo "fileHash:${fileHash}"
echo "bodyHash:${fileBody}"
# echo "====================="
# node filestoretest.js [w3fs_rpc] [user_address] [oriHash] [nodeId] [fileHash]
# echo "node filestoretest.js ${w3fs_rpc} ${user_address} ${user_priv} ${oriHash} ${nodeId} ${fileHash} ${fileHash2} ${chain_id}"
node_status=$(node ${cur_dir}/js/filestoretest.js ${up_w3fs_rpc} ${user_address} ${user_priv} ${oriHash} ${down_nodeId} ${fileHash} ${fileBody} ${chain_id})

echo "transactionHash：${node_status}"
if [ "${node_status}X" == "X" ];then
    echo "createFileStoreInfo failed"
    exit 1
fi

#公共方法
post_common_send(){
    method_name="$1"
    headFlag="$2"
    fileHash="$3"
    w3fs_rpc="$4"
    minerId="$5"
    # echo "----------------------"
    # echo "method_name:${method_name}"
    # echo "headFlag:${headFlag}"
    # echo "minerId:${minerId}"
    # echo "oriHash:${oriHash}"
    # echo "fileHash:${fileHash}"
    # echo "----------------------"
    if [ ${method_name} == "w3fs_clientSend" ];then
        params="{\"jsonrpc\":\"2.0\",\"method\":\"${method_name}\",\"params\":[{\"oriHash\":\"${oriHash}\",\"minerId\":\"${minerId}\",\"headFlag\":${headFlag},\"file\":\"${fileHash}\"}],\"id\":1}"
    elif [ ${method_name} == "w3fs_getStorageStatus" ];then
        params="{\"jsonrpc\":\"2.0\",\"method\":\"${method_name}\",\"params\":[{\"oriHash\":\"${oriHash}\",\"minerId\":\"${minerId}\",\"headFlag\":${headFlag}}],\"id\":1}"
    elif [ ${method_name} == "w3fs_clientRetrieval" ];then
        params="{\"jsonrpc\":\"2.0\",\"method\":\"${method_name}\",\"params\":[{\"oriHash\":\"${oriHash}\",\"headFlag\":${headFlag}}],\"id\":1}"
    elif [ ${method_name} == "w3fs_getRetrievalStatus" ];then
        params="{\"jsonrpc\":\"2.0\",\"method\":\"${method_name}\",\"params\":[{\"oriHash\":\"${oriHash}\",\"headFlag\":${headFlag}}],\"id\":1}"
    else
        echo "${method_name}方法目前暂不支持！"
    fi
    # echo "curl -H \"Content-Type:application/json\" --keepalive-time 60 -s -X POST --data \"${params}\" ${w3fs_rpc}"
    curl_status_code=$(curl -H "Content-Type:application/json" --keepalive-time 60 -s -X POST --data "${params}" ${w3fs_rpc})
    echo $curl_status_code
    echo $curl_status_code > ${oriHash}_${method_name}_${fileHash}_${headFlag}_${cur_time}.log

    #get_curl ${method_name} ${params} ${w3fs_rpc} ${oriHash}

    eval ${method_name}_${oriHash}_${headFlag}_status=$(jq .result.Status ${oriHash}_${method_name}_${fileHash}_${headFlag}_${cur_time}.log)
    eval ${method_name}_${oriHash}_${headFlag}_message=$(jq .result.Message ${oriHash}_${method_name}_${fileHash}_${headFlag}_${cur_time}.log)
    rm -f ${oriHash}_${method_name}_${fileHash}_${headFlag}_${cur_time}.log
}

echo "============w3fs_clientSend head============"
ec_head_flag=true
post_common_send w3fs_clientSend ${ec_head_flag} ${fileHash} ${up_w3fs_rpc} ${down_nodeId}
ec_head_status=$(eval echo '$'w3fs_clientSend_${oriHash}_${ec_head_flag}_status)
ec_head_message=$(eval echo '$'w3fs_clientSend_${oriHash}_${ec_head_flag}_message)

if [ ! ${ec_head_status} == 200 ];then
    echo "w3fs_clientSend head执行失败,报错信息如下:${ec_head_message}"
    exit 1
fi

echo "等待2s后执行w3fs_clientSend body..."
sleep 3
echo "============w3fs_clientSend body============"
ec_body_flag=false
post_common_send w3fs_clientSend ${ec_body_flag} ${fileBody} ${up_w3fs_rpc} ${down_nodeId}
ec_body_status=$(eval echo '$'w3fs_clientSend_${oriHash}_${ec_body_flag}_status)
ec_body_message=$(eval echo '$'w3fs_clientSend_${oriHash}_${ec_body_flag}_message)
# echo "ec_head_status:$ec_body_status"
# echo "ec_head_message:$ec_body_message"

# exit 1
if [ ! $ec_body_status == 200 ];then
    echo "w3fs_clientSend body执行失败,报错信息如下:${ec_body_message}"
    exit 1
fi

echo "等待3s后查询存储状态..."
sleep 3
echo "============w3fs_getStorageStatus head============"
gs_head_flag=true
post_common_send w3fs_getStorageStatus ${gs_head_flag} ${fileHash} ${up_w3fs_rpc} ${down_nodeId}
gs_head_status=$(eval echo '$'w3fs_getStorageStatus_${oriHash}_${gs_head_flag}_status)
gs_head_message=$(eval echo '$'w3fs_getStorageStatus_${oriHash}_${gs_head_flag}_message)

if [ ! $gs_head_status == 200 ];then
    for((j=1;j<=5;j++))
    do
        sleep 3
        post_common_send w3fs_getStorageStatus ${gs_head_flag} ${fileHash} ${up_w3fs_rpc} ${down_nodeId}
        gs_head_status2=$(eval echo '$'w3fs_getStorageStatus_${oriHash}_${gs_head_flag}_status)
        gs_head_message2=$(eval echo '$'w3fs_getStorageStatus_${oriHash}_${gs_head_flag}_message)
        if [ $gs_head_status2 == 200 ];then
            echo "w3fs_getStorageStatus head重试${j}次"
            break
        fi
    done
    if [ ! $gs_head_status2 == 200 ];then
            echo "w3fs_getStorageStatus head执行失败,报错信息如下:${gs_head_message2}"
            exit 1
    fi   
fi
echo "============w3fs_getStorageStatus body============"
gs_body_flag=false
post_common_send w3fs_getStorageStatus ${gs_body_flag} ${fileBody} ${up_w3fs_rpc} ${down_nodeId}
gs_body_status=$(eval echo '$'w3fs_getStorageStatus_${oriHash}_${gs_body_flag}_status)
gs_body_message=$(eval echo '$'w3fs_getStorageStatus_${oriHash}_${gs_body_flag}_message)

if [ ! $gs_body_status == 200 ];then
    for((j=1;j<=5;j++))
    do
        sleep 3
        post_common_send w3fs_getStorageStatus ${gs_body_flag} ${fileBody} ${up_w3fs_rpc} ${down_nodeId}
        gs_body_status2=$(eval echo '$'w3fs_getStorageStatus_${oriHash}_${gs_body_flag}_status)
        gs_body_message2=$(eval echo '$'w3fs_getStorageStatus_${oriHash}_${gs_body_flag}_message)
        if [ $gs_body_status2 == 200 ];then
            echo "w3fs_getStorageStatus body重试${j}次"
            break
        fi
    done
    if [ ! $gs_body_status2 == 200 ];then
            echo "w3fs_getStorageStatus body执行失败,报错信息如下:${gs_body_message2}"
            exit 1
    fi   
fi

echo "============w3fs_clientRetrieval head============"
cr_head_flag=true
post_common_send w3fs_clientRetrieval ${cr_head_flag} ${fileHash} ${up_w3fs_rpc}
cr_head_status=$(eval echo '$'w3fs_clientRetrieval_${oriHash}_${cr_head_flag}_status)
cr_head_message=$(eval echo '$'w3fs_clientRetrieval_${oriHash}_${cr_head_flag}_message)

if [ ! $cr_head_status == 200 ];then
    echo "w3fs_clientRetrieval head执行失败,报错信息如下:${cr_head_message}"
    exit 1
fi
echo "============w3fs_clientRetrieval body============"
cr_body_flag=false
post_common_send w3fs_clientRetrieval ${cr_body_flag} ${fileBody} ${up_w3fs_rpc}
cr_body_status=$(eval echo '$'w3fs_clientRetrieval_${oriHash}_${cr_body_flag}_status)
cr_body_message=$(eval echo '$'w3fs_clientRetrieval_${oriHash}_${cr_body_flag}_message)

if [ ! $cr_body_status == 200 ];then
    echo "w3fs_clientRetrieval body执行失败,报错信息如下:${cr_body_message}"
    exit 1
fi

echo "等待3s后查询检索状态..."
sleep 3

echo "============w3fs_getRetrievalStatus head============"
rs_head_flag=true
post_common_send w3fs_getRetrievalStatus ${rs_head_flag} ${fileHash} ${up_w3fs_rpc}
rs_head_status=$(eval echo '$'w3fs_getRetrievalStatus_${oriHash}_${rs_head_flag}_status)
rs_head_message=$(eval echo '$'w3fs_getRetrievalStatus_${oriHash}_${rs_head_flag}_message)

if [ $rs_head_status == 500 ];then
    echo "w3fs_getRetrievalStatus head执行失败,报错信息如下:${rs_head_message}"
    exit 1
fi
if [ ! $rs_head_status == 200 ];then
    for((j=1;j<=5;j++))
    do
        sleep 3
        post_common_send w3fs_getRetrievalStatus ${rs_head_flag} ${fileHash} ${up_w3fs_rpc}
        rs_head_status2=$(eval echo '$'w3fs_getRetrievalStatus_${oriHash}_${rs_head_flag}_status)
        rs_head_message2=$(eval echo '$'w3fs_getRetrievalStatus_${oriHash}_${rs_head_flag}_message)
        if [ $rs_head_status2 == 200 ];then
            echo "w3fs_getRetrievalStatus head重试${j}次"
            break
        fi
    done
    if [ ! $rs_head_status2 == 200 ];then
            echo "w3fs_getRetrievalStatus head执行失败,报错信息如下:${rs_head_message2}"
            exit 1
    fi   
fi

echo "============w3fs_getRetrievalStatus body============"
rs_body_flag=false
post_common_send w3fs_getRetrievalStatus ${rs_body_flag} ${fileBody} ${up_w3fs_rpc}
rs_body_status=$(eval echo '$'w3fs_getRetrievalStatus_${oriHash}_${rs_body_flag}_status)
rs_body_message=$(eval echo '$'w3fs_getRetrievalStatus_${oriHash}_${rs_body_flag}_message)

if [ $rs_body_status == 500 ];then
    echo "w3fs_getRetrievalStatus body执行失败,报错信息如下:${rs_body_message}"
    exit 1
fi
if [ ! $rs_body_status == 200 ];then
    for((j=1;j<=5;j++))
    do
        sleep 3
        post_common_send w3fs_getRetrievalStatus ${rs_body_flag} ${fileBody} ${up_w3fs_rpc}
        rs_body_status2=$(eval echo '$'w3fs_getRetrievalStatus_${oriHash}_${rs_body_flag}_status)
        rs_body_message2=$(eval echo '$'w3fs_getRetrievalStatus_${oriHash}_${rs_body_flag}_message)
        if [ $rs_body_status2 == 200 ];then
            echo "w3fs_getRetrievalStatus body重试${j}次"
            break
        fi
    done
    if [ ! $rs_body_status2 == 200 ];then
            echo "w3fs_getRetrievalStatus body执行失败,报错信息如下:${rs_body_message2}"
            exit 1
    fi   
fi

echo "finish!"
