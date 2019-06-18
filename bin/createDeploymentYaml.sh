#!/bin/sh

# For debugging
# set -x

# Default values
ID=
BASELINE=
CANDIDATE=
TEMPLATE=
NAME_POSTFIX=

# Read inputs
while [ $# -gt 0 ]; do
  case "${1}" in
    -u|--uid)
      ID="${2}"
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
if [ -z "${ID}" ]; then
  echo "WARNING: no unique name postfix specified with --uid option"
else
  NAME_POSTFIX="-${ID}"
fi

# Set derived values
NAME=$(yq r ${TEMPLATE} metadata.name)
NEW_NAME="${NAME}${NAME_POSTFIX}"

#MK#YAML="/tmp/$(basename ${TEMPLATE})-$$"
YAML="${TEMPLATE}"

# Process
#MK#cp ${TEMPLATE} ${YAML}
yq w ${YAML} -i metadata.name ${NEW_NAME}

if [ -n "${BASELINE}" ]; then
  yq w ${YAML} -i spec.targetService.baseline ${BASELINE}
fi

if [ -n "${CANDIDATE}" ]; then
  yq w ${YAML} -i spec.targetService.canary ${CANDIDATE}
fi

#MK#cat ${YAML}
#MK#rm ${YAML}
