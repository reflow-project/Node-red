
export DEST=${1}; time ./doFlow.sh ${DEST} N N > MP-${DEST}.log
# export DEST=shared; time ./curl.sh ${DEST} N N > MP-${DEST}.log

# echo -e "Result from trace"
# cat MP-${1}.log | grep -v 'CET 2022' | jq '.trace[] | .id + " " + .__typename + " " + .note'

# echo -e "Result from track"
# cat MP-${1}.log | grep -v 'CET 2022' | jq '.track[] | .id + " " + .__typename + " " + .note'

