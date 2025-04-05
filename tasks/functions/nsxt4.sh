# Collection of functions that work with NSX-T 4.2.x API to perform actions


Get_NSX_T1_Gateway() {
 # $1 - T1 Router name
 local t1id=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/policy/api/v1/infra/tier-1s | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.resource_type == "Tier1") | .id')
   echo $t1id
}

Get_NSX_T0_Gateway_Path() {
  # $1 T0 Name
  local t0path=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/policy/api/v1/infra/tier-0s | \
    jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.resource_type == "Tier0") | .path')
 echo $t0path
}

Get_NSX_EdgeCluster_Path() {
  # $1 Edgecluster Name
  # $2 SiteID - defaults to "default"
  # $3 enforcementpointid - defaults to "default"
  local siteid="${2:-default}"
  local enforcementpointid="${3:-default}"
  local ecpath=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/policy/api/v1/infra/sites/$siteid/enforcement-points/$enforcementpointid/edge-clusters | \
    jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.resource_type == "PolicyEdgeCluster") | .path')
  echo $ecpath
}


Create_NSX_T1_Gateway() {
  # $1 - T1 Router name
  # $2 - T0 to attach to
  # $3 - edgecluster_name
  # $4 - route_adv_types - optional
  # $5 - description - optional
  # $6 - ha_mode - optional
  # $7 - pool allocation - optional
  local routeadv=${4:-'["TIER1_NAT","TIER1_LB_VIP","TIER1_CONNECTED","TIER1_IPSEC_LOCAL_ENDPOINT"]'} # NOT WORKING
  local desc="${5:-'Created via automation'}"
  local ha_mode="${6:-ACTIVE_STANDBY}"
  local pool_alloc="${7:-ROUTING}"
  local chk=$(Get_NSX_T1_Gateway $1)

  if [ -n "$chk" ]; then
   echo Logical Router $1 already exists, skipping
  else
   echo "Creating $1"
   local t0path=$(Get_NSX_T0_Gateway_Path $2)
   #local routeadv='["TIER1_NAT","TIER1_LB_VIP","TIER1_CONNECTED","TIER1_IPSEC_LOCAL_ENDPOINT"]'
   gateway_config=$(jq -n \
     --arg display_name "$1" \
     --arg t0path "$t0path" \
     --argjson route_advertisement_types $routeadv \
     --arg desc "$desc" \
     --arg ha_mode "$ha_mode" \
     --arg pool_allocation "$pool_alloc" \
     '
     {
      "display_name": $display_name,
      "resource_type": "Tier1",
      "tier0_path": $t0path,
      "description": $desc,
      "ha_mode": $ha_mode,
      "pool_allocation": $pool_allocation,
      "failover_mode": "NON_PREEMPTIVE",
      "route_advertisement_types": $route_advertisement_types
     }
     '
     )
    # Create Gateway
    curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/policy/api/v1/infra/tier-1s/$1 -X PATCH -d "$gateway_config"

     # Attach to edge cluster
    # https://developer.broadcom.com/xapis/nsx-t-data-center-rest-api/latest/method_PatchTier1LocaleServices.html
    local ec_path=$(Get_NSX_EdgeCluster_Path $3)
    locale_services_config=$(jq -n \
      --arg ec_path "$ec_path" \
      '
      {
        "edge_cluster_path": $ec_path
      }
      '
      )
      curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
       -u $NSXUSERNAME:$NSXPASSWORD \
       $NSXHOSTNAME/policy/api/v1/infra/tier-1s/$1/locale-services/default -X PATCH -d "$locale_services_config"


    #  # Check the response status
    # local http_code=$(echo "$response" | tail -n1)
    # if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 204 ]; then
    #   echo "Successfully Created Tier-1 gateway: $display_name"
    # else
    #   echo "Failed to create Tier-1 gateway: $display_name"
    #   echo "HTTP Status: $http_code"
    #   echo "Response: $(echo "$response" | sed '$d')"
    #   return 1
    # fi


  #Create Logical Router Port on T0
  #Create a link Logical Router Port on new T1 to T0
  #Connect_NSX_T1T0 $2 $1
  #Enable_Route_Advertisement_T1 $1
  fi
}


Delete_NSX_T1_Gateway() {
  # $1 - T1 Router name to delete
  local t1_name="$1"
  local t1_id=$(Get_NSX_T1_Gateway "$t1_name")
  if [ -z "$t1_id" ]; then
    echo "Error: Tier-1 gateway '$t1_name' not found"
  else
    #Delete attachmento to edgecluster
    curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/policy/api/v1/infra/tier-1s/$1/locale-services/default -X DELETE

     # Delete T1
    local response=$(curl -s -k -X DELETE \
    -H "Content-Type: application/json" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    -w "%{http_code}" \
    "$NSXHOSTNAME/policy/api/v1/infra/tier-1s/$t1_id")

    # Extract the HTTP status code
    local http_code=$(echo "$response" | tail -n1)

    # Check the response status
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 204 ]; then
      echo "Successfully deleted Tier-1 gateway: $t1_name (ID: $t1_id)"
    else
      echo "Failed to delete Tier-1 gateway: $t1_name (ID: $t1_id)"
      echo "HTTP Status: $http_code"
      echo "Response: $(echo "$response" | sed '$d')"
      return 1
    fi
  fi
}
