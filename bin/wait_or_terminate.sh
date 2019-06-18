#!/bin/bash

# for debug
# set -x

EXPERIMENT_ID=${BUILD}
EXPERIMENT_TEMPLATE=
NAMESPACE=default
FREQUENCY=2
DURATION=300

# process options
while [ $# -gt 0 ]; do
  case "${1}" in
    -i|--experiment-id)
      EXPERIMENT_ID="${2}"
      shift; shift
      ;;
    -d|--duration)
      DURATION="${2}"
      shift; shift
      ;;
    -f|--frequency)
      FREQUENCY="${2}"
      shift; shift
      ;;
    -n|--namespace)
      NAMESPACE="${2}"
      shift; shift
      ;;
    -s|--stop-file)
      STOP_FILE="${2}"
      shift; shift
      ;;
    *) EXPERIMENT_TEMPLATE="${1}"
      shift
      ;;
  esac
done

# for debug
echo "      EXPERIMENT_ID = $EXPERIMENT_ID"
echo "EXPERIMENT_TEMPLATE = $EXPERIMENT_TEMPLATE"
echo "          NAMESPACE = $NAMESPACE"
echo "           DURATION = $DURATION"
echo "          FREQUENCY = $FREQUENCY"
echo "          STOP_FILE = $STOP_FILE"

# validate input
# compute values
PIPELINERUN="bookinfo-app-master-${EXPERIMENT_ID}"
SERVICE=$(yq r ${EXPERIMENT_TEMPLATE} metadata.name)
EXPERIMENT="${SERVICE}-${EXPERIMENT_ID}"

get_generateload_status() {
  kubectl get pipelinerun ${PIPELINERUN} -o json \
  | jq '.status.taskRuns' \
  | jq -r '.[] | select(.pipelineTaskName=="generate-load").status.conditions | .[].status'
}

get_experiment_status() {
  kubectl --namespace ${NAMESPACE} \
    get experiment ${EXPERIMENT} \
    -o jsonpath='{.status.conditions[?(@.type=="ExperimentCompleted")].status}'
}

# If we have already completed; just exit
eStatus=$(get_experiment_status)
status=${eStatus:-"False"} # experiment might not have started
if [[ "${status}" == "True" ]]; then
  # experiment is done; make sure load generation is terminated and exit
  generate_load_status=$(get_generateload_status)
  if [ "${generate_load_status}" == "Unknown" ]; then
    touch ${STOP_FILE}
  fi
  exit 0
fi

# Determine when the pipeline was started
start=$(kubectl get pipelinerun ${PIPELINERUN} -o jsonpath='{.status.startTime}' | sed 's/T/ /' | sed 's/Z$//')
startS=$(TZ=/usr/share/UTC date -d "$start" +%s)
#mac startS=$(TZ=/usr/share/UTC date -j -f "%F %T" "$start" +%s)

timePassedS=$(( $(date +%s) - $startS ))
while (( timePassedS < ${DURATION} )); do
  sleep ${FREQUENCY}

eStatus=$(get_experiment_status)
status=${eStatus:-"False"} # experiment might not have started
if [[ "${status}" == "True" ]]; then
  # experiment is done; make sure load generation is terminated and exit
  generate_load_status=$(get_generateload_status)
  if [[ "${generate_load_status}" == "Unknown" ]]; then
    touch ${STOP_FILE}
  fi
  exit 0
fi

  timePassedS=$(( $(date +%s) - $startS ))
done

# We've waited ${DURATION} for the experiment to complete
# It hasn't, so we kill the experiment and the load-generation
kubectl --namespace ${NAMESPACE} delete experiment $EXPERIMENT --ignore-not-found
touch ${STOP_FILE}
exit 1
