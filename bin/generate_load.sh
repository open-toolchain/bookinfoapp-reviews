#!/bin/sh

# for debug
# set -x

FREQUENCY=2
OPTIONS="-Is"
DURATION="10"
URL=
STOP_FILE=

# process options
while [ $# -gt 0 ]; do
  case "${1}" in
    -u|--url)
      URL="${2}"
      shift; shift
      ;;
    -f|--frequency)
      FREQUENCY="${2}"
      shift; shift
      ;;
    -d|--duration)
      DURATION="${2}"
      shift; shift
      ;;
    -o|--options)
      OPTIONS="${2}"
      shift; shift
      ;;
    -s|--stop-file)
      STOP_FILE="${2}"
      shift; shift
      ;;
    *) echo "WARNING: Ignoring unknown option: ${1}"
      shift
      ;;
  esac
done

echo "      URL = $URL"
echo "  OPTIONS = $OPTIONS"
echo " DURATION = $DURATION"
echo "FREQUENCY = $FREQUENCY"
echo "STOP_FILE = $STOP_FILE"

# validate input
if [ -z $URL ]; then
  echo "url to test for liveness required"
  exit 1
fi

COUNT=0
startS=$(date +%s)
timePassedS=$(( $(date +%s) - $startS ))
while [ $timePassedS -lt $DURATION ]; do
  if [ -f ${STOP_FILE} ]; then break; fi
  sleep ${FREQUENCY}

  curl $OPTIONS $URL | grep HTTP #> /dev/null
  COUNT=$(( $COUNT + 1 ))

  timePassedS=$(( $(date +%s) - $startS ))
done

echo "Sent ${COUNT} queries over ${timePassedS}s"