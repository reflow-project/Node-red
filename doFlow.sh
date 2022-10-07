hosp_cred_file=.creds_hosp.json
cleaner_cred_file=.creds_clean.json
admin_cred_file=.creds_admin.json

admin_key="$(cat ${admin_cred_file} | jq -r '.key')"

hospital_name="$(cat ${hosp_cred_file} | jq -r '.name')"
hospital_username="$(cat ${hosp_cred_file} | jq -r '.username')"
hospital_email="$(cat ${hosp_cred_file} | jq -r '.email')"
hospital_lat="$(cat ${hosp_cred_file} | jq -r '.lat')"
hospital_long="$(cat ${hosp_cred_file} | jq -r '.long')"
hospital_addr="$(cat ${hosp_cred_file} | jq -r '.addr')"
hospital_note="$(cat ${hosp_cred_file} | jq -r '.note')"
hospital_hmac="$(cat ${hosp_cred_file} | jq -r '."seedServerSideShard.HMAC"')"
hospital_id="$(cat ${hosp_cred_file} | jq -r '.id')"

cleaner_name="$(cat ${cleaner_cred_file} | jq -r '.name')"
cleaner_username="$(cat ${cleaner_cred_file} | jq -r '.username')"
cleaner_email="$(cat ${cleaner_cred_file} | jq -r '.email')"
cleaner_lat="$(cat ${cleaner_cred_file} | jq -r '.lat')"
cleaner_long="$(cat ${cleaner_cred_file} | jq -r '.long')"
cleaner_addr="$(cat ${cleaner_cred_file} | jq -r '.addr')"
cleaner_note="$(cat ${cleaner_cred_file} | jq -r '.note')"
cleaner_hmac="$(cat ${cleaner_cred_file} | jq -r '."seedServerSideShard.HMAC"')"
cleaner_id="$(cat ${cleaner_cred_file} | jq -r '.id')"

if [ "${hospital_email} " == " " ] || [ "${cleaner_email} " == " " ]
then
    echo "credentials not set"
    echo "==${hospital_email}==${cleaner_email}=="
    exit -1
fi

# read the endpoint
case "${1}" in
        "testing")
            my_endpoint='http://65.109.11.42:9000/api'
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

my_nodered='localhost:1880/interfacer'

machine=$(echo "${my_endpoint}" | sed 's/http[s]*:\/\/\(.*\)[:0-9]*\/api/\1/g')
init_file="init_${machine}.json"



body=""
exctcont_filename='extract_contracts'

function update_field {
    orig_file=${1}
    prefixed_field=${2}
    new_value=${3}

    update_tmpfile=$(mktemp)
    cp ${orig_file} "${update_tmpfile}" &&
    # jq --arg field "$prefixed_field" --arg prefix "$prefix" --arg newvalue "$new_value" '.[$prefix].[$field] |= $newvalue'  ${update_tmpfile} > ${orig_file} &&
    jq --argjson prefixed_field "$prefixed_field" --arg newvalue "${new_value}" 'setpath( $prefixed_field; $newvalue)' ${update_tmpfile} > ${orig_file} &&
    rm -f -- "${update_tmpfile}"
}

function signRequest {
    variables=${1}
    query=${2}
    zenKeysFile=${3}

    sign_tmpfile=$(mktemp)
    # echo ${sign_tmpfile}
    echo "{\"a\":\"b\"}" > ${sign_tmpfile}
    update_field "${sign_tmpfile}" "[\"variables\"]" "${variables}" &&
    update_field "${sign_tmpfile}" "[\"query\"]" "${query}" &&
    encoded=$(cat "${sign_tmpfile}" | jq tostring | base64) &&
    update_field "${sign_tmpfile}" "[\"gql\"]" "${encoded}" &&
    cp "${sign_tmpfile}" ss.json &&
    json_result=$(~/bin/zenroom-osx.command -a "${sign_tmpfile}" -k ${zenKeysFile} -z sign.zen) &&
    rm -f -- "${sign_tmpfile}" &&
    echo ${json_result}
}

function getHMAC {
    body="{\"email\" : \"${1}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/getHMAC 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createPerson {
    body="{\"name\" : \"${1}\", \"username\" : \"${2}\", \"email\" : \"${3}\", \"eddsaPublicKey\" : \"${4}\", \"key\" : \"${admin_key}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/createPerson 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createLocation {
    sign_body="\"eddsa\" : \"${1}\", \"username\" : \"${2}\""
    body="{${sign_body}, \"name\" : \"${3}\", \"lat\" : ${4}, \"long\" : ${5}, \"addr\" : \"${6}\", \"note\" : \"${7}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/createLocation 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createUnit {
    sign_body="\"eddsa\" : \"${1}\", \"username\" : \"${2}\""
    body="{${sign_body}, \"label\" : \"${3}\", \"symbol\" : \"${4}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/createUnit 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createProcess {
    sign_body="\"eddsa\" : \"${1}\", \"username\" : \"${2}\""
    body="{${sign_body}, \"process_name\" : \"${3}\", \"process_note\" : \"${4}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/createProcess 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function transferCustody {
    sign_body="\"eddsa\" : \"${1}\", \"username\" : \"${2}\""
    body="{${sign_body}, \"provider_id\" : \"${3}\", \"receiver_id\" : \"${4}\", \"resource_name\" : \"${5}\", \"resource_id\" : \"${6}\", \"unit_id\" : \"${7}\", \"amount\" : ${8}, \"location_id\" : \"${9}\", \"note\": \"${10}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/createTransfer 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createResourceSpec {
    sign_body="\"eddsa\" : \"${1}\", \"username\" : \"${2}\""
    body="{${sign_body}, \"unit_id\" : \"${3}\", \"name\" : \"${4}\", \"note\" : \"${5}\", \"classification\" : \"${6}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/createResourceSpec 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createResource {
    sign_body="\"eddsa\" : \"${1}\", \"username\" : \"${2}\""
    body="{${sign_body}, \"agent_id\" : \"${3}\", \"resource_name\" : \"${4}\", \"resource_id\" : \"${5}\", \"unit_id\" : \"${6}\", \"amount\" : ${7}, \"classification\": \"${8}\", \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/createResource 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

function createEvent {
    
    sign_body="\"eddsa\" : \"${1}\", \"username\" : \"${2}\""
    action=${3}
    common_body="${sign_body}, \"action\" : \"${action}\", \"note\": \"${4}\", \"provider_id\" : \"${5}\", \"receiver_id\" : \"${6}\", \"unit_id\" : \"${7}\", \"amount\" : ${8}, \"endpoint\" : \"${my_endpoint}\""

    case "${action}" in
        "accept")
            body="{${common_body}, \"processIn_id\" : \"${9}\", \"resource_id\" : \"${10}\"}"
        ;;
        "consume")
            body="{${common_body}, \"processIn_id\" : \"${9}\", \"resource_id\" : \"${10}\"}"
        ;;
        "modify")
            body="{${common_body}, \"processOut_id\" : \"${9}\", \"resource_id\" : \"${10}\"}"
        ;;
        "produce")
            body="{${common_body}, \"processOut_id\" : \"${9}\", \"resourcetrack_id\" : \"${10}\", \"resource_name\" : \"${11}\", \"classification\": \"${12}\"}"
        ;;
        "work")
            body="{${common_body}, \"processIn_id\" : \"${9}\", \"classification\": \"${10}\"}"
        ;;
        *)
            echo "Please specify a valid action"
        ;;
	esac

    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/createEvent 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
    # echo ${body}
}

function traceTrack {

    body="{\"resource_id\" : \"${1}\", \"recursion\" : ${2}, \"endpoint\" : \"${my_endpoint}\" }"
    result=$(curl -X POST -H "Content-Type: application/json" -d "${body}" ${my_nodered}/traceTrack 2>/dev/null)
    json_result="{\"result\": $result, \"body\": $body}"
    echo ${json_result}
}

################################################################################
##### Get credentials for the 2 users
################################################################################
################################################
##### Get the contract from the checked-out repo
################################################
tsc ./${exctcont_filename}.ts
node ./${exctcont_filename}.js

if [ "${hospital_id} " == "null " ]
then
    ################################################
    ##### Get the HMAC for the hospital
    ################################################
    result=$(getHMAC ${hospital_email})
    hospital_seed=$(echo ${result} | jq -r '.result.seed')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        echo "DEBUG: $(date) -  hospital_seed is ${hospital_seed}" 
    fi

    if [ "${hospital_seed} " == " " ]
    then
        echo "Getting seed failed for ${hospital_username}"
        exit -1
    fi
    echo "$(date) - Got seed for user hospital, seed: ${hospital_seed}"
    # jq --arg newhmac "$hospital_seed" '."seedServerSideShard.HMAC" |= $newhmac'  > ${hosp_cred_file}
    update_field ${hosp_cred_file} "[\"seedServerSideShard.HMAC\"]" $hospital_seed

    ################################################
    ##### Generate keys
    ################################################
    result=$(~/bin/zenroom-osx.command -a ${hosp_cred_file} -z keypairoomClient.zen)

    if [ "${do_debug} " == "true " ]
        then
            echo "DEBUG: $(date) -  result is: $(echo ${result} | jq '.')"
            # echo "$(date) - lochospital_id is ${lochospital_id}" 
        fi

    seed=$(echo ${result} | jq -r '.seed')
    eddsa_public_key=$(echo ${result} | jq -r '.eddsa_public_key')
    eddsa_private_key=$(echo ${result} | jq -r '.keyring.eddsa')
    update_field ${hosp_cred_file} "[\"seed\"]" "$seed"
    update_field ${hosp_cred_file} "[\"eddsa_public_key\"]" "$eddsa_public_key"
    update_field ${hosp_cred_file} "[\"keyring\",\"eddsa\"]" "$eddsa_private_key"

    ################################################
    ##### Create the person
    ################################################
    result=$(createPerson "${hospital_name}" ${hospital_username} ${hospital_email} ${eddsa_public_key})
    if [ "${do_debug} " == "true " ]
        then
            echo "DEBUG: $(date) -  result is: $(echo ${result} | jq '.')"
            # echo "$(date) - lochospital_id is ${lochospital_id}" 
        fi

    hospital_id=$(echo ${result} | jq -r '.result.id')
    update_field ${hosp_cred_file} "[\"id\"]" "$hospital_id"
else
    echo "Data for hospital seems to be already available"
fi

if [ "${cleaner_id} " == "null " ]
then
    ################################################
    ##### Get the HMAC for the cleaner
    ################################################
    result=$(getHMAC ${cleaner_email})
    cleaner_seed=$(echo ${result} | jq -r '.result.seed')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        echo "DEBUG: $(date) -  cleaner_seed is ${cleaner_seed}" 
    fi
    if [ "${cleaner_seed} " == " " ]
    then
        echo "Getting seed failed for ${cleaner_username}"
        exit -1
    fi
    echo "$(date) - Got seed for user cleaner, seed: ${cleaner_seed}"
    update_field ${cleaner_cred_file} "[\"seedServerSideShard.HMAC\"]" $cleaner_seed

    ################################################
    ##### Generate keys
    ################################################
    result=$(~/bin/zenroom-osx.command -a ${cleaner_cred_file} -z keypairoomClient.zen)

    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: $(echo ${result} | jq '.')"
        # echo "$(date) - lochospital_id is ${lochospital_id}" 
    fi

    seed=$(echo ${result} | jq -r '.seed')
    eddsa_public_key=$(echo ${result} | jq -r '.eddsa_public_key')
    eddsa_private_key=$(echo ${result} | jq -r '.keyring.eddsa')
    update_field ${cleaner_cred_file} "[\"seed\"]" "$seed"
    update_field ${cleaner_cred_file} "[\"eddsa_public_key\"]" "$eddsa_public_key"
    update_field ${cleaner_cred_file} "[\"keyring\",\"eddsa\"]" "$eddsa_private_key"

    ################################################
    ##### Create the person
    ################################################
    result=$(createPerson "${cleaner_name}" ${cleaner_username} ${cleaner_email} ${eddsa_public_key})
    if [ "${do_debug} " == "true " ]
        then
            echo "DEBUG: $(date) -  result is: $(echo ${result} | jq '.')"
            # echo "$(date) - lochospital_id is ${lochospital_id}" 
        fi

    cleaner_id=$(echo ${result} | jq -r '.result.id')
    update_field ${cleaner_cred_file} "[\"id\"]" "$cleaner_id"
else
    echo "Data for cleaner seems to be already available"
fi

if [ "${do_init} " == "true " ] || [ ! -f "${init_file}" ]
then
    echo "$(date) - Creating units"
    ################################################################################
    ##### Create locations and units of measures
    ################################################################################
    eddsa_hosp=$(cat ${hosp_cred_file} | jq -r '.keyring.eddsa')
    result=$(createLocation ${eddsa_hosp} "${hospital_username}" "${hospital_name}" ${hospital_lat} ${hospital_long} "${hospital_addr}" ${hospital_note})
    lochospital_id=$(echo ${result} | jq -r '.result.location')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - lochospital_id is ${lochospital_id}" 
    fi
    echo "$(date) - Created location for ${hospital_name}, id: ${lochospital_id}"
    
    eddsa_cleaner=$(cat ${cleaner_cred_file} | jq -r '.keyring.eddsa')
    result=$(createLocation ${eddsa_cleaner} "${cleaner_username}" "${cleaner_name}" ${cleaner_lat} ${cleaner_long} "${cleaner_addr}" ${cleaner_note})
    loccleaner_id=$(echo ${result} | jq -r '.result.location')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - loccleaner_id is ${loccleaner_id}"
    fi
    echo "$(date) - Created location for ${cleaner_name}, id: ${loccleaner_id}"

    result=$(createUnit ${eddsa_cleaner} "${cleaner_username}" "u_piece" "om2:one")
    piece_unit=$(echo ${result} | jq -r '.result.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - Piece unit is ${piece_unit}" 
    fi
    echo "$(date) - Created unit for gowns, id: ${piece_unit}"

    result=$(createUnit ${eddsa_cleaner} "${cleaner_username}" "kg" "om2:kilogram")
    mass_unit=$(echo ${result} | jq -r '.result.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - Mass unit is ${mass_unit}" 
    fi
    echo "$(date) - Created unit for mass (kg), id: ${mass_unit}"

    result=$(createUnit ${eddsa_cleaner} "${cleaner_username}" "lt" "om2:litre")
    volume_unit=$(echo ${result} | jq -r '.result.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - Volume unit is ${volume_unit}"
    fi
    echo "$(date) - Created unit for volume (litre), id: ${volume_unit}"
    
    result=$(createUnit ${eddsa_hosp} "${hospital_username}" "h" "om2:hour")
    time_unit=$(echo ${result} | jq -r '.result.unit')
    if [ "${do_debug} " == "true " ]
    then
        echo "DEBUG: $(date) -  result is: ${result}"
        # echo "$(date) - Time unit is ${time_unit}" 
    fi
    echo "$(date) - Create unit for time (hour), id: ${time_unit}"

    # Save units to file
    jq -n "{lochospital_id: \"${lochospital_id}\",  loccleaner_id: \"${loccleaner_id}\", piece_unit: \"${piece_unit}\", mass_unit: \"${mass_unit}\", volume_unit: \"${volume_unit}\", time_unit: \"${time_unit}\"}" > ${init_file}
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
    echo "$(date) - Read location for ${hospital_name}, id: ${lochospital_id}"
    echo "$(date) - Read location for ${cleaner_name}, id: ${loccleaner_id}"
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
eddsa_cleaner=$(cat ${cleaner_cred_file} | jq -r '.keyring.eddsa')
note='Specification for soap to be used to wash the gowns'
result=$(createResourceSpec ${eddsa_cleaner} "${cleaner_username}" "${mass_unit}" "Soap" "${note}" "https://www.wikidata.org/wiki/Q34396")
soap_spec_id=$(echo ${result} | jq -r '.result.specId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created ${note} with spec id: ${soap_spec_id}"

soap_trackid="soap-${RANDOM}"
result=$(createResource ${eddsa_cleaner} "${cleaner_username}" "${cleaner_id}" "Soap" ${soap_trackid} "${mass_unit}" 100 ${soap_spec_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
soap_id=$(echo ${result} | jq -r '.result.resourceId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created 100 kg soap with tracking id: ${soap_trackid}, id: ${soap_id} owned by the cleaner, event id: ${event_id}"

note='Specification for water to be used to wash the gowns'
result=$(createResourceSpec ${eddsa_cleaner} "${cleaner_username}" "${volume_unit}" "Water" "${note}" "https://www.wikidata.org/wiki/Q283")
water_spec_id=$(echo ${result} | jq -r '.result.specId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created ${note} with spec id: ${water_spec_id}"

water_trackid="water-${RANDOM}"
result=$(createResource ${eddsa_cleaner} "${cleaner_username}" "${cleaner_id}" "Water" ${water_trackid} "${volume_unit}" 50 ${water_spec_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
water_id=$(echo ${result} | jq -r '.result.resourceId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created 50 liters water with tracking id: ${water_trackid}, id: ${water_id} owned by the cleaner, event id: ${event_id}"

note='Specification for cotton to be used to sew the gowns'
result=$(createResourceSpec ${eddsa_cleaner} "${cleaner_username}" "${mass_unit}" "Cotton" "${note}" "https://www.wikidata.org/wiki/Q11457")
cotton_spec_id=$(echo ${result} | jq -r '.result.specId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created ${note} with spec id: ${cotton_spec_id}"

cotton_trackid="cotton-${RANDOM}"
result=$(createResource ${eddsa_cleaner} "${cleaner_username}" "${cleaner_id}" "Cotton" ${cotton_trackid} "${mass_unit}" 20 ${cotton_spec_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
cotton_id=$(echo ${result} | jq -r '.result.resourceId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created 20 kg cotton with tracking id: ${cotton_trackid}, id: ${cotton_id} owned by the cleaner, event id: ${event_id}"

note='Specification for gowns'
result=$(createResourceSpec ${eddsa_cleaner} "${cleaner_username}" "${piece_unit}" "Gown" "${note}" "https://www.wikidata.org/wiki/Q89990310")
gown_spec_id=$(echo ${result} | jq -r '.result.specId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created ${note} with spec id: ${gown_spec_id}"

eddsa_hosp=$(cat ${hosp_cred_file} | jq -r '.keyring.eddsa')
note='Specification for surgical operation'
result=$(createResourceSpec ${eddsa_hosp} "${hospital_username}" "${time_unit}" "Surgical operation" "${note}" "https://www.wikidata.org/wiki/Q600236")
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
result=$(createProcess ${eddsa_cleaner} "${cleaner_username}" "${process_name}" "Sew gown process performed by ${cleaner_name}")
sewgownprocess_id=$(echo ${result} | jq -r '.result.processId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created process: ${process_name}, process id: ${sewgownprocess_id}"

event_note='consume cotton for sewing'
result=$(createEvent ${eddsa_cleaner} "${cleaner_username}" "consume" "${event_note}" ${cleaner_id} ${cleaner_id} ${mass_unit} 10 ${sewgownprocess_id} ${cotton_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action consume 10 kg cotton as input for process: ${sewgownprocess_id}"

event_note='produce gown'
gown_trackid="gown-${RANDOM}"
result=$(createEvent ${eddsa_cleaner} "${cleaner_username}" "produce" "${event_note}" ${cleaner_id} ${cleaner_id} ${piece_unit} 1 ${sewgownprocess_id} ${gown_trackid} "Gown" ${gown_spec_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
gown_id=$(echo ${result} | jq -r '.result.resourceId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action produce 1 gown with tracking id: ${gown_trackid}, id: ${gown_id} owned by the cleaner as output of process: ${sewgownprocess_id}"

# result=$(createResource ${cleaner_seed} "${cleaner_id}" "Gown" ${gown_trackid} "${piece_unit}" 1)
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
result=$(transferCustody ${eddsa_cleaner} "${cleaner_username}" ${cleaner_id} ${hospital_id} "Gown" ${gown_id} ${piece_unit} 1 ${lochospital_id} "${transfer_note}")
event_id=$(echo ${result} | jq -r '.result.eventId')
gown_transferred_id=$(echo ${result} | jq -r '.result.transferredId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Transferred custody of 1 gown to hospital with note: ${transfer_note}, event id: ${event_id}, gown tranferred id: ${gown_transferred_id}"

################################################################################
##### Perform the process at the hospital
################################################################################
process_name='Process Use Gown'
result=$(createProcess ${eddsa_hosp} "${hospital_username}" "${process_name}" "Use gown process performed at ${hospital_name}")
useprocess_id=$(echo ${result} | jq -r '.result.processId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created process: ${process_name}, process id: ${useprocess_id}"

event_note='work perform surgery'
result=$(createEvent ${eddsa_hosp} "${hospital_username}" "work" "${event_note}" ${hospital_id} ${hospital_id} ${time_unit} 80 ${useprocess_id} ${surgery_spec_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action work 80 hours as input for process: ${useprocess_id}"

event_note='accept use for surgery'
result=$(createEvent ${eddsa_hosp} "${hospital_username}" "accept" "${event_note}" ${hospital_id} ${hospital_id} ${piece_unit} 1 ${useprocess_id} ${gown_transferred_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action accept 1 gown as input for process: ${useprocess_id}"

event_note='modify dirty after use'
result=$(createEvent ${eddsa_hosp} "${hospital_username}" "modify" "${event_note}" ${hospital_id} ${hospital_id} ${piece_unit} 1 ${useprocess_id} ${gown_transferred_id})
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
result=$(transferCustody ${eddsa_hosp} "${hospital_username}" ${hospital_id} ${cleaner_id} "Gown" ${gown_transferred_id} ${piece_unit} 1 ${loccleaner_id} "${transfer_note}")
event_id=$(echo ${result} | jq -r '.result.eventId')
gown_transferred_back_id=$(echo ${result} | jq -r '.result.transferredId')

if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Transferred custody of 1 gown to cleaner with note: ${transfer_note}, event id: ${event_id}, gown transferred id: ${gown_transferred_back_id}"

################################################################################
##### Perform the process at the cleaner
################################################################################
process_name='Process Clean Gown'
result=$(createProcess ${eddsa_cleaner} "${cleaner_username}" "${process_name}" "Clean gown process performed at ${cleaner_name}")
cleanprocess_id=$(echo ${result} | jq -r '.result.processId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created process: ${process_name}, process id: ${cleanprocess_id}"

event_note='accept gowns to be cleaned'
result=$(createEvent ${eddsa_cleaner} "${cleaner_username}" "accept" "${event_note}" ${cleaner_id} ${cleaner_id} ${piece_unit} 1 ${cleanprocess_id} ${gown_transferred_back_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action accept 1 gown as input for process: ${cleanprocess_id}"

event_note='consume water for the washing'
result=$(createEvent ${eddsa_cleaner} "${cleaner_username}" "consume" "${event_note}" ${cleaner_id} ${cleaner_id} ${volume_unit} 25 ${cleanprocess_id} ${water_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action consume 25 liters water as input for process: ${cleanprocess_id}"

event_note='consume soap for the washing'
result=$(createEvent ${eddsa_cleaner} "${cleaner_username}" "consume" "${event_note}" ${cleaner_id} ${cleaner_id} ${mass_unit} 50 ${cleanprocess_id} ${soap_id})
event_id=$(echo ${result} | jq -r '.result.eventId')
if [ "${do_debug} " == "true " ]
then
    echo "DEBUG: $(date) -  result is: ${result}"
fi
echo "$(date) - Created event: ${event_note}, event id: ${event_id}, action consume 50 kg soap as input for process: ${cleanprocess_id}"

event_note='modify clean after washing'
result=$(createEvent ${eddsa_cleaner} "${cleaner_username}" "modify" "${event_note}" ${cleaner_id} ${cleaner_id} ${piece_unit} 1 ${cleanprocess_id} ${gown_transferred_back_id})
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

