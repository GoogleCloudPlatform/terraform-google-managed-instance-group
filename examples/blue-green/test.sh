#!/usr/bin/env bash

set -x 
set -e

URL="http://$(terraform output load-balancer-ip)"
status=0
count=0
while [[ $count -lt 120 && $status -ne 200 ]]; do
  echo "INFO: Waiting for load balancer..."
  status=$(curl -sf -m 5 -o /dev/null -w "%{http_code}" "${URL}" || true)
  ((count=count+1))
  sleep 5
done
if [[ $count -lt 120 ]]; then
  echo "INFO: PASS"
else
  echo "ERROR: Failed"
  exit 1
fi

DEPLOY_COLOR="$(terraform output deploy-color)"
count=0
while [[ $count -lt 120 ]]; do
  RES=$(curl -s -m 5 -w '%{http_code}\n' "${URL}" |grep "class=\"card ${DEPLOY_COLOR}" | tail -1 || true)
  echo "INFO: Current deployment: ${RES}"
  if [[ "${RES}" =~ $DEPLOY_COLOR ]]; then
    echo "INFO: PASS. Current deployment color: ${DEPLOY_COLOR}"
    exit 0
  fi
  ((count=count+1))
  sleep 5
done
echo "ERROR: Failed"
exit 1

(while true; do ; sleep 1; done)