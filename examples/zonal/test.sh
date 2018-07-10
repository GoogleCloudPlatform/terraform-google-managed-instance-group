#!/usr/bin/env bash

set -x
set -e

function usage() {
  echo "USAGE: $0 <label <name> <value>|no-label>"
}

MODE=$1

[[ "${MODE}" != "label" && "${MODE}" != "no-label" ]] && usage && exit 1
[[ "${MODE}" == "label" && -z "$2" ]] && echo "ERROR: Missing label name" && usage && exit 1
[[ "${MODE}" == "label" && -z "$3" ]] && echo "ERROR: Missing label value" && usage && exit 1

for i in `seq 1 3`; do
  SELF_LINK=$(terraform output "instance_self_link_${i}")
  if [[ "${SELF_LINK}" != "" ]]; then
    echo "INFO: Zonal instance ${i} created."

    if [[ "${MODE}" == "label" ]]; then
      EXP_LABEL_NAME="${2}"
      EXP_LABEL_VALUE="${3}"
      ACT_LABEL_VALUE=$(gcloud compute instances describe "${SELF_LINK}" --format="value(labels.${EXP_LABEL_NAME})")
      if [[ "${ACT_LABEL_VALUE}" == "${EXP_LABEL_VALUE}" ]]; then
        echo "INFO: Found label ${EXP_LABEL_NAME}=${EXP_LABEL_VALUE} on ${SELF_LINK}"
      else
        echo "ERROR: Label ${EXP_LABEL_NAME}=${EXP_LABEL_VALUE} not found on ${SELF_LINK}"
        exit 1
      fi
    else
      # Verify no labels.
      ACT_LABEL_VALUE=$(gcloud compute instances describe "${SELF_LINK}" --format="value(labels)")
      if [[ "${ACT_LABEL_VALUE}" != "" ]]; then
        echo "ERROR: Found labels on instance ${SELF_LINK}, epxected none."
      fi
    fi
  else
    echo "ERROR: Zonal instance ${i} not found or is not running"
    exit 1
  fi
done

echo "INFO: PASS. All instances found and running."
