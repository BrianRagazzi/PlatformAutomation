#!/bin/bash

OPS_MAN_FQDN=om.pas.ragazzilab.com
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

curl -k "https://$OPS_MAN_FQDN/api/v0/staged/vm_extensions" \
-X POST \
-H "Authorization: Bearer $(cat ./token)" \
-H "Content-Type: application/json" \
-d "$web_json)"

curl -k "https://$OPS_MAN_FQDN/api/v0/staged/vm_extensions" \
-X POST \
-H "Authorization: Bearer $(cat ./token)" \
-H "Content-Type: application/json" \
-d "$ssh_json)"

curl -k "https://$OPS_MAN_FQDN/api/v0/staged/vm_extensions" \
-X POST \
-H "Authorization: Bearer $(cat ./token)" \
-H "Content-Type: application/json" \
-d "$tcp_json)"

curl -k "https://$OPS_MAN_FQDN/api/v0/staged/vm_extensions" \
-X GET \
-H "Authorization: Bearer $(cat ./token)" | jq

CF_GUID=$(
  curl -k "https://$OPS_MAN_FQDN/api/v0/staged/products" \
    -H "Authorization: Bearer $(cat ./token)" | \
    jq -r '.[] | .installation_name' | grep cf- | tail -1
)

ROUTER_JOB_GUID=$(
  curl -k "https://$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs" \
    -H "Authorization: Bearer $(cat ./token)" | \
    jq | jq -r '.jobs[] | .guid' | grep ^router
)


ROUTER_JOB_CONFIG=$(
  curl -k "https://$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$ROUTER_JOB_GUID/resource_config" \
    -H "Authorization: Bearer $(cat ./token)" | \
    jq -r '. += {"additional_vm_extensions": "pcf_web_vm_extension"}'
)

TCP_ROUTER_JOB_GUID=$(
  curl -k "https://$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs" \
    -H "Authorization: Bearer $(cat ./token)" | \
    jq | jq -r '.jobs[] | .guid' | grep ^tcp
)

TCP_ROUTER_JOB_CONFIG=$(
curl -k "https://$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$TCP_ROUTER_JOB_GUID/resource\_config" \
  -H "Authorization: Bearer $(cat ./token)" | \
  jq -r '. += {"additional_vm_extensions": "pcf_tcp_vm_extension"}'
)

DIEGO_BRAIN_JOB_GUID=$(
  curl -k "https://$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs" \
    -H "Authorization: Bearer $(cat ./token)" | \
    jq | jq -r '.jobs[] | .guid' | grep ^diego\_brain
)

DIEGO_BRAIN_JOB_CONFIG=$(
curl -k "https://$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$DIEGO_BRAIN_JOB_GUID/resource\_config" \
  -H "Authorization: Bearer $(cat ./token)" | \
  jq -r '. += {"additional_vm_extensions": "pcf_ssh_vm_extension"}'
)

curl -k "https://$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$ROUTER_JOB_GUID/resource\_config" \
  -X PUT \
  -H "Authorization: Bearer $(cat ./token)" \
  -H "Content-Type: application/json" \
  -d "$ROUTER_JOB_CONFIG"
echo "Updated vm_extensions property for $ROUTER_JOB_GUID"

curl -k "https://$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$TCP_ROUTER_JOB_GUID/resource\_config" \
  -X PUT \
  -H "Authorization: Bearer $(cat ./token)" \
  -H "Content-Type: application/json" \
  -d "$TCP_ROUTER_JOB_CONFIG"
echo "Updated vm_extensions property for $TCP_ROUTER_JOB_GUID"


curl -k "https://$OPS_MAN_FQDN/api/v0/staged/products/$CF_GUID/jobs/$DIEGO_BRAIN_JOB_GUID/resource\_config" \
  -X PUT \
  -H "Authorization: Bearer $(cat ./token)" \
  -H "Content-Type: application/json" \
  -d "$DIEGO_BRAIN_JOB_CONFIG"
echo "Updated vm_extensions property for $DIEGO_BRAIN_JOB_GUID"
