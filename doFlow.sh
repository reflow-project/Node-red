. ./.credentials.sh
if [ "${hospital_username} " == " " ] || [ "${hospital_password} " == " "  ] || [ "${cleaner_username} " == " " ] || [ "${cleaner_password} " == " " ]
then
    echo "credentials not set"
    echo "==${hospital_username}==${hospital_password}==${cleaner_username}==${cleaner_password}=="
    exit -1
fi

# read the endpoint
case "${1}" in
        "latest")
            my_endpoint='https://reflow-void.zenr.io/api/explore'
        ;;
        *)
            echo "Please specify a valid back-end"
            exit -1
        ;;
esac

# perform init or read units from disk
if [ "${2} " = "Y " ]
then
    do_init="true"
fi

if [ "${3} " = "Y " ]
then
    do_debug="true"
fi

my_nodered='localhost:1880/isolationgowns'
# my_nodered='http://zorro.free2air.net:1880/isolationgowns'
# my_endpoint='http://135.181.35.156:4000/api/explore'
# my_endpoint='http://reflow-demo.dyne.org:4000/api/explore'

machine=$(echo "${my_endpoint}" | sed 's/http[s]*:\/\/\(.*\)[:0-9]*\/api\/explore/\1/g')
init_file="init_${machine}.json"

lochospital_name='OLVG'
lochospital_lat='52.35871773455108'
lochospital_long='4.916762398221842'
lochospital_addr='Oosterpark 9, 1091 AC Amsterdam'
lochospital_note='olvg.nl'

loccleaner_name='CleanLease Eindhoven'
loccleaner_lat='51.47240440868687'
loccleaner_long='5.412460440524406'
loccleaner_addr='De schakel 30, 5651 Eindhoven'
loccleaner_note='Textile service provider'

body=""

function doLogin {
    body="{\"username\" : \"${1}\", \"password\" : \"${2}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/login 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createLocation {
    body="{\"token\" : \"${1}\", \"name\" : \"${2}\", \"lat\" : \"${3}\", \"long\" : \"${4}\", \"addr\" : \"${5}\", \"note\" : \"${6}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/location 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createUnit {
    body="{\"token\" : \"${1}\", \"label\" : \"${2}\", \"symbol\" : \"${3}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/unit 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createProcess {
    body="{\"token\" : \"${1}\", \"process_name\" : \"${2}\", \"process_note\" : \"${3}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/process 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function transferCustody {

    body="{\"token\" : \"${1}\", \"provider_id\" : \"${2}\", \"receiver_id\" : \"${3}\", \"resource_id\" : \"${4}\", \"unit_id\" : \"${5}\", \"amount\" : ${6}, \"location_id\" : \"${7}\", \"note\": \"${8}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/transfer 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createResourceSpec {

    body="{\"token\" : \"${1}\", \"unit_id\" : \"${2}\", \"name\" : \"${3}\", \"note\" : \"${4}\", \"classification\" : \"${5}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/resourcespec 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createResource {
    body="{\"token\" : \"${1}\", \"agent_id\" : \"${2}\", \"resource_name\" : \"${3}\", \"resource_id\" : \"${4}\", \"unit_id\" : \"${5}\", \"amount\" : ${6}, \"classification\": \"${7}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/resource 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createEvent {
    
    action=${1}
    common_body="\"action\" : \"${action}\", \"token\" : \"${2}\",  \"note\": \"${3}\", \"provider_id\" : \"${4}\", \"receiver_id\" : \"${5}\", \"unit_id\" : \"${6}\", \"amount\" : ${7}, \"endpoint\" : \"${my_endpoint}\""

    case "${action}" in
        "work")
            body="{ ${common_body}, \"processIn_id\" : \"${8}\", \"classification\": \"${9}\"}"
        ;;
        "accept")
            body="{ ${common_body}, \"processIn_id\" : \"${8}\", \"resource_id\" : \"${9}\"}"
        ;;
        "modify")
            body="{ ${common_body}, \"processOut_id\" : \"${8}\", \"resource_id\" : \"${9}\"}"
        ;;
        "consume")
            body="{ ${common_body}, \"processIn_id\" : \"${8}\", \"resource_id\" : \"${9}\"}"
        ;;
        "produce")
            body="{ ${common_body}, \"processOut_id\" : \"${8}\", \"resourcetrack_id\" : \"${9}\", \"resource_name\" : \"${10}\", \"classification\": \"${11}\"}"
        ;;
        *)
            echo "Please specify a valid action"
        ;;
	esac

    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/event 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function traceTrack {

    body="{\"resource_id\" : \"${1}\", \"recursion\" : ${2}, \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/tracetrack 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

################################################################################
##### Login the 2 users
################################################################################

result=$(doLogin ${hospital_username} ${hospital_password})
hospital_token=$(echo ${result} | jq -r '.result.token')
hospital_id=$(echo ${result} | jq -r '.result.id')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
    echo "DEBUG: $(date) -  hospital_token is ${hospital_token}" 
fi

if [ "${hospital_token} " == " " ]
then
    echo "Login failed for ${hospital_username}"
    exit -1
fi
echo "$(date) - Logged user hospital in, id: ${hospital_id}"

result=$(doLogin ${cleaner_username} ${cleaner_password})
cleaner_token=$(echo ${result} | jq -r '.result.token')
cleaner_id=$(echo ${result} | jq -r '.result.id')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
    echo "DEBUG: $(date) -  cleaner_token is ${cleaner_token}" 
fi
if [ "${cleaner_token} " == " " ]
then
    echo "Login failed for ${cleaner_username}"
    exit -1
fi
echo "$(date) - Logged user cleaner in, id: ${cleaner_id}"

if [ "${do_init} " == "true " ] || [ ! -f "${init_file}" ]
then
    echo "$(date) - Creating units"
    ################################################################################
    ##### Create locations and units of measures
    ################################################################################

    result=$(createLocation ${hospital_token} "${lochospital_name}" ${lochospital_lat} ${lochospital_long} "${lochospital_addr}" ${lochospital_note})
    lochospital_id=$(echo ${result} | jq -r '.result.location')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - lochospital_id is ${lochospital_id}" 
    fi
    echo "$(date) - Created location for ${lochospital_name}, id: ${lochospital_id}"

    
    result=$(createLocation ${cleaner_token} "${loccleaner_name}" ${loccleaner_lat} ${loccleaner_long} "${loccleaner_addr}" ${loccleaner_note})
    loccleaner_id=$(echo ${result} | jq -r '.location')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - loccleaner_id is ${loccleaner_id}"
    fi
    echo "$(date) - Created location for ${loccleaner_name}, id: ${loccleaner_id}"

    result=$(createUnit ${cleaner_token} "u_piece" "om2:one")
    piece_unit=$(echo ${result} | jq -r '.result.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - Piece unit is ${piece_unit}" 
    fi
    echo "$(date) - Created unit for gowns, id: ${piece_unit}"

    result=$(createUnit ${cleaner_token} "kg" "om2:kilogram")
    mass_unit=$(echo ${result} | jq -r '.result.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - Mass unit is ${mass_unit}" 
    fi
    echo "$(date) - Created unit for mass (kg), id: ${mass_unit}"

    result=$(createUnit ${cleaner_token} "lt" "om2:litre")
    volume_unit=$(echo ${result} | jq -r '.result.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - Volume unit is ${volume_unit}"
    fi
    echo "$(date) - Created unit for volume (litre), id: ${volume_unit}"
    
    result=$(createUnit ${hospital_token} "h" "om2:hour")
    time_unit=$(echo ${result} | jq -r '.result.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - Time unit is ${time_unit}" 
    fi
    echo "$(date) - Create unit for time (hour), id: ${time_unit}"

    # Save units to file
    jq -n "{lochospital_id: ${lochospital_id},  loccleaner_id: ${loccleaner_id}, piece_unit: ${piece_unit}, mass_unit: ${mass_unit}, volume_unit: ${volume_unit}, time_unit: ${time_unit}}" > ${init_file}
else
    echo "$(date) - Reading units from file ${init_file}"
    lochospital_id=$(cat ${init_file} | jq -r '.lochospital_id')
    loccleaner_id=$(cat ${init_file} | jq -r '.loccleaner_id')
    piece_unit=$(cat ${init_file} | jq -r '.piece_unit')
    mass_unit=$(cat ${init_file} | jq -r '.mass_unit')
    volume_unit=$(cat ${init_file} | jq -r '.volume_unit')
    time_unit=$(cat ${init_file} | jq -r '.time_unit')
    # if [ "${do_debug} " == "true " ]
    # then
    #     echo "$(date) - lochospital_id: ${lochospital_id},  loccleaner_id is ${loccleaner_id}, piece_unit: ${piece_unit}, mass_unit: ${mass_unit}, volume_unit: ${volume_unit}, time_unit: ${time_unit}"
    # fi
    echo "$(date) - Read location for ${lochospital_name}, id: ${lochospital_id}"
    echo "$(date) - Read location for ${loccleaner_name}, id: ${loccleaner_id}"
    echo "$(date) - Read unit for gowns, id: ${piece_unit}"
    echo "$(date) - Read unit for mass (kg), id: ${mass_unit}"
    echo "$(date) - Read unit for volume (litre), id: ${volume_unit}"
    echo "$(date) - Read unit for time (hour), id: ${time_unit}"

fi

################################################################################
##### Create Resources (the owner is the cleaner for them all):
##### -gown (https://www.wikidata.org/wiki/Q89990310)
##### -soap to wash the gown (https://www.wikidata.org/wiki/Q34396)
##### -water to wash the gown (https://www.wikidata.org/wiki/Q283)
##### -cotton to sew the gown (https://www.wikidata.org/wiki/Q11457)
################################################################################
note='Specification for soap to be used to wash the gowns'
result=$(createResourceSpec ${cleaner_token} "${mass_unit}" "Soap" "${note}" "https://www.wikidata.org/wiki/Q34396")
soap_spec_id=$(echo ${result} | jq -r '.result.specId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created ${note} with spec id: ${soap_spec_id}"

soap_trackid="soap-${RANDOM}"
result=$(createResource ${cleaner_token} "${cleaner_id}" "Soap" ${soap_trackid} "${mass_unit}" 100 ${soap_spec_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
soap_id=$(echo ${result} | jq -r '.result.resourceId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created 100 kg soap with tracking id: ${soap_trackid}, id: ${soap_id} owned by the cleaner, event id: ${event_id}"

note='Specification for water to be used to wash the gowns'
result=$(createResourceSpec ${cleaner_token} "${volume_unit}" "Water" "${note}" "https://www.wikidata.org/wiki/Q283")
water_spec_id=$(echo ${result} | jq -r '.result.specId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created ${note} with spec id: ${water_spec_id}"

water_trackid="water-${RANDOM}"
result=$(createResource ${cleaner_token} "${cleaner_id}" "Water" ${water_trackid} "${volume_unit}" 50 ${water_spec_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
water_id=$(echo ${result} | jq -r '.result.resourceId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created 50 liters water with tracking id: ${water_trackid}, id: ${water_id} owned by the cleaner, event id: ${event_id}"

note='Specification for cotton to be used to sew the gowns'
result=$(createResourceSpec ${cleaner_token} "${mass_unit}" "Cotton" "${note}" "https://www.wikidata.org/wiki/Q11457")
cotton_spec_id=$(echo ${result} | jq -r '.result.specId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created ${note} with spec id: ${cotton_spec_id}"

cotton_trackid="cotton-${RANDOM}"
result=$(createResource ${cleaner_token} "${cleaner_id}" "Cotton" ${cotton_trackid} "${mass_unit}" 20 ${cotton_spec_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
cotton_id=$(echo ${result} | jq -r '.result.resourceId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created 20 kg cotton with tracking id: ${cotton_trackid}, id: ${cotton_id} owned by the cleaner, event id: ${event_id}"

note='Specification for gowns'
result=$(createResourceSpec ${cleaner_token} "${piece_unit}" "Gown" "${note}" "https://www.wikidata.org/wiki/Q89990310")
gown_spec_id=$(echo ${result} | jq -r '.result.specId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created ${note} with spec id: ${gown_spec_id}"

note='Specification for surgical operation'
result=$(createResourceSpec ${hospital_token} "${time_unit}" "Surgical operation" "${note}" "https://www.wikidata.org/wiki/Q600236")
surgery_spec_id=$(echo ${result} | jq -r '.result.specId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created ${note} with spec id: ${surgery_spec_id}"

################################################################################
##### First we create the gown from the cotton
################################################################################
process_name='Process sew gown'
result=$(createProcess ${cleaner_token} "${process_name}" "Sew gown process performed by ${loccleaner_name}")
sewgownprocess_id=$(echo ${result} | jq -r '.result.processId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created process: ${process_name}, process id: ${sewgownprocess_id}"

event_note='consume cotton for sewing'
result=$(createEvent "consume" ${cleaner_token} "${event_note}" ${cleaner_id} ${cleaner_id} ${mass_unit} 10 ${sewgownprocess_id} ${cotton_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action consume 10 kg cotton as input for process: ${sewgownprocess_id}"

event_note='produce gown'
gown_trackid="gown-${RANDOM}"
result=$(createEvent "produce" ${cleaner_token} "${event_note}" ${cleaner_id} ${cleaner_id} ${piece_unit} 1 ${sewgownprocess_id} ${gown_trackid} "Gown" ${gown_spec_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
gown_id=$(echo ${result} | jq -r '.result.resourceId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action produce 1 gown with tracking id: ${gown_trackid}, id: ${gown_id} owned by the cleaner as output of process: ${sewgownprocess_id}"

# result=$(createResource ${cleaner_token} "${cleaner_id}" "Gown" ${gown_trackid} "${piece_unit}" 1)
# event_id=$(echo ${result} | jq -r '.result.eventId')
# resourceIn_id=$(echo ${result} | jq -r '.result.resourceIn.id')
# gown_id=$(echo ${result} | jq -r '.result.resourceOut.id')
# if [ "${do_debug} " == "true " ]
# then
#     echo "DEBUG: $(date) -  result is: ${result}"
# fi
# echo "$(date) - Created 1 gown with tracking id: ${gown_trackid}, id: ${gown_id} owned by the cleaner, event id: ${event_id}"

################################################################################
##### First we transfer the gown from the owner to the hospital
##### The cleaner is still the primary accountable
################################################################################
transfer_note='Transfer gowns to hospital'
result=$(transferCustody ${cleaner_token} ${cleaner_id} ${hospital_id} ${gown_id} ${piece_unit} 1 ${lochospital_id} "${transfer_note}")
event_id=$(echo ${result} | jq -r '.result.eventID')
gown_transferred_id=$(echo ${result} | jq -r '.result.transferredID')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Transferred custody of 1 gown to hospital with note: ${transfer_note}, event id: ${event_id}, gown tranferred id: ${gown_transferred_id}"

################################################################################
##### Perform the process at the hospital
################################################################################
process_name='Process Use Gown'
result=$(createProcess ${hospital_token} "${process_name}" "Use gown process performed at ${lochospital_name}")
useprocess_id=$(echo ${result} | jq -r '.result.processId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created process: ${process_name}, process id: ${useprocess_id}"

event_note='work perform surgery'
result=$(createEvent "work" ${hospital_token} "${event_note}" ${hospital_id} ${hospital_id} ${time_unit} 80 ${useprocess_id} ${surgery_spec_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action work 80 hours as input for process: ${useprocess_id}"

event_note='accept use for surgery'
result=$(createEvent "accept" ${hospital_token} "${event_note}" ${hospital_id} ${hospital_id} ${piece_unit} 1 ${useprocess_id} ${gown_transferred_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action accept 1 gown as input for process: ${useprocess_id}"

event_note='modify dirty after use'
result=$(createEvent "modify" ${hospital_token} "${event_note}" ${hospital_id} ${hospital_id} ${piece_unit} 1 ${useprocess_id} ${gown_transferred_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action modify 1 gown as output for process: ${useprocess_id}"

################################################################################
##### Transfer back to the owner (the cleaner)
################################################################################
transfer_note='Transfer gowns to cleaner'
result=$(transferCustody ${hospital_token} ${hospital_id} ${cleaner_id} ${gown_transferred_id} ${piece_unit} 1 ${loccleaner_id} "${transfer_note}")
event_id=$(echo ${result} | jq -r '.result.eventID')
gown_transferred_back_id=$(echo ${result} | jq -r '.result.transferredID')

if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Transferred custody of 1 gown to cleaner with note: ${transfer_note}, event id: ${event_id}, gown transferred id: ${gown_transferred_back_id}"

################################################################################
##### Perform the process at the cleaner
################################################################################
process_name='Process Clean Gown'
result=$(createProcess ${cleaner_token} "${process_name}" "Clean gown process performed at ${loccleaner_name}")
cleanprocess_id=$(echo ${result} | jq -r '.result.processId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created process: ${process_name}, process id: ${cleanprocess_id}"

event_note='accept gowns to be cleaned'
result=$(createEvent "accept" ${cleaner_token} "${event_note}" ${cleaner_id} ${cleaner_id} ${piece_unit} 1 ${cleanprocess_id} ${gown_transferred_back_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action accept 1 gown as input for process: ${cleanprocess_id}"

event_note='consume water for the washing'
result=$(createEvent "consume" ${cleaner_token} "${event_note}" ${cleaner_id} ${cleaner_id} ${volume_unit} 25 ${cleanprocess_id} ${water_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action consume 25 liters water as input for process: ${cleanprocess_id}"

event_note='consume soap for the washing'
result=$(createEvent "consume" ${cleaner_token} "${event_note}" ${cleaner_id} ${cleaner_id} ${mass_unit} 50 ${cleanprocess_id} ${soap_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action consume 50 kg soap as input for process: ${cleanprocess_id}"

event_note='modify clean after washing'
result=$(createEvent "modify" ${cleaner_token} "${event_note}" ${cleaner_id} ${cleaner_id} ${piece_unit} 1 ${cleanprocess_id} ${gown_transferred_back_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action modify 1 gown as output of process: ${cleanprocess_id}"

echo "$(date) - Doing trace and track gown: ${gown_transferred_back_id}"
result=$(traceTrack ${gown_transferred_back_id} 10)

if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo ${result} | jq -r '.result'

echo -e "Result from trace"
echo ${result} | jq -r '.result.trace[] | .id + " " + .__typename + " " + .name + " " + .note'

echo -e "Result from track"
echo ${result} | jq -r '.result.track[] | .id + " " + .__typename + " " + .name + " " + .note'

