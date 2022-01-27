# In case we will read one day some data from disk, we do not need to do the init, currently not supported
if [ "${1} " = "Y " ]
then
    do_init="true"
fi

if [ "${2} " = "Y " ]
then
    do_debug="true"
fi

init_file='init.json'
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
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/event 2>/dev/null)
    echo ${result}
}

function traceTrack {

    body="{\"resource_id\" : ${1}, \"recursion\" : ${2}, \"endpoint\" : \"${my_endpoint}\" }"
    # echo "${body}"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/tracetrack 2>/dev/null)
    echo ${result}
}

################################################################################
##### Login the 2 users
################################################################################

result=$(doLogin ${hospital_username} ${hospital_password})
hospital_token=$(echo ${result} | jq '.token')
hospital_id=$(echo ${result} | jq '.id')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "hospital_token is ${hospital_token}, hospital_id is ${hospital_id}" 
fi



result=$(doLogin ${cleaner_username} ${cleaner_password})
cleaner_token=$(echo ${result} | jq '.token')
cleaner_id=$(echo ${result} | jq '.id')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "cleaner_token is ${cleaner_token}, cleaner_id is ${cleaner_id}" 
fi



if [ "${do_init} " == "true " ] || [ ! -f "${init_file}" ]
then
    echo "Creating units"
    ################################################################################
    ##### Create locations and units of measures
    ################################################################################

    result=$(createLocation ${hospital_token} "${lochospital_name}" ${lochospital_lat} ${lochospital_long} "${lochospital_addr}" ${lochospital_note})
    locationA=$(echo ${result} | jq '.location')
    if [ "${do_debug} " == "true " ]
    then
        echo "result is: ${result}"
        echo "locationA is ${locationA}" 
    fi

    result=$(createLocation ${cleaner_token} "${loccleaner_name}" ${loccleaner_lat} ${loccleaner_long} "${loccleaner_addr}" ${loccleaner_note})
    locationB=$(echo ${result} | jq '.location')
    if [ "${do_debug} " == "true " ]
    then
        echo "result is: ${result}"
        echo "locationB is ${locationB}"
    fi
    
    result=$(createUnit ${cleaner_token} "u_piece" "om2:one")
    piece_unit=$(echo ${result} | jq '.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "result is: ${result}"
        echo "Piece unit is ${piece_unit}" 
    fi

    result=$(createUnit ${cleaner_token} "kg" "om2:kilogram")
    mass_unit=$(echo ${result} | jq '.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "result is: ${result}"
        echo "Mass unit is ${mass_unit}" 
    fi

    result=$(createUnit ${cleaner_token} "lt" "om2:litre")
    volume_unit=$(echo ${result} | jq '.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "result is: ${result}"
        echo "Volume unit is ${volume_unit}" 
    fi
    
    result=$(createUnit ${hospital_token} "h" "om2:hour")
    time_unit=$(echo ${result} | jq '.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "result is: ${result}"
        echo "Time unit is ${time_unit}" 
    fi
    jq -n "{locationA: ${locationA},  locationB: ${locationB}, piece_unit: ${piece_unit}, mass_unit: ${mass_unit}, volume_unit: ${volume_unit}, time_unit: ${time_unit}}" > ${init_file}
else
    echo "Reading units from file ${init_file}"
    locationA=$(cat ${init_file} | jq '.locationA')
    locationB=$(cat ${init_file} | jq '.locationB')
    piece_unit=$(cat ${init_file} | jq '.piece_unit')
    mass_unit=$(cat ${init_file} | jq '.mass_unit')
    volume_unit=$(cat ${init_file} | jq '.volume_unit')
    time_unit=$(cat ${init_file} | jq '.time_unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "locationA: ${locationA},  locationB is ${locationB}, piece_unit: ${piece_unit}, mass_unit: ${mass_unit}, volume_unit: ${volume_unit}, time_unit: ${time_unit}"
    fi
fi

################################################################################
##### Create Resources (the owner is the cleaner for them all):
##### -gown 
##### -soap to wash the gown
##### -water to wash the gown
################################################################################

gown_trackid="gown-${RANDOM}"
result=$(createResource ${cleaner_token} "${cleaner_id}" "Gown" ${gown_trackid} "${piece_unit}" 1)
creategown_id=$(echo ${result} | jq '.eventId')
resourceIn_id=$(echo ${result} | jq '.resourceIn.id')
gown_id=$(echo ${result} | jq '.resourceOut.id')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "creategown_id is: ${creategown_id}, gown_trackid is: ${gown_trackid}, gown_id is ${gown_id}" 
fi



soap_trackid="soap-${RANDOM}"
result=$(createResource ${cleaner_token} "${cleaner_id}" "Soap" ${soap_trackid} "${mass_unit}" 100)
createsoap_id=$(echo ${result} | jq '.eventId')
resourceIn_id=$(echo ${result} | jq '.resourceIn.id')
soap_id=$(echo ${result} | jq '.resourceOut.id')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "createsoap_id is: ${createsoap_id}, soap_trackid is: ${soap_trackid}, soap_id is ${soap_id}" 
fi

water_trackid="water-${RANDOM}"
result=$(createResource ${cleaner_token} "${cleaner_id}" "Water" ${water_trackid} "${volume_unit}" 50)
event_id=$(echo ${result} | jq '.eventId')
resourceIn_id=$(echo ${result} | jq '.resourceIn.id')
water_id=$(echo ${result} | jq '.resourceOut.id')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "createwater_id is: ${event_id}, water_trackid is: ${water_trackid}, water_id is ${water_id}" 
fi


################################################################################
##### First we transfer the gown from the owner to the hospital
##### The cleaner is still the primary accountable
################################################################################
transfer_note='Transfer gowns to hospital'
result=$(transferCustody ${cleaner_token} ${cleaner_id} ${hospital_id} "Gown" ${gown_id} ${piece_unit} 1 ${locationA} "${transfer_note}")
event_id=$(echo ${result} | jq '.transferID')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "${transfer_note}: event id is ${event_id}"
fi

################################################################################
##### Perform the process at the hospital
################################################################################
process_name='Process Use Gowns'
result=$(createProcess ${hospital_token} "${process_name}" "Use process performed at ${lochospital_name}")
useprocess_id=$(echo ${result} | jq '.processId')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "${process_name}: useprocess id is ${useprocess_id}"
fi

event_note='work perform surgery'
result=$(createEvent "work" ${hospital_token} "${event_note}" ${hospital_id} ${hospital_id} ${time_unit} 80 ${useprocess_id})
event_id=$(echo ${result} | jq '.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "${event_note}: event id is ${event_id}"
fi


event_note='accept use for surgery'
result=$(createEvent "accept" ${hospital_token} "${event_note}" ${cleaner_id} ${hospital_id} ${piece_unit} 1 ${useprocess_id} ${gown_id})
event_id=$(echo ${result} | jq '.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "${event_note}: event id is ${event_id}"
fi


event_note='modify dirty after use'
result=$(createEvent "modify" ${hospital_token} "${event_note}" ${cleaner_id} ${hospital_id} ${piece_unit} 1 ${useprocess_id} ${gown_id})
event_id=$(echo ${result} | jq '.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "${event_note}: event id is ${event_id}"
fi


################################################################################
##### Transfer back to the owner (the cleaner)
################################################################################
transfer_note='Transfer gowns to cleaner'
result=$(transferCustody ${hospital_token} ${hospital_id} ${cleaner_id} "Gown" ${gown_id} ${piece_unit} 1 ${locationB} "${transfer_note}")
event_id=$(echo ${result} | jq '.transferID')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "${transfer_note}: event id is ${event_id}"
fi


################################################################################
##### Perform the process at the cleaner
################################################################################
process_name='Process Clean Gowns'
result=$(createProcess ${cleaner_token} "${process_name}" "Cleaning process performed at ${loccleaner_name}")
cleanprocess_id=$(echo ${result} | jq '.processId')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "${process_name}: cleanprocess id is ${cleanprocess_id}"
fi


event_note='accept gowns to be cleaned'
result=$(createEvent "accept" ${cleaner_token} "${event_note}" ${cleaner_id} ${cleaner_id} ${piece_unit} 1 ${cleanprocess_id} ${gown_id})
event_id=$(echo ${result} | jq '.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "${event_note}: event id is ${event_id}"
fi


event_note='consume water for the washing'
result=$(createEvent "consume" ${cleaner_token} "${event_note}" ${cleaner_id} ${cleaner_id} ${volume_unit} 25 ${cleanprocess_id} ${water_trackid})
event_id=$(echo ${result} | jq '.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "${event_note}: event id is ${event_id}"
fi


event_note='consume soap for the washing'
result=$(createEvent "consume" ${cleaner_token} "${event_note}" ${cleaner_id} ${cleaner_id} ${mass_unit} 50 ${cleanprocess_id} ${soap_trackid})
event_id=$(echo ${result} | jq '.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "${event_note}: event id is ${event_id}"
fi


event_note='modify clean after washing'
result=$(createEvent "modify" ${cleaner_token} "${event_note}" ${cleaner_id} ${cleaner_id} ${piece_unit} 1 ${cleanprocess_id} ${gown_id})
event_id=$(echo ${result} | jq '.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
    echo "${event_note}: event id is ${event_id}"
fi


echo "gown id is: ${gown_id}"

result=$(traceTrack ${gown_id} 10)
echo ${result} | jq '.'
if [ "${do_debug} " == "true " ]
then
    echo "result is: ${result}"
fi
