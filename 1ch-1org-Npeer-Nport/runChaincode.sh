#!/bin/bash
CHANNEL_NAME="$1"
: ${CHANNEL_NAME:="mychannel0"}
DELAY="$2"
: ${DELAY:="3"}
MAX_RETRY="$3"
: ${MAX_RETRY:="10"}
VERBOSE="$4"
: ${VERBOSE:="false"}
CHAINCODE_NAME="$5"
: ${CHAINCODE_NAME:="STO"}
CHAINCODE_VERSION="$6"
: ${CHAINCODE_VERSION:="v1"}
CHAINCODE_SEQUENCE="$7"
: ${CHAINCODE_SEQUENCE:="1"}
CHAINCODE_END_POLICY="$8"
: ${CHAINCODE_END_POLICY:=""}
CHAINCODE_COLL_CONFIG="$9"
: ${CHAINCODE_COLL_CONFIG:=""}
ORG_NUM="1"
: ${ORG_NUM:="1"}

LOG_LEVEL=info
export CALIPER_SCRIPT=${PWD}
export CALIPER_HOME=${CALIPER_SCRIPT%/*}
export CALIPER_BENCHMARKS=$CALIPER_HOME/benchmarks

############ Set core.yaml ############
export TEST_NETWORK_HOME=$(dirname $(readlink -f $0))

echo "chaincode invoke"
export PEERPATH="${TEST_NETWORK_HOME}"
export LOG_DIR="${TEST_NETWORK_HOME}/log"

export BIN_DIR="${TEST_NETWORK_HOME}/bin"
# ${BIN_DIR}/peer chaincode list --installed

## query example
# CC_ARGS="{\"selector\":{\"Name\":\"0\"}}"

param=""
func=""
string=""

function changePeer() {
    peer=$1

    if [ "${peer}" = "peer0" ]; then
        export PORT=7051
    elif [ "${peer}" = "peer1" ]; then
        export PORT=6051
    elif [ "${peer}" = "peer2" ]; then
        export PORT=5051
    elif [ "${peer}" = "peer3" ]; then
        export PORT=4051
    elif [ "${peer}" = "peer4" ]; then
        export PORT=3051
    elif [ "${peer}" = "peer5" ]; then
        export PORT=2051
    fi

    export FABRIC_CFG_PATH=${TEST_NETWORK_HOME}/config
    export HOST="${peer}.org1.example.com"
    export ORG="Org1"

    ############ Peer Vasic Setting ############
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ID="${peer}.org1.example.com"
    export CORE_PEER_ENDORSER_ENABLED=true
    export CORE_PEER_ADDRESS="${peer}.org1.example.com:${PORT}"
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/peers/${peer}.org1.example.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    export ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
}

function IsInit() {
    echo set flag $@
    flag $@

    # set query
    echo ${FUNCNAME[0]}

    param="{\"Args\":[\"${FUNCNAME[0]}\"]}"
    echo $param

    # set
    set -x

    # set env
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param --isInit >&${LOG_DIR}/IsInit.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/IsInit.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    PEER_CONN_PARMS=""
}

function Invoke() {
    echo Invoke chaincode
    # set flag
    echo set flag $@
    flag $@

    # set query
    param="{\"Args\":[\"${func}\"]}"
    echo $param

    # set
    set -x

    # set env
    echo "invoke peer connection parameters:${PEER_CONN_PARMS[@]}"
    ${BIN_DIR}/peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} ${PEER_CONN_PARMS[@]} -c $param >&${LOG_DIR}/Invoke-${ORG}-${CHANNEL_NAME}-${CHAINCODE_NAME}-${func}.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Invoke-${ORG}-${CHANNEL_NAME}-${CHAINCODE_NAME}-${func}.log
    echo "Invoke transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    PEER_CONN_PARMS=""
    func=""
    string=""
    param=""
}

function Query() {
    echo Query chaincode
    # set flag
    echo set flag $@
    flag $@

    # set query
    param="{\"Args\":[\"${func}\",\"{$string}\"]}"
    echo $param

    # set
    set -x

    # set env
    echo "query peer connection parameters:"
    ${BIN_DIR}/peer chaincode query -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA" -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} --peerAddresses ${CORE_PEER_ADDRESS} --tlsRootCertFiles ${CORE_PEER_TLS_ROOTCERT_FILE} -c $param >&${LOG_DIR}/Query-${ORG}-${CHANNEL_NAME}-${CHAINCODE_NAME}-${func}.log

    { set +x; } 2>/dev/null
    cat ${LOG_DIR}/Query-${ORG}-${CHANNEL_NAME}-${CHAINCODE_NAME}-${func}.log
    echo "Query transaction successful on peer0 on channel '${CHANNEL_NAME}'"

    PEER_CONN_PARMS=""
    func=""
    string=""
    param=""
}

function flag() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        --cc)
            export CHAINCODE_NAME="$2"
            shift 2
            ;;
        --ch)
            export CHANNEL_NAME="$2"
            shift 2
            ;;
        --func)
            func=$2
            shift 2
            ;;
        --caller)
            string+="\\\"_caller\\\":\\\"$2\\\","
            shift 2
            ;;
        --tokenHolder)
            string+="\\\"_tokenHolder\\\":\\\"$2\\\","
            shift 2
            ;;
        --partition)
            if [ "$2" == "-" ]; then
                string+="\\\"_partition\\\":\\\"\\\","
            else
                string+="\\\"_partition\\\":\\\"$2\\\","
            fi
            shift 2
            ;;
        --value)
            string+="\\\"_value\\\":\\\"$2\\\","
            shift 2
            ;;
        --data)
            string+="\\\"_data\\\":\\\"$2\\\","
            shift 2
            ;;
        --from)
            string+="\\\"_from\\\":\\\"$2\\\","
            shift 2
            ;;
        --to)
            string+="\\\"_to\\\":\\\"$2\\\","
            shift 2
            ;;
        --operator)
            string+="\\\"_operator\\\":\\\"$2\\\","
            shift 2
            ;;
        --tokenWalletId)
            string+="\\\"tokenWalletId\\\":\\\"$2\\\","
            shift 2
            ;;
        --role)
            string+="\\\"role\\\":\\\"$2\\\","
            shift 2
            ;;
        --accountNumber)
            string+="\\\"accountNumber\\\":\\\"$2\\\","
            shift 2
            ;;
        --channelNm)
            string+="\\\"channelNm\\\":\\\"$2\\\","
            shift 2
            ;;
        --tokenId)
            string+="\\\"tokenId\\\":\\\"$2\\\","
            shift 2
            ;;
        --publicOfferingAmount)
            string+="\\\"publicOfferingAmount\\\":\\\"$2\\\","
            shift 2
            ;;
        --recipients)
            string+="\\\"recipients\\\":{\\\"Kyle1\\\":\\\"5000\\\"},"
            shift 2
            ;;
        --spender)
            string+="\\\"_spender\\\":\\\"$2\\\","
            shift 2
            ;;
        --key)
            string+="\\\"key\\\":\\\"$2\\\","
            shift 2
            ;;
        --p)
            changePeer $2
            export PEER_CONN_PARMS="${PEER_CONN_PARMS} --peerAddresses ${CORE_PEER_ADDRESS}"
            TLSINFO=$(eval echo "--tlsRootCertFiles \$CORE_PEER_TLS_ROOTCERT_FILE")
            export PEER_CONN_PARMS="${PEER_CONN_PARMS} ${TLSINFO}"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
        esac
    done
    string=${string%\,}
}

function main() {
    # IsInit --cc Dev --ch mychannel-a --p org2 --p org1

    # Invoke --func InitAdmin --cc validatorinfo --ch mdl --p org2 --p org1
    Invoke --func EmitEvent1 --cc Dev --ch mychannel0 --p peer4

    #  --p peer1
    # --p peer2

    # Query --func GetData --cc Dev --ch mychannel0 --key a --p peer3

    # Invoke --func AddValidator --cc validatorinfo --ch mdl --p org2 --p org1
}

main
