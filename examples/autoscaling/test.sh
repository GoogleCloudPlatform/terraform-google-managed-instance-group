#!/usr/bin/env bash

set -x
set -e

### Verify instance status ###

SELF_LINK=$(terraform output "instance_self_link")
STATUS=$(terraform output "instance_status")
if [[ "${SELF_LINK}" != "" && "${STATUS}" == "RUNNING" ]]; then
  echo "INFO: Regional instance ${i} created and running."
else
  echo "ERROR: Regional instance not found or is not running"
  exit 1
fi
