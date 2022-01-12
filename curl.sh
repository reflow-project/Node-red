do_init=${1}

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



function doLogin {
    body="{\"username\" : \"${1}\", \"password\" : \"${2}\", \"endpoint\" : \"${my_endpoint}\" }"
    # echo "${body}"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/login 2>/dev/null)
    echo ${result}
}

function createLocation {
    body="{\"token\" : ${1}, \"name\" : \"${2}\", \"lat\" : ${3}, \"long\" : ${4}, \"addr\" : \"${5}\", \"note\" : \"${6}\", \"endpoint\" : \"${my_endpoint}\" }"
    # echo "${body}"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/location 2>/dev/null)
    echo ${result}
}

function createUnit {
    body="{\"token\" : ${1}, \"label\" : \"${2}\", \"symbol\" : \"${3}\", \"endpoint\" : \"${my_endpoint}\" }"
    # echo "${body}"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/unit 2>/dev/null)
    echo ${result}
}

function createResource {
    body="{\"token\" : ${1}, \"agent_id\" : ${2}, \"resource_name\" : \"${3}\", \"resource_id\" : \"${4}\", \"unit_id\" : ${5}, \"amount\" : ${6}, \"endpoint\" : \"${my_endpoint}\" }"
    # echo "${body}"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/resource 2>/dev/null)
    echo ${result}
}

function createProcess {
    body="{\"token\" : ${1}, \"process_name\" : \"${2}\", \"process_note\" : \"${3}\", \"endpoint\" : \"${my_endpoint}\" }"
    # echo "${body}"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/process 2>/dev/null)
    echo ${result}
}

function transferCustody {

    body="{\"token\" : ${1}, \"provider_id\" : ${2}, \"receiver_id\" : ${3}, \"name\" : \"${4}\", \"resource_id\" : ${5}, \"unit_id\" : ${6}, \"amount\" : ${7}, \"location_id\" : ${8}, \"note\": \"${9}\", \"endpoint\" : \"${my_endpoint}\" }"
    # echo "${body}"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/transfer 2>/dev/null)
    echo ${result}
}

function createEvent {
    
    action=${1}
    common_body="\"action\" : \"${action}\", \"token\" : ${2},  \"note\": \"${3}\", \"provider_id\" : ${4}, \"receiver_id\" : ${5}, \"unit_id\" : ${6}, \"amount\" : ${7}, \"endpoint\" : \"${my_endpoint}\""
    # echo ${common_body}

    case "${action}" in
        "work")
            body="{ ${common_body}, \"processIn_id\" : ${8}}"
        ;;
        "accept")
            body="{ ${common_body}, \"processIn_id\" : ${8}, \"resource_id\" : ${9}}"
        ;;
        "modify")
            body="{ ${common_body}, \"processOut_id\" : ${8}, \"resource_id\" : ${9}}"
        ;;
        "consume")
            body="{ ${common_body}, \"processIn_id\" : ${8}, \"resource_id\" : \"${9}\"}"
        ;;
        *)
            echo "Please specify a valid action"
        ;;
	esac

    # echo ${body}
    result=$(curl -X POST -H "Content-Type: application/json" \
        -d "${body}" \
        ${my_nodered}/event 2>/dev/null)
    echo ${result}
}


result=$(doLogin ${usernameA} ${passwordA})
# echo "result is: ${result}"
tokenA=$(echo ${result} | jq '.token')
idA=$(echo ${result} | jq '.id')
# echo "tokenA is ${tokenA}, idA is ${idA}" 


result=$(doLogin ${usernameB} ${passwordB})
# echo "result is: ${result}"
tokenB=$(echo ${result} | jq '.token')
idB=$(echo ${result} | jq '.id')
# echo "tokenB is ${tokenB}, idB is ${idB}" 

if [ ! "${do_init} " == " " ]
then
    result=$(createLocation ${tokenA} "${locA_name}" ${locA_lat} ${locA_long} "${locA_addr}" ${locA_note})
    # echo "result is: ${result}"
    locationA=$(echo ${result} | jq '.location')
    # echo "locationA is ${locationA}" 

    result=$(createLocation ${tokenB} "${locB_name}" ${locB_lat} ${locB_long} "${locB_addr}" ${locB_note})
    # echo "result is: ${result}"
    locationB=$(echo ${result} | jq '.location')
    # echo "locationB is ${locationB}" 

    result=$(createUnit ${tokenB} "u_piece" "om2:one")
    # echo "result is: ${result}"
    piece_unit=$(echo ${result} | jq '.unit')
    # echo "Unit is ${unit}" 

    result=$(createUnit ${tokenB} "kg" "om2:kilogram")
    # echo "result is: ${result}"
    mass_unit=$(echo ${result} | jq '.unit')
    # echo "Unit is ${unit}"

    result=$(createUnit ${tokenB} "lt" "om2:litre")
    # echo "result is: ${result}"
    volume_unit=$(echo ${result} | jq '.unit')
    # echo "Unit is ${unit}"
    
    result=$(createUnit ${tokenA} "h" "om2:hour")
    # echo "result is: ${result}"
    time_unit=$(echo ${result} | jq '.unit')
    # echo "Unit is ${unit}"
    
fi

gown_trackid="gown-${RANDOM}"
result=$(createResource ${tokenB} "${idB}" "Gown" ${gown_trackid} "${piece_unit}" 1)
# echo "result is: ${result}"
creategown_id=$(echo ${result} | jq '.eventId')
resourceIn_id=$(echo ${result} | jq '.resourceIn.id')
gown_id=$(echo ${result} | jq '.resourceOut.id')
# echo "creategown_id is: ${creategown_id}, gown_trackid is: ${gown_trackid}, gown_id is ${gown_id}" 

soap_trackid="soap-${RANDOM}"
result=$(createResource ${tokenB} "${idB}" "Soap" ${soap_trackid} "${mass_unit}" 100)
# echo "result is: ${result}"
createsoap_id=$(echo ${result} | jq '.eventId')
resourceIn_id=$(echo ${result} | jq '.resourceIn.id')
soap_id=$(echo ${result} | jq '.resourceOut.id')
# echo "createsoap_id is: ${createsoap_id}, soap_trackid is: ${soap_trackid}, soap_id is ${soap_id}" 

water_trackid="water-${RANDOM}"
result=$(createResource ${tokenB} "${idB}" "Water" ${water_trackid} "${volume_unit}" 50)
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
resourceIn_id=$(echo ${result} | jq '.resourceIn.id')
water_id=$(echo ${result} | jq '.resourceOut.id')
# echo "createwater_id is: ${event_id}, water_trackid is: ${water_trackid}, water_id is ${water_id}" 


################################################################################
##### First we transfer the gown from the owner to the hospital
##### The cleaner is still the primary accountable
################################################################################
result=$(transferCustody ${tokenB} ${idB} ${idA} "Gown" ${gown_id} ${piece_unit} 1 ${locationA} "transfer to hospital")
# echo "result is: ${result}"
transfer_id=$(echo ${result} | jq '.transferID')
# echo "transfer_id is: ${transfer_id}" 

################################################################################
##### Perform the process at the hospital
################################################################################
result=$(createProcess ${tokenA} "Use Gowns" "Use process performed at ${locA_name}")
# echo "result is: ${result}"
useprocess_id=$(echo ${result} | jq '.processId')
# echo "useprocess_id is: ${useprocess_id}"

result=$(createEvent "work" ${tokenA} "perform surgery" ${idA} ${idA} ${time_unit} 80 ${useprocess_id})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

result=$(createEvent "accept" ${tokenA} "use for surgery" ${idB} ${idA} ${piece_unit} 1 ${useprocess_id} ${gown_id})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

result=$(createEvent "modify" ${tokenA} "dirty after use" ${idB} ${idA} ${piece_unit} 1 ${useprocess_id} ${gown_id})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

################################################################################
##### Transfer back to the owner (the cleaner)
################################################################################

result=$(transferCustody ${tokenA} ${idA} ${idB} "Gown" ${gown_id} ${piece_unit} 1 ${locationB} "transfer to cleaner")
# echo "result is: ${result}"
transfer_id=$(echo ${result} | jq '.transferID')
# echo "transfer_id is: ${transfer_id}" 

################################################################################
##### Perform the process at the cleaner
################################################################################
result=$(createProcess ${tokenB} "Clean Gowns" "Cleaning process performed at ${locB_name}")
# echo "result is: ${result}"
cleanprocess_id=$(echo ${result} | jq '.processId')
# echo "cleanprocess_id is: ${cleanprocess_id}" 

result=$(createEvent "accept" ${tokenB} "to be cleaned" ${idB} ${idB} ${piece_unit} 1 ${cleanprocess_id} ${gown_id})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

result=$(createEvent "consume" ${tokenB} "water for the washing" ${idB} ${idB} ${volume_unit} 25 ${cleanprocess_id} ${water_trackid})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

result=$(createEvent "consume" ${tokenB} "soap for the washing" ${idB} ${idB} ${mass_unit} 50 ${cleanprocess_id} ${soap_trackid})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

result=$(createEvent "modify" ${tokenB} "clean after washing" ${idB} ${idB} ${piece_unit} 1 ${cleanprocess_id} ${gown_id})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 
