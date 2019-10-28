#!/bin/bash
set -euo pipefail

# TOKEN=''
# ACCESS_KEY=''
# API_ID=''
# SEVERITY_THRESHOLD='High'
# POLL_WINDOW=5

if [[ $TOKEN == "" ]]; then
  echo "TOKEN has not been set. Aborting."
  exit 1
fi

if [[ $ACCESS_KEY == "" ]]; then
  echo "ACCESS_KEY has not been set. Aborting."
  exit 1
fi

if [[ $API_ID == "" ]]; then
  echo "API_ID has not been set. Aborting."
  exit 1
fi

if [[ $SEVERITY_THRESHOLD == "" ]]; then
  SEVERITY_THRESHOLD='High'
fi

if [[ $POLL_WINDOW == "" ]]; then
  POLL_WINDOW=5
fi

BASE_URL='https://api-scanner.tinfoilsecurity.com/api/v1'
AUTH_HEADER="Authorization:Token token=${TOKEN}, access_key=${ACCESS_KEY}"

# [1] Start an API scan
START_SCAN_RESPONSE=$(curl -s -X POST "${BASE_URL}/apis/${API_ID}/scans" --header "${AUTH_HEADER}")
SCAN_ID=$(echo ${START_SCAN_RESPONSE} | grep -o "\"id\":[0-9]\+" | grep -o "[0-9]\+")

if [[ $SCAN_ID == "" ]]; then
  echo "Scan failed to start. Aborting."
  exit 1
else
  echo "Scan with id ${SCAN_ID} successfully started."
fi

# [2] Poll scan until it has completed/failed/cancelled
TIME_ELAPSED=0

while true; do
  SCAN=$(curl -s -X GET ${BASE_URL}/scans/${SCAN_ID}/ --header "${AUTH_HEADER}")
  SCAN_STATUS=$(echo ${SCAN} | grep -o "\"status\":\"[[:alpha:]]\+\"" | grep -o ":\"[[:alpha:]]\+\"" | grep -o "[[:alpha:]]\+")
  if [[ $SCAN_STATUS != "running" ]]; then 
    break
  fi
  sleep ${POLL_WINDOW}
  echo "Scan still running, time elapsed: ${TIME_ELAPSED}"
  let TIME_ELAPSED=TIME_ELAPSED+POLL_WINDOW
done

if [[ $SCAN_STATUS == "failed" ]]; then
  echo "Scan failed. Aborting."
  exit 1
elif [[ $SCAN_STATUS == "succeeded" ]]; then
  echo "Scan succeeded."
else
  echo "Unknown status. Aborting."
  exit 1
fi

# [3] Abort next step if severity threshold crossed
declare -a SEVERITY_MAP=('Info' 'Low' 'Medium' 'High')

SEVERITY_INDEX=0
for i in $(seq 0 3); do
  if [ $SEVERITY_THRESHOLD = ${SEVERITY_MAP[$i]} ]; then
    break
  fi  
  let SEVERITY_INDEX=SEVERITY_INDEX+1
done

ISSUES=$(curl -s -X GET ${BASE_URL}/scans/${SCAN_ID}/issues --header "${AUTH_HEADER}")

for i in `seq ${SEVERITY_INDEX} 3`; do
  if echo "${ISSUES}" | grep -q "${SEVERITY_THRESHOLD}" 
  then
    echo "Issue severity threshold exceeded. Aborting."
    exit 1
  fi
done

echo "No issues crossed severity threshold, scan was successful."