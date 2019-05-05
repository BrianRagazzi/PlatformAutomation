#!/bin/bash

OPS_MAN_FQDN=https://om.pas.ragazzilab.com
ENV_FILE=env.yml
echo $OPS_MAN_FQDN

web_json=$(cat <<-EOF
{
    "name": "pas_web_vm_extension",
    "cloud_properties": {
        "nsxt": {
            "lb": {
                "server_pools": [
                    {
                        "name": "pas-web-pool"
                    }
                ]
            }
        }
    }
}
EOF
)

ssh_json=$(cat <<-EOF
{
    "name": "pas_ssh_vm_extension",
    "cloud_properties": {
        "nsxt": {
            "lb": {
                "server_pools": [
                    {
                        "name": "pas-ssh-pool"
                    }
                ]
            }
        }
    }
}
EOF
)

tcp_json=$(cat <<-EOF
{
    "name": "pas_tcp_vm_extension",
    "cloud_properties": {
        "nsxt": {
            "lb": {
                "server_pools": [
                    {
                        "name": "pas-tcp-pool"
                    }
                ]
            }
        }
    }
}
EOF
)

# POST new vm_extensions
om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/vm_extensions" \
  -x POST \
  -H "Content-Type: application/json" \
  -d "$web_json"

om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/vm_extensions" \
  -x POST \
  -H "Content-Type: application/json" \
  -d "$ssh_json"

om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/vm_extensions" \
  -x POST \
  -H "Content-Type: application/json" \
  -d "$tcp_json"


# Check for the vm_extensions
# om --env env/"${ENV_FILE}" -k \
#   curl -s -p "$OPS_MAN_FQDN/api/v0/staged/vm_extensions" \
#   -x GET | jq

# GET CF GUID
CF_GUID=$(
om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/products" |
  jq -r '.[] | .installation_name' | grep cf- | tail -1
)
# GET CF JOB  GUIDS & CONFIGS
ROUTER_JOB_GUID=$(
om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs" |
  jq | jq -r '.jobs[] | .guid' | grep ^router
)

ROUTER_JOB_CONFIG=$(
om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$ROUTER_JOB_GUID/resource_config" |
  jq -r '. += {"additional_vm_extensions": "pcf_web_vm_extension"}'
)

TCP_ROUTER_JOB_GUID=$(
om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs" |
  jq | jq -r '.jobs[] | .guid' | grep ^tcp
)

TCP_ROUTER_JOB_CONFIG=$(
om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$TCP_ROUTER_JOB_GUID/resource_config" |
  jq -r '. += {"additional_vm_extensions": "pcf_web_vm_extension"}'
)

DIEGO_BRAIN_JOB_GUID=$(
om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs" |
  jq | jq -r '.jobs[] | .guid' | grep ^diego\_brain
)

DIEGO_BRAIN_JOB_CONFIG=$(
om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$DIEGO_BRAIN_JOB_GUID/resource_config" |
  jq -r '. += {"additional_vm_extensions": "pcf_web_vm_extension"}'
)

# Update vm_extensions property for CF JOBS
om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$ROUTER_JOB_GUID/resource\_config" \
  -x PUT \
  -H "Content-Type: application/json" \
  -d "$ROUTER_JOB_CONFIG"
echo "Updated vm_extensions property for $ROUTER_JOB_GUID"

om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$TCP_ROUTER_JOB_GUID/resource\_config" \
  -x PUT \
  -H "Content-Type: application/json" \
  -d "$TCP_ROUTER_JOB_CONFIG"
echo "Updated vm_extensions property for $TCP_ROUTER_JOB_GUID"

om --env env/"${ENV_FILE}" -k \
  curl -s -p "$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$DIEGO_BRAIN_JOB_GUID/resource\_config" \
  -x PUT \
  -H "Content-Type: application/json" \
  -d "$DIEGO_BRAIN_JOB_CONFIG"
echo "Updated vm_extensions property for $DIEGO_BRAIN_JOB_GUID"