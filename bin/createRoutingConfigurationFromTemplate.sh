#!/bin/sh

# For debugging
# set -x

# Default values
EXPERIMENT_ID=
BASELINE=
CANDIDATE=
TEMPLATE=
NAME_POSTFIX=

# Read inputs
while [ $# -gt 0 ]; do
  case "${1}" in
    -u|--experiment-id)
      EXPERIMENT_ID="${2}"
      shift; shift
      ;;
    -b|--baseline)
      BASELINE="${2}"
      shift; shift
      ;;
    -c|--candidate)
      CANDIDATE="${2}"
      shift; shift
      ;;
    *) TEMPLATE="${1}"
      shift
      ;;
  esac
done

# Validate input
if [ -z "${TEMPLATE}" ]; then
  echo "Invalid input; template required"
  exit -1
fi
if [ -z "${EXPERIMENT_ID}" ]; then
  echo "WARNING: no unique name postfix specified with --experiment-id option"
else
  NAME_POSTFIX="-${EXPERIMENT_ID}"
fi

# Set derived values
NAME=$(yq r ${TEMPLATE} metadata.name)
NEW_NAME="${NAME}${NAME_POSTFIX}"

YAML="${TEMPLATE}"

# Process
yq w ${YAML} -i metadata.name ${NEW_NAME}

if [ -n "${BASELINE}" ]; then
  yq w ${YAML} -i spec.targetService.baseline ${BASELINE}
fi

if [ -n "${CANDIDATE}" ]; then
  yq w ${YAML} -i spec.targetService.candidate ${CANDIDATE}
fi