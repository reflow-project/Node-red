# In case we will read one day some data from disk, we do not need to do the init, currently not supported
do_init=${1}

my_nodered='localhost:1880/isolationgowns'
# my_nodered='http://zorro.free2air.net:1880/isolationgowns'
my_endpoint='http://135.181.35.156:4000/api/explore'

hospital_username='stefano+olvg@waag.org'
hospital_password='PasswordOLVG1'

lochospital_name='OLVG'
lochospital_lat='52.35871773455108'
lochospital_long='4.916762398221842'
lochospital_addr='Oosterpark 9, 1091 AC Amsterdam'
lochospital_note='olvg.nl'


cleaner_username='stefano+cls@waag.org'
cleaner_password='PasswordCL1'

loccleaner_name='CleanLease Eindhoven'
loccleaner_lat='51.47240440868687'
loccleaner_long='5.412460440524406'
loccleaner_addr='De schakel 30, 5651 Eindhoven'
loccleaner_note='Textile service provider'



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

################################################################################
##### Login the 2 users
################################################################################

result=$(doLogin ${hospital_username} ${hospital_password})
# echo "result is: ${result}"
hospital_token=$(echo ${result} | jq '.token')
hospital_id=$(echo ${result} | jq '.id')
# echo "hospital_token is ${hospital_token}, hospital_id is ${hospital_id}" 


result=$(doLogin ${cleaner_username} ${cleaner_password})
# echo "result is: ${result}"
cleaner_token=$(echo ${result} | jq '.token')
cleaner_id=$(echo ${result} | jq '.id')
# echo "cleaner_token is ${cleaner_token}, cleaner_id is ${cleaner_id}" 

# if [ ! "${do_init} " == " " ]
# then
    ################################################################################
    ##### Create locations and units of measures (currently always done)
    ################################################################################

    result=$(createLocation ${hospital_token} "${lochospital_name}" ${lochospital_lat} ${lochospital_long} "${lochospital_addr}" ${lochospital_note})
    # echo "result is: ${result}"
    locationA=$(echo ${result} | jq '.location')
    # echo "locationA is ${locationA}" 

    result=$(createLocation ${cleaner_token} "${loccleaner_name}" ${loccleaner_lat} ${loccleaner_long} "${loccleaner_addr}" ${loccleaner_note})
    # echo "result is: ${result}"
    locationB=$(echo ${result} | jq '.location')
    # echo "locationB is ${locationB}" 

    result=$(createUnit ${cleaner_token} "u_piece" "om2:one")
    # echo "result is: ${result}"
    piece_unit=$(echo ${result} | jq '.unit')
    # echo "Unit is ${unit}" 

    result=$(createUnit ${cleaner_token} "kg" "om2:kilogram")
    # echo "result is: ${result}"
    mass_unit=$(echo ${result} | jq '.unit')
    # echo "Unit is ${unit}"

    result=$(createUnit ${cleaner_token} "lt" "om2:litre")
    # echo "result is: ${result}"
    volume_unit=$(echo ${result} | jq '.unit')
    # echo "Unit is ${unit}"
    
    result=$(createUnit ${hospital_token} "h" "om2:hour")
    # echo "result is: ${result}"
    time_unit=$(echo ${result} | jq '.unit')
    # echo "Unit is ${unit}"
    
# fi

################################################################################
##### Create Resources (the owner is the cleaner for them all):
##### -gown 
##### -soap to wash the gown
##### -water to wash the gown
################################################################################

gown_trackid="gown-${RANDOM}"
result=$(createResource ${cleaner_token} "${cleaner_id}" "Gown" ${gown_trackid} "${piece_unit}" 1)
# echo "result is: ${result}"
creategown_id=$(echo ${result} | jq '.eventId')
resourceIn_id=$(echo ${result} | jq '.resourceIn.id')
gown_id=$(echo ${result} | jq '.resourceOut.id')
# echo "creategown_id is: ${creategown_id}, gown_trackid is: ${gown_trackid}, gown_id is ${gown_id}" 

soap_trackid="soap-${RANDOM}"
result=$(createResource ${cleaner_token} "${cleaner_id}" "Soap" ${soap_trackid} "${mass_unit}" 100)
# echo "result is: ${result}"
createsoap_id=$(echo ${result} | jq '.eventId')
resourceIn_id=$(echo ${result} | jq '.resourceIn.id')
soap_id=$(echo ${result} | jq '.resourceOut.id')
# echo "createsoap_id is: ${createsoap_id}, soap_trackid is: ${soap_trackid}, soap_id is ${soap_id}" 

water_trackid="water-${RANDOM}"
result=$(createResource ${cleaner_token} "${cleaner_id}" "Water" ${water_trackid} "${volume_unit}" 50)
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
resourceIn_id=$(echo ${result} | jq '.resourceIn.id')
water_id=$(echo ${result} | jq '.resourceOut.id')
# echo "createwater_id is: ${event_id}, water_trackid is: ${water_trackid}, water_id is ${water_id}" 


################################################################################
##### First we transfer the gown from the owner to the hospital
##### The cleaner is still the primary accountable
################################################################################
result=$(transferCustody ${cleaner_token} ${cleaner_id} ${hospital_id} "Gown" ${gown_id} ${piece_unit} 1 ${locationA} "transfer to hospital")
# echo "result is: ${result}"
transfer_id=$(echo ${result} | jq '.transferID')
# echo "transfer_id is: ${transfer_id}" 

################################################################################
##### Perform the process at the hospital
################################################################################
result=$(createProcess ${hospital_token} "Use Gowns" "Use process performed at ${lochospital_name}")
# echo "result is: ${result}"
useprocess_id=$(echo ${result} | jq '.processId')
# echo "useprocess_id is: ${useprocess_id}"

result=$(createEvent "work" ${hospital_token} "perform surgery" ${hospital_id} ${hospital_id} ${time_unit} 80 ${useprocess_id})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

result=$(createEvent "accept" ${hospital_token} "use for surgery" ${cleaner_id} ${hospital_id} ${piece_unit} 1 ${useprocess_id} ${gown_id})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

result=$(createEvent "modify" ${hospital_token} "dirty after use" ${cleaner_id} ${hospital_id} ${piece_unit} 1 ${useprocess_id} ${gown_id})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

################################################################################
##### Transfer back to the owner (the cleaner)
################################################################################

result=$(transferCustody ${hospital_token} ${hospital_id} ${cleaner_id} "Gown" ${gown_id} ${piece_unit} 1 ${locationB} "transfer to cleaner")
# echo "result is: ${result}"
transfer_id=$(echo ${result} | jq '.transferID')
# echo "transfer_id is: ${transfer_id}" 

################################################################################
##### Perform the process at the cleaner
################################################################################
result=$(createProcess ${cleaner_token} "Clean Gowns" "Cleaning process performed at ${loccleaner_name}")
# echo "result is: ${result}"
cleanprocess_id=$(echo ${result} | jq '.processId')
# echo "cleanprocess_id is: ${cleanprocess_id}" 

result=$(createEvent "accept" ${cleaner_token} "to be cleaned" ${cleaner_id} ${cleaner_id} ${piece_unit} 1 ${cleanprocess_id} ${gown_id})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

result=$(createEvent "consume" ${cleaner_token} "water for the washing" ${cleaner_id} ${cleaner_id} ${volume_unit} 25 ${cleanprocess_id} ${water_trackid})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

result=$(createEvent "consume" ${cleaner_token} "soap for the washing" ${cleaner_id} ${cleaner_id} ${mass_unit} 50 ${cleanprocess_id} ${soap_trackid})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 

result=$(createEvent "modify" ${cleaner_token} "clean after washing" ${cleaner_id} ${cleaner_id} ${piece_unit} 1 ${cleanprocess_id} ${gown_id})
# echo "result is: ${result}"
event_id=$(echo ${result} | jq '.eventId')
# echo "clean_id is: ${clean_id}" 
