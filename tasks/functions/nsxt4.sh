# Collection of functions that work with NSX-T 4.2.x API to perform actions


Get_NSX_T1_Gateway_Path() {
 # $1 - T1 Router name
 # Returns Path
 local t1path=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/policy/api/v1/infra/tier-1s | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.resource_type == "Tier1") | .path')
   echo $t1path
}

Get_NSX_T0_Gateway_Path() {
  # $1 T0 Name
  local t0path=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/policy/api/v1/infra/tier-0s | \
    jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.resource_type == "Tier0") | .path')
 echo $t0path
}

Get_NSX_TransportZone_Path() {
  # $1 - tzname
  # $2 SiteID - defaults to "default"
  # $3 enforcementpointid - defaults to "default"
  local siteid="${2:-default}"
  local enforcementpointid="${3:-default}"
  local tzname="${1:-nsx-overlay-transportzone}"
  local tzid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/policy/api/v1/infra/sites/$siteid/enforcement-points/$enforcementpointid/transport-zones | \
    jq -r --arg name "$tzname" '.results[] | select(.display_name == $name) | .path')
  echo $tzid
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

Get_NSX_Segment_ID() {
  # $1 Segment Name
  local segmentname=$1
  local segmentid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/policy/api/v1/infra/segments| \
    jq -r --arg name "$segmentname" '.results[] | select(.display_name == $name) | .id')
  echo $segmentid
}

Get_NSX_IP_Pool_ID() {
  # $1 Pool Name
  local pool_name=$1
  local poolid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/policy/api/v1/infra/ip-pools| \
    jq -r --arg name "$pool_name" '.results[] | select(.display_name == $name) | .id')
  echo $poolid
}

Get_NSX_IP_Block_ID() {
  # $1 Block Name
  local block_name=$1
  local blockid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/policy/api/v1/infra/ip-blocks| \
    jq -r --arg name "$block_name" '.results[] | select(.display_name == $name) | .id')
  echo $blockid
}

Get_NSX_Tier0_NAT_Rule_ID() {
  # $1 Rule Name
  # $2 Tier0 Gatewway Name
  # Specifically USER NAT rules
  local name=$1
  local t0id=$2
  local id=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/policy/api/v1/infra/tier-0s/$t0id/nat/USER/nat-rules| \
    jq -r --arg name "$name" '.results[] | select(.display_name == $name) | .id')
  echo $id
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
  local chk=$(Get_NSX_T1_Gateway_Path $1)

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
  local t1_path=$(Get_NSX_T1_Gateway_Path "$t1_name")
  if [ -z "$t1_path" ]; then
    echo "Error: Tier-1 gateway '$t1_name' not found"
  else
    #Delete attachmento to edgecluster
    curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/policy/api/v1/infra/tier-1s/$t1_name/locale-services/default -X DELETE

     # Delete T1
    local response=$(curl -s -k -X DELETE \
    -H "Content-Type: application/json" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    -w "%{http_code}" \
    "$NSXHOSTNAME/policy/api/v1$t1_path") #Note t1_pathc begins with "/"

    # Extract the HTTP status code
    local http_code=$(echo "$response" | tail -n1)

    # Check the response status
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 204 ]; then
      echo "Successfully deleted Tier-1 gateway: $t1_name"
    else
      echo "Failed to delete Tier-1 gateway: $t1_name"
      echo "HTTP Status: $http_code"
      echo "Response: $(echo "$response" | sed '$d')"
      return 1
    fi
  fi
}

Create_NSX_Segment() {
 # $1 - Segment name
 # $2 - Transport Zone Name
 # $3 - Gateway
 # $4 - Subnet - gateway address
 # $5 - Subnet - CIDR
 # Note: Assumes default SiteID and EnforementPointID
 # Refactored April 2025
  local segment_name="$1"
  local transport_zone="$2"
  local gateway_name="$3"
  local segment_gateway_address="$4"
  local segment_network_id="$5"
  local chk=$(Get_NSX_Segment_ID $1)
  if [ -n "$chk" ]; then
   echo Logical Switch $1 already exists, skipping
  else
   echo "Creating $1"

   local tz_path=$(Get_NSX_TransportZone_Path $transport_zone)
   local t1_path=$(Get_NSX_T1_Gateway_Path "$gateway_name")

   local payload=$(jq -n \
        --arg name "$segment_name" \
        --arg tz "${tz_path}" \
        --arg t1 "$t1_path" \
        --arg gw "$segment_gateway_address" \
        --arg net "$segment_network_id" \
        '{
            "display_name": $name,
            "transport_zone_path": $tz,
            "connectivity_path": $t1,
            "advanced_config": {
                "connectivity": "ON"
            },
            "subnets": [
                {
                    "gateway_address": $gw,
                    "network": $net
                }
            ],
            "admin_state": "UP"
        }')
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/policy/api/v1/infra/segments/${segment_name} \
     -X PATCH -d "$payload"
  fi
}

Delete_NSX_Segment() {
  # $1 Segment Name
  local seg_name="$1"
  local chk=$(Get_NSX_Segment_ID $seg_name)

  if [ -z "$chk" ]; then
   echo "Error: Segment '$1' not found"
  else
   # Delete segment
   local response=$(curl -s -k -X DELETE \
   -H "Content-Type: application/json" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   -w "%{http_code}" \
   "$NSXHOSTNAME/policy/api/v1/infra/segments/$seg_name") #Note t1_pathc begins with "/"

   # Extract the HTTP status code
   local http_code=$(echo "$response" | tail -n1)

   # Check the response status
   if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 204 ]; then
     echo "Successfully deleted Segment: $seg_name"
   else
     echo "Failed to delete Segment: $seg_name"
     echo "HTTP Status: $http_code"
     echo "Response: $(echo "$response" | sed '$d')"
     return 1
   fi
 fi
}

Create_NSX_IP_Pool() {
  # $1 pool name
  # $2 CIDR
  # $3 Gateway Address
  # $4 IP Range xxx.xxx.xxx.xxx-yyy.yyy.yyy.yyy
  # $5 DNS Servers [xxx.xxx.xxx.xxx,aaa.bbb.ccc.ddd]
  # $6 Description
  local pool_name="$1"
  local cidr="$2"
  local gw_address="$3"
  local ip_range="$4"
  local dns_servers="$5"
  local desc="$6"
  # Create Pool
  # /policy/api/v1/infra/ip-pools/{ip-pool-id}
  # Create Subnet
  # /policy/api/v1/infra/ip-pools/{ip-pool-id}/ip-subnets/{ip-subnet-id} PATCH
  # /policy/api/v1/infra/ip-pools/{ip-pool-id}/ip-subnets/{ip-subnet-id} PUT
  local chk=$(Get_NSX_IP_Pool_ID $pool_name)
  if [ -n "$chk" ]; then
   echo IP Pool $1 already exists, skipping
  else
    echo "Creating $1"
    local pool_config=$(jq -n \
        --arg display_name "$pool_name" \
        --arg desc "$desc" \
    '{
    "resource_type": "IpAddressPool",
    "display_name": $display_name,
    "ip_address_type": "IPV4",
    "description": $desc,
    }')

    curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
      -u $NSXUSERNAME:$NSXPASSWORD \
      $NSXHOSTNAME/policy/api/v1/infra/ip-pools/$pool_name \
      -X PATCH -d "$pool_config"

    echo "Creating Subnet $cidr for pool $pool_name"
    # range start/end using awk
    range_start=$(echo "$ip_range" | awk -F'-' '{print $1}')
    range_end=$(echo "$ip_range" | awk -F'-' '{print $2}')

    # Using sed
    #range_start=$(echo "$ip_range" | sed 's/-.*//')
    #range_end=$(echo "$ip_range" | sed 's/.*-//')

    local subnet_config=$(jq -n \
        --arg range_start "$range_start" \
        --arg range_end "$range_end" \
        --arg cidr "$cidr" \
        --arg gateway_ip "$gw_address" \
        --argjson dns_servers "$dns_servers" \
    '{
    "resource_type": "IpAddressPoolStaticSubnet",
    "allocation_ranges": [
      {
          "start": $range_start,
          "end": $range_end
         }
      ],
    "cidr": $cidr,
    "gateway_ip": $gateway_ip,
    "dns_nameservers": $dns_servers
    }')

  curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/policy/api/v1/infra/ip-pools/$pool_name/ip-subnets/default \
    -X PATCH -d "$subnet_config"
  fi
}

Delete_NSX_IP_Pool() {
  # $1 pool name
  local pool_name="$1"
  local chk=$(Get_NSX_IP_Pool_ID $pool_name)

  if [ -z "$chk" ]; then
   echo "Error: IP Pool '$1' not found"
  else
    # Delete subnets:
    # /policy/api/v1/infra/ip-pools/{ip-pool-id}/ip-subnets/{ip-subnet-id}
    Delete_NSX_IP_Pool_Subnets $pool_name
    #DELETE /policy/api/v1/infra/ip-pools/{ip-pool-id}
    # Delete segment
    local response=$(curl -s -k -X DELETE \
    -H "Content-Type: application/json" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    -w "%{http_code}" \
    "$NSXHOSTNAME/policy/api/v1/infra/ip-pools/$pool_name") #Note t1_pathc begins with "/"

    # Extract the HTTP status code
    local http_code=$(echo "$response" | tail -n1)

    # Check the response status
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 204 ]; then
      echo "Successfully deleted IP Pool: $pool_name"
    else
      echo "Failed to delete IP Pool: $pool_name"
      echo "HTTP Status: $http_code"
      echo "Response: $(echo "$response" | sed '$d')"
      return 1
    fi
  fi
}

Delete_NSX_IP_Pool_Subnets(){
  # $1 Pool Name
  local pool_name="$1"
  # loop through each subnet, delete each
  local subnetids=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/policy/api/v1/infra/ip-pools/$pool_name/ip-subnets | \
    jq -r --arg name "$1" '.results[] | .id')
  for subnet in $subnetids
    do
      echo "Deleting Subnet: $subnet"
      curl -s -k -X DELETE -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
        -u $NSXUSERNAME:$NSXPASSWORD \
        $NSXHOSTNAME/policy/api/v1/infra/ip-pools/$pool_name/ip-subnets/$subnet
    done
    # policy/api/v1/infra/ip-pools/{ip-pool-id}/ip-subnets/{ip-subnet-id}


}

Create_NSX_IP_Block() {
  # $1 block name
  # $2 CIDR
  # $3 Description
  local block_name="$1"
  local cidr="$2"
  local desc="$3"
  local chk=$(Get_NSX_IP_Block_ID $block_name)
  if [ -n "$chk" ]; then
   echo IP Block $1 already exists, skipping
  else
    echo "Creating $block_name with $cidr"
    local config=$(jq -n \
        --arg display_name "$block_name" \
        --arg cidr "$cidr" \
        --arg desc "$desc" \
    '{
    "resource_type": "IpAddressBlock",
    "display_name": $display_name,
    "ip_address_type": "IPV4",
    "description": $desc,
    "cidr": $cidr
    }')

    curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
      -u $NSXUSERNAME:$NSXPASSWORD \
      $NSXHOSTNAME/policy/api/v1/infra/ip-blocks/$block_name \
      -X PATCH -d "$config"
  fi
}

Delete_NSX_IP_Block() {
  # $1 block name
  local block_name="$1"
  local chk=$(Get_NSX_IP_Block_ID $block_name)

  if [ -z "$chk" ]; then
   echo "Error: IP block '$1' not found"
  else
    local response=$(curl -s -k -X DELETE \
    -H "Content-Type: application/json" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    -w "%{http_code}" \
    "$NSXHOSTNAME/policy/api/v1/infra/ip-blocks/$block_name") #Note t1_pathc begins with "/"

    # Extract the HTTP status code
    local http_code=$(echo "$response" | tail -n1)

    # Check the response status
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 204 ]; then
      echo "Successfully deleted IP block: $block_name"
    else
      echo "Failed to delete IP block: $block_name"
      echo "HTTP Status: $http_code"
      echo "Response: $(echo "$response" | sed '$d')"
      return 1
    fi
  fi
}

Create_NSX_T0_NAT_Rule(){
  # $1 - nat rule name
  # $2 - Tier 0 Name
  # $3 - action (DNAT, SNAT)
  # $4 - source net
  # $5 - translated net
  # $6 - destination net
  local name="$1"
  local t0id="$2"
  local action="$3"
  local source_net="$4"
  local trans_net="$5"
  local dest_net="$6"
  # check for any
  [[ "$source_net" == "Any" ]] && source_net=""
  [[ "$trans_net" == "Any" ]] && trans_net=""
  [[ "$dest_net" == "Any" ]] && dest_net=""

  local chk=$(Get_NSX_Tier0_NAT_Rule_ID $name $t0id)
  if [ -n "$chk" ]; then
   echo NAT Rule $1 already exists, skipping
  else
    echo "Creating NAT Rule $name on $t0id"
    local config=$(jq -n \
        --arg display_name "$name" \
        --arg action "$action" \
        --arg source "$source_net" \
        --arg trans "$trans_net" \
        --arg dest "$dest_net" \
    '{
    "resource_type": "PolicyNatRule",
    "display_name": $display_name,
    "action": $action,
    "source_network": $source,
    "destination_network": $dest,
    "translated_network": $trans,
    "firewall_match": "BYPASS",
    "enabled": true
    }')

    curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
      -u $NSXUSERNAME:$NSXPASSWORD \
      $NSXHOSTNAME/policy/api/v1/infra/tier-0s/$t0id/nat/USER/nat-rules/$name\
      -X PATCH -d "$config"
  fi
#/policy/api/v1/infra/tier-0s/{tier-0-id}/nat/{nat-id}/nat-rules/{nat-rule-id}
}

Delete_NSX_T0_NAT_Rule(){
  # $1 - nat rule name
  # $2 - Tier 0 Name
  local name="$1"
  local t0id="$2"
  local chk=$(Get_NSX_Tier0_NAT_Rule_ID $name $t0id)
  if [ -z "$chk" ]; then
   echo "Error: T0 NAT Rule $1 not found"
  else
    local response=$(curl -s -k -X DELETE \
    -H "Content-Type: application/json" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    -w "%{http_code}" \
    "$NSXHOSTNAME/policy/api/v1/infra/tier-0s/$t0id/nat/USER/nat-rules/$name") #Note t1_pathc begins with "/"

    # Extract the HTTP status code
    local http_code=$(echo "$response" | tail -n1)

    # Check the response status
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 204 ]; then
      echo "Successfully deleted NAT Rule: $name"
    else
      echo "Failed to delete NAT Rule: $name"
      echo "HTTP Status: $http_code"
      echo "Response: $(echo "$response" | sed '$d')"
      return 1
    fi
  fi

}


Get_TKGI_SuperUser_ID(){
  # $1 = superuser_name
  # $2 = NSX_SUPERUSER_CERT_FILE path
  local pi_name="$1"
  local cert_pem="$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ./"$2" )" #leaves spacs
  #local cert_pem="$(cat ./"$2" | tr -d ' \t\r' | awk '{printf "%s\\n", $0}')" #Leaves "\\n"
  #local cert_pem="$(cat ./"$2" | tr -d ' \t\r\n')"
  local certid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/api/v1/trust-management/principal-identities | \
    jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')

  if [ -z "$certid" ]; then
    #local NODE_ID=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
    local pi_request=$(jq -n \
        --arg display_name "$pi_name" \
        --arg cert_pem "$cert_pem" \
        --arg node_id $(cat /proc/sys/kernel/random/uuid | sed 's/-//g') \
        '{
        "display_name": $display_name,
        "name": $display_name,
        "role": "enterprise_admin",
        "roles_for_paths": [{"path": "/","roles": [{"role": "enterprise_admin"}]}],
        "certificate_pem": $cert_pem,
        "node_id": $node_id
        }')
      curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
        -u $NSXUSERNAME:$NSXPASSWORD \
        $NSXHOSTNAME/api/v1/trust-management/principal-identities/with-certificate \
        -X POST -d "$pi_request"
      certid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
        -u $NSXUSERNAME:$NSXPASSWORD \
        $NSXHOSTNAME/api/v1/trust-management/principal-identities | \
        jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')
  else
    echo "Principal ID for $1 already exists in NSX, skipping creation"
  fi
  echo $certid
}

Delete_TKGI_SuperUser_ID() {
  # $1 = superuser_name
  local pi_name="$1"
  local certid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/api/v1/trust-management/principal-identities | \
    jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')
  if [ -z "$certid" ]; then
    echo "Principal ID for $pi_name is not found, skipping"
  else
    local response=$(curl -s -k -X DELETE \
    -H "Content-Type: application/json" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    -w "%{http_code}" \
    "$NSXHOSTNAME/api/v1/trust-management/principal-identities/$certid")

    # Extract the HTTP status code
    local http_code=$(echo "$response" | tail -n1)

    # Check the response status
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 204 ]; then
      echo "Successfully deleted PI: $pi_name"
    else
      echo "Failed to delete PI: $pi_name"
      echo "HTTP Status: $http_code"
      echo "Response: $(echo "$response" | sed '$d')"
      return 1
    fi
  fi
}
