my_nodered='localhost:1880/isolationgowns'
my_endpoint='http://135.181.35.156:4000/api/explore'

usernameA='stefano+olvg@waag.org'
passwordA='PasswordOLVG1'

locA_name='OLVG'
locA_lat='52.35871773455108'
locA_long='4.916762398221842'
locA_addr='Oosterpark 9, 1091 AC Amsterdam'
locA_note='olvg.nl'


usernameB='stefano+cls@waag.org'
passwordB='PasswordCL1'

locB_name='CleanLease Eindhoven'
locB_lat='51.47240440868687'
locB_long='5.412460440524406'
locB_addr='De schakel 30, 5651 Eindhoven'
locB_note='Textile service provider'

unitlabel='u_piece'
unitsymbol='om2:one'

resource_name="Gown"
resource_id="http://cleanlease.nl/zs/${RANDOM}"

function doLogin {
    username=${1}
    password=${2}
    # echo "{\"username\" : \"${usernameA}\", \"password\" : \"${passwordA}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" \
        -d "{\"username\" : \"${1}\", \"password\" : \"${2}\", \"endpoint\" : \"${my_endpoint}\" }" \
        ${my_nodered}/login 2>/dev/null)
    echo ${result}
}

function createLocation {
    token=${1}
    name=${2}
    lat=${3}
    long=${4}
    addr=${5}
    note=${6}

    # echo "{\"token\" : ${1}, \"name\" : \"${2}\", \"lat\" : ${3}, \"long\" : ${4}, \"addr\" : \"${5}\", \"note\" : \"${6}\", \"endpoint\" : \"${my_endpoint}\" }" \
    result=$(curl -X POST -H "Content-Type: application/json" \
        -d "{\"token\" : ${1}, \"name\" : \"${2}\", \"lat\" : ${3}, \"long\" : ${4}, \"addr\" : \"${5}\", \"note\" : \"${6}\", \"endpoint\" : \"${my_endpoint}\" }" \
        ${my_nodered}/location 2>/dev/null)
    echo ${result}
}

function createUnit {
    token=${1}
    label=${2}
    symbol=${3}

    # echo "{\"token\" : ${1}, \"label\" : \"${2}\", \"symbol\" : \"${3}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" \
        -d "{\"token\" : ${1}, \"label\" : \"${2}\", \"symbol\" : \"${3}\", \"endpoint\" : \"${my_endpoint}\" }" \
        ${my_nodered}/unit 2>/dev/null)
    echo ${result}
}

function createResource {
    token=${1}
    agent_id=${2}
    resource_name=${3}
    resource_id=${4}
    unit_id=${5}
    amount=${6}

    # echo "{\"token\" : ${1}, \"agent_id\" : ${2}, \"resource_id\" : \"${3}\", \"unit_id\" : ${4}, \"amount\" : ${5}, \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" \
        -d "{\"token\" : ${1}, \"agent_id\" : ${2}, \"resource_name\" : \"${3}\", \"resource_id\" : \"${4}\", \"unit_id\" : ${5}, \"amount\" : ${6}, \"endpoint\" : \"${my_endpoint}\" }" \
        ${my_nodered}/resource 2>/dev/null)
    echo ${result}
}

result=$(doLogin ${usernameA} ${passwordA})
# echo "result is: ${result}"
tokenA=$(echo ${result} | jq '.token')
idA=$(echo ${result} | jq '.id')
# echo "tokenA is ${tokenA}, idA is ${idA}" 

result=$(createLocation ${tokenA} "${locA_name}" ${locA_lat} ${locA_long} "${locA_addr}" ${locA_note})
# echo "result is: ${result}"
locationA=$(echo ${result} | jq '.location')
# echo "locationA is ${locationA}" 

result=$(doLogin ${usernameB} ${passwordB})
# echo "result is: ${result}"
tokenB=$(echo ${result} | jq '.token')
idB=$(echo ${result} | jq '.id')
# echo "tokenB is ${tokenB}, idB is ${idB}" 

result=$(createLocation ${tokenB} "${locB_name}" ${locB_lat} ${locB_long} "${locB_addr}" ${locB_note})
# echo "result is: ${result}"
locationB=$(echo ${result} | jq '.location')
# echo "locationB is ${locationB}" 

result=$(createUnit ${tokenA} ${unitlabel} "${unitsymbol}")
# echo "result is: ${result}"
unit=$(echo ${result} | jq '.unit')
# echo "Unit is ${unit}" 

# createResource ${tokenA} "${idA}" ${resource_id} "${unit}" 1
result=$(createResource ${tokenA} "${idA}" "${resource_name}" ${resource_id} "${unit}" 1)
# echo "result is: ${result}"
eventId=$(echo ${result} | jq '.eventId')
resourceIn_id=$(echo ${result} | jq '.resourceIn.id')
resourceOut_id=$(echo ${result} | jq '.resourceOut.id')
echo "resource_id is: ${resource_id}, eventId is ${eventId}, resourceIn_id is ${resourceIn_id}, resourceOut_id is ${resourceOut_id}" 

