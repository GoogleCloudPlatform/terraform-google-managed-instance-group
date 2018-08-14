#!/usr/bin/env bash

set -x
set -e

function usage() {
  echo "USAGE: $0 [<label name> <value>|no-label>]"
}

MODE=${1-"no-label"}

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

### Verify HTTP server ###

function ssh_cleanup() {
  set +e
  rm -f ssh_config
  killall -9 autossh
  killall -9 ssh
  kill $SSH_AGENT_PID
}
trap ssh_cleanup EXIT

declare -a REMOTE_HOSTS
REMOTE_HOSTS[0]=${REMOTE_HOST_1:-$(terraform output instance_self_link_1)}
REMOTE_HOSTS[1]=${REMOTE_HOST_2:-$(terraform output instance_self_link_2)}
REMOTE_HOSTS[2]=${REMOTE_HOST_3:-$(terraform output instance_self_link_3)}

function verify_curl_through_bastion() {
  BASTION_HOST=$1
  TARGET_HOST_NAME=$2
  URL=$3
  PATTERN=${4-"*"}
  TIMEOUT=${5:-180}

  [[ -z "${BASTION_HOST}" || -z "${TARGET_HOST_NAME}" || -z "${URL}" ]] && echo "USAGE: verify_curl_through_bastion <bastion host IP or uri> <target host name> <check url> <verify pattern> [<timeout|180>]" && return 1

  # Configure SSH
  SSH_USER_EMAIL=$(gcloud config get-value account)
  SSH_USER=${SSH_USER_EMAIL//@*}

  cat > ssh_config << EOF
Host *
  User ${SSH_USER}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host remote
  HostName ${REMOTE_HOSTS[0]}
  ProxyCommand gcloud compute ssh ${SSH_USER}@${BASTION_HOST} --ssh-flag="-A -W ${TARGET_HOST_NAME}:22"
  DynamicForward 1080
EOF

  if [[ ! -f ${HOME}/.ssh/google_compute_engine ]]; then
    mkdir -p ${HOME}/.ssh && chmod 0700 ${HOME}/.ssh && \
    ssh-keygen -b 2048 -t rsa -f ${HOME}/.ssh/google_compute_engine -q -N "" -C ${SSH_USER_EMAIL}
  fi
  eval `ssh-agent`
  ssh-add ${HOME}/.ssh/google_compute_engine
  gcloud compute config-ssh
  export AUTOSSH_LOGFILE=/dev/stderr
  autossh -M 20000 -f -N -F ${PWD}/ssh_config remote

  count=0
  while [[ $count -lt $TIMEOUT ]]; do
    DATA=$(curl -m 5 -s --socks5-hostname localhost:1080 ${URL} || true)
    if grep -q "${PATTERN}" <<< "$DATA"; then
      ssh_cleanup
      return 0
    fi
    ((count=count+1))
    sleep 2
  done
  return 1
}

ALL_PASS=0
for h in ${REMOTE_HOSTS[*]}; do

  REMOTE_HOSTNAME=${h//*instances\//}

  if verify_curl_through_bastion "${h}" "${REMOTE_HOSTNAME}" http://${REMOTE_HOSTNAME}:80/ "${REMOTE_HOSTNAME}" 180; then
    echo "INFO: PASS. HTTP check for ${REMOTE_HOSTNAME}"
  else
    echo "ERROR: FAIL. HTTP check for ${REMOTE_HOSTNAME}"
    ALL_PASS=1
  fi
done

if [[ "${ALL_PASS}" -eq 0 ]]; then
  echo "INFO: PASS. All instances passed."
else
  echo "ERROR: FAIL. At least one of the checks failed."
  exit 1
fi
