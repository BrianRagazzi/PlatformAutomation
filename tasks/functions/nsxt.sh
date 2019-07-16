# Collection of functions that work with NSX-T API to perform actions

Create_NSX_LB_Monitor() {
 # $1 - Monitor Name ex:  pas-web-monitor
 # $2 - Monitor Port ex:  443
 # $3 - Monitor Protocol ex:  LbHttpMonitor, LbTcpMonitor
 # $4 - URL to monitor ex:  /health
 ##################################################################
 ### Creates the Requested Monitor if it does not already exist ###
 ##################################################################
 local monchk=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/loadbalancer/monitors | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')
   #'.results[].display_name' | grep "$1")
   #jq -r '.results[] | select(.display_name == "$1") | .id')
 #echo monchk: $monchk
 if [ -n "$monchk" ]; then
   echo Monitor $1 already exists, skipping
 else
   echo "Creating $1"

   monitor_config=$(
     jq -n \
       --arg monitor_name "$1" \
       --arg monitor_port "$2" \
       --arg monitor_protocol "$3" \
       --arg monitor_url "$4" \
       '{
        "monitor_port": $monitor_port,
        "fall_count": 1,
        "interval": 1,
        "rise_count": 1,
        "timeout": 1,
        "resource_type": $monitor_protocol,
        "display_name": $monitor_name,
        "description": $monitor_name
       }
       +
       if $monitor_protocol == "LbHttpMonitor" then
       {
        "request_method": "GET",
        "response_status_codes": [200],
        "request_version": "HTTP_VERSION_1_1",
        "request_url": $monitor_url
       }
       elif $monitor_protocol == "LbHttpsMonitor" then
       {
        "request_method": "GET",
        "response_status_codes": [200],
        "request_version": "HTTP_VERSION_1_1",
        "request_url": $monitor_url
       }
       else .
       end
       '
   )

   #echo $monitor_config
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/monitors \
     -X POST -d "$monitor_config"
fi
}

Create_NSX_LB_ServerPool() {
 # $1 - Server Pool Name ex:  pas-web-pool
 # $2 - Monitor Name ex:  pas-web-monitor
 # $3 - Translation mode (LbSnatAutoMap or Transparent)
 ######################################################################
 ### Creates the Requested Server Pool if it does not already exist ###
 ######################################################################
 local chk=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/loadbalancer/pools | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')

 if [ -n "$chk" ]; then
   echo Pool $1 already exists, skipping
 else
   echo "Creating $1"

   local monid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/monitors | \
     jq -r --arg name "$2" '.results[] | select(.display_name == $name) | .id')

   pool_config=$(
     jq -n \
     --arg pool_name "$1" \
     --arg monid "$monid" \
     --arg translation_mode "$3" \
     '
     {
       "display_name": $pool_name,
       "min_active_members": 1,
       "tcp_multiplexing_number": 6,
       "active_monitor_ids": [ $monid ],
       "tcp_multiplexing_enabled": false,
       "algorithm": "ROUND_ROBIN"
     }
     +
     if $translation_mode == "LbSnatAutoMap" then
     {
      "snat_translation": {
        "port_overload": 32,
        "type": "LbSnatAutoMap"
        }
     }
     else .
     end
     '
   )

   echo $pool_config

   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/pools \
     -X POST -d "$pool_config"

 fi

}

Create_NSX_LB_VirtualServer() {
 # $1 - Virtual Server Name ex:  pas-web-vs
 # $2 - Server Pool Name ex:  pas-web-pool
 # $3 - Virtual Server Port ex:  443
 # $4 - Virtual Server IP address ex:  192.168.105.22
 ##################################################################
 ###  Creates the Virtual Server if it does not already exist   ###
 ##################################################################
 local chk=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/loadbalancer/virtual-servers | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')

 if [ -n "$chk" ]; then
   echo Virtual Server $1 already exists, skipping
 else
   echo "Creating $1"
   #get applicatgion Profile named "nsx-default-lb-fast-tcp-profile"
   local poolid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/pools | \
     jq -r --arg name "$2" '.results[] | select(.display_name == $name) | .id')

   local profid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/application-profiles | \
     jq -r --arg name "$2" '.results[] | select(.display_name == "nsx-default-lb-fast-tcp-profile") | .id')

   vs_config=$(
     jq -n \
       --arg vs_name "$1" \
       --arg vs_pool "$2" \
       --arg vs_port "$3" \
       --arg vs_ip "$4" \
       --arg vs_pool_id "$poolid" \
       --arg vs_appprofileid "$profid" \
       '
       {
         "display_name": $vs_name,
         "ip_address": $vs_ip,
         "ports": [ $vs_port ],
         "pool_id": $vs_pool_id,
         "enabled": true,
         "ip_protocol": "TCP",
         "default_pool_member_ports": [ $vs_port ],
         "default_pool_member_port": $vs_port,
         "port": $vs_port,
         "access_log_enabled": false,
         "application_profile_id": $vs_appprofileid
       }
       '
   )

   echo $vs_config
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/virtual-servers \
     -X POST -d "$vs_config"
 fi

}

Create_NSX_LoadBalancer() {
 # $1 - Load Balancer Name ex:  pas-lb
 # $2 - T1 router Name  ex:  t1-pas
 # $3 - Virtual Server Names to bind to ex: pas-web-vs,pas-tcp-vs,pas-ssh-vs
 ##################################################################
 ###   Creates the Load Balancer if it does not already exist   ###
 ##################################################################
 local chk=$(curl -s -k -H "Content-Type: Application/xml" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/loadbalancer/services | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')
 if [ -n "$chk" ]; then
   echo LB $1 already exists, skipping
 else
   echo "Creating $1"
   #identify virtual servers
   #identify logical router for
   local t1_routerid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-routers | \
     jq -r --arg name "$2" '.results[] | select(.display_name == $name) | .id')

   lb_config=$(
     jq -n \
       --arg lb_name "$1" \
       --arg t1_routerid "$t1_routerid" \
       '
       {
         "display_name": "pas-lb",
         "size": "SMALL",
         "attachment": {"target_id": $t1_routerid},
         "error_log_level": "INFO",
         "access_log_enabled": false,
         "virtual_server_ids": [],
         "enabled": true
       }
       '
   )

   for vs_name in ${3//,/ }
   do
     #vs_names = "${vs_name},"
     #echo "Need to add $vs_name"
     vsid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/virtual-servers | \
     jq -r --arg name "$vs_name" '.results[] | select(.display_name == $name) | .id')
     lb_config=$(echo $lb_config | \
     jq -r --arg vsid $vsid '.virtual_server_ids[.virtual_server_ids|length] += $vsid')
   done

   #echo $lb_config
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/services \
     -X POST -d "$lb_config"

 fi
}

Create_NSX_LogicalSwitch() {
 # $1 - Logical Switch name
 # $2 - Transport Zone Name
 local chk=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-switches | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')
 if [ -n "$chk" ]; then
   echo Logical Switch $1 already exists, skipping
 else
   echo "Creating $1"

   local tzid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/transport-zones | \
     jq -r --arg name "$2" '.results[] | select(.display_name == $name) | .id')


   switch_config=$(
     jq -n \
       --arg switch_name "$1" \
       --arg transport_zone_id "$tzid" \
       '
       {
        "transport_zone_id": $transport_zone_id,
        "replication_mode": "MTEP",
        "admin_state":"UP",
        "display_name": $switch_name
       }
       '
   )

   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-switches \
     -X POST -d "$switch_config"
 fi
}

Create_NSX_LogicalSwitchPortforT1() {
 # $1 Logical Switch Name
 # $2 T1 Router Name
 # Called in-line, do not add echos
 local display_name="$2"-"$1"
 local lsid=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-switches | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')

   if [ -z "$lsid" ]; then
     #echo "Logical Switch $1 Does not exist, cannot proceed"
     return 1
   fi

 local chk=$(curl -s -k -H "Content-Type: Application/xml" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-ports?logical_switch_id=$lsid | \
   jq -r --arg name "$display_name" '.results[] | select(.display_name == $name)| .id')

 if [ -n "$chk" ]; then
   #echo Logical Switch Port named $display_name already exists, skipping
   echo $chk
 else
   #echo "Creating $display_name"

   lsp_config=$(
     jq -n \
     --arg lsp_name "$display_name" \
     --arg logical_switch_id "$lsid" \
     '
     {
       "logical_switch_id": $logical_switch_id,
       "display_name": $lsp_name,
       "description" : "Created by script",
       "admin_state": "UP"
     }
     '
   )
  #echo $lsp_config

   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-ports \
     -X POST -d "$lsp_config" > /dev/null

   #sleep 5
   local lsp_id=$(curl -s -k -H "Content-Type: Application/xml" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-ports?logical_switch_id=${lsid} | \
     jq -r --arg name "$display_name" '.results[] | select(.display_name == $name) | .id')

   # this could be null...
   # Issue one call to create and a second to retrieve
   echo $lsp_id
 fi
}

Create_NSX_T1Router() {
 # $1 - T1 Router name
 # $2 - T0 to attach to
 # $3 - Edge Cluster Name
 local chk=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-routers | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.router_type == "TIER1") | .id')

 if [ -n "$chk" ]; then
   echo Logical Router $1 already exists, skipping
 else
   echo "Creating $1"
   local t0id=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-routers | \
     jq -r --arg name "$2" '.results[] | select(.display_name == $name) | select(.router_type == "TIER0") | .id')
   if [ -n "$3" ]; then
    local ecid=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
      -u $NSXUSERNAME:$NSXPASSWORD \
      $NSXHOSTNAME/api/v1/edge-clusters | \
      jq -r --arg name "$3" '.results[] | select(.display_name == $name) | .id')
      local useedgecluster="true"
   else
     echo "Not binding to an edgecluster"
     local useedgecluster="false"
     local ecid=""
   fi

   router_config=$(
     jq -n \
     --arg router_name "$1" \
     --arg edge_cluster_id "$ecid" \
     --arg use_edge_cluster ${useedgecluster:-"false"} \
     '
     {
      "display_name": $router_name,
      "router_type": "TIER1",
     }
     +
     if $use_edge_cluster == "true" then
     {
      "edge_cluster_id": $edge_cluster_id
     }
     else .
     end
     '
   )

   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-routers \
     -X POST -d "$router_config"

   #Create Logical Router Port on T0
   #Create a link Logical Router Port on new T1 to T0
   Connect_NSX_T1T0 $2 $1
   Enable_Route_Advertisement_T1 $1
 fi
}

Create_NSX_IP_Pool() {
 # $1 - Name
 # $2 - CIDR
 # $3 - Description
 # $4 - Gateway address
 # $5 - Allocation Range ex: 192.168.1.20-192.168.1.40
 # $6 - DNS Servers (Comma separated, optional)
 local chk=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/pools/ip-pools | \
   jq -r --arg cidr $2 '.results[].subnets[] | select(.cidr == $cidr) | .id')
 if [ -n "$chk" ]; then
   echo Pool with CIDR $2 already exists, skipping
 else
   echo "Creating IP Pool $1"
   local range_start=$(echo $5 | cut -d "-" -f1)
   local range_end=$(echo $5 | cut -d "-" -f2)
   local dns_server1=$(echo $6 | cut -d "," -f1)
   local dns_server2=$(echo $6 | cut -d "," -f2)
   pool_config=$(
     jq -n \
     --arg display_name "$1" \
     --arg cidr "$2" \
     --arg desc "$3" \
     --arg gateway "$4" \
     --arg range_start "$range_start" \
     --arg range_end "$range_end" \
     --arg dns_server1 "$dns_server1" \
     --arg dns_server2 "$dns_server2" \
     '
     {
      "display_name": $display_name,
      "description": $desc
     }
     +
     if $dns_server1 != "" then
     {
      "subnets": [
        {
         "allocation_ranges": [
            {
             "start": $range_start,
             "end": $range_end
            }],
         "gateway_ip": $gateway,
         "cidr": $cidr,
         "dns_nameservers": [ $dns_server1,$dns_server2 ]
        }]
     }
     else
     {
      "subnets": [
        {
         "allocation_ranges": [
            {
             "start": $range_start,
             "end": $range_end
            }],
         "gateway_ip": $gateway,
         "cidr": $cidr
        }]
     }
     end
     '
   )
   echo $pool_config
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/pools/ip-pools \
     -X POST -d "$pool_config"
 fi
}

Create_NSX_IP_Block() {
 # $1 - Name
 # $2 - CIDR
 # $3 - Description
 local chk=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/pools/ip-blocks | \
   jq -r --arg cidr $2 '.results[] | select(.cidr == $cidr) | .id')
 if [ -n "$chk" ]; then
   echo Block with CIDR $2 already exists, skipping
 else
   echo "Creating IP Block $1"
   block_config=$(
     jq -n \
     --arg display_name "$1" \
     --arg cidr "$2" \
     --arg desc "$3" \
     '
     {
      "display_name": $display_name,
      "description": $desc,
      "cidr": $cidr
     }
     '
   )
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/pools/ip-blocks \
     -X POST -d "$block_config"
 fi
}

Create_NSX_T1DownlinkPort() {
 # $1 - Router name
 # $2 - Downlink Logical Switch Name
 # $3 - Router POrt CIDR Address
 local t1id=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-routers | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.router_type == "TIER1") | .id')

 if [ -z "$t1id" ]; then
   echo "Router $1 does not exist, cannot proceed"
   return 1
 fi

 local lsid=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-switches | \
   jq -r --arg name "$2" '.results[] | select(.display_name == $name) | .id')

 if [ -z "$lsid" ]; then
   echo "Logical switch $2 Does not exist, cannot proceed"
   return 1
 fi

 local display_name="$1-$2"
 local ip_address=$(echo $3 | cut -d "/" -f1)
 local subnet_mask=$(echo $3 | cut -d "/" -f2)

 echo "Checking T1 $t1id for $ip_address"
 local chk=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-router-ports?logical_router_id=$t1id | \
   jq -r --arg ip_address "$ip_address" \
   '.results[] |
   select(.resource_type == "LogicalRouterDownLinkPort") |
   .subnets[] |
   select(.ip_addresses[] == $ip_address)')
   # Check for existing LRP for this T1 and Logical Switch
   # Come back to this

 #echo "CHK: $chk"
 if [ -n "$chk" ]; then
   echo "Router Port $1 with IP $ip_address already exists, skipping"
 else
   echo "Creating Router Port on $1 for $2"
   #Create Logical Switch Port first
   lspid=$(Create_NSX_LogicalSwitchPortforT1 $2 $1)
   #echo "lspid:" $lspid
   # then attach switch port id to router and set subnet


   downlink_config=$(
     jq -n \
     --arg t1id "$t1id" \
     --arg display_name "$display_name" \
     --arg logical_switch_port_id "$lspid" \
     --arg ip_address "$ip_address" \
     --arg subnet_mask "$subnet_mask" \
     '
     {
      "resource_type": "LogicalRouterDownLinkPort",
      "logical_router_id": $t1id,
      "display_name": $display_name,
      "linked_logical_switch_port_id": {"target_type": "LogicalPort", "target_id": $logical_switch_port_id},
      "subnets": [
        {
         "ip_addresses": [$ip_address],
         "prefix_length": $subnet_mask
        }]
     }
     '
     )
     # echo $downlink_config
     echo "Adding Router Port for $2 to $1 with IP: $ip_address"
     curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
       -u $NSXUSERNAME:$NSXPASSWORD \
       $NSXHOSTNAME/api/v1/logical-router-ports \
       -X POST -d "$downlink_config"
 fi
}

Create_NSX_NAT_rule() {
 # $1 T0 Router Name
 # $2 Type/Action
 # $3 Source
 # $4 Destination
 # $5 Translated
 # $6 Priority
 # $7 Description
 # GET T0 ID
 local t0id=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-routers | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.router_type == "TIER0") | .id')
 if [ -z "$t0id" ]; then
   echo "Tier 0 Router $1 Does not exist, cannot proceed"
   return 1
 fi
 #check for existing rule matching action, source,  dest & Trans
 if [ $3 == "Any" ]; then
  #check for existing rule matching action, dest & Trans
  local chk=$(curl -s -k -H "Content-Type: Application/xml" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules | \
    jq -r \
    --arg action "$2" \
    --arg dest "$4" \
    --arg trans "$5" \
    '.results[] | select(.action == $action) | select(.match_destination_network == $dest) | select(.translated_network == $trans) | .id')
 elif [ $4 == "Any" ]; then
   #check for existing rule matching action, source & Trans
   local chk=$(curl -s -k -H "Content-Type: Application/xml" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules | \
     jq -r \
     --arg action "$2" \
     --arg source "$3" \
     --arg trans "$5" \
     '.results[] | select(.action == $action) | select(.match_source_network == $source) | select(.translated_network == $trans) | .id')
 else
   #check for existing rule matching action, source & Trans
   local chk=$(curl -s -k -H "Content-Type: Application/xml" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules | \
     jq -r \
     --arg action "$2" \
     --arg source "$3" \
     --arg trans "$5" \
     --arg dest "$4" \
     '.results[] | select(.action == $action) | select(.match_source_network == $source) | select(.translated_network == $trans) | select(.match_destination_network == $dest) | .id')
 fi

 if [ -n "$chk" ]; then
   ruleenabled=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD -X GET \
     $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules/$chk \
     | jq -r '.enabled')
   if [ $ruleenabled == "true" ]; then
     echo "Rule exists and is enabled, skipping"
   else
     echo "Rule exists, but is disabled.  Enabling"
     natconfig=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
       -u $NSXUSERNAME:$NSXPASSWORD -X GET \
       $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules/$chk \
       | jq -r '.enabled = "true"')
     curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
       -u $NSXUSERNAME:$NSXPASSWORD \
       $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules/$chk \
       -X PUT -d "$natconfig"
   fi
 else
   nat_config=$(
     jq -n \
     --arg t0id "$t0id" \
     --arg action "$2" \
     --arg source "$3" \
     --arg dest "$4" \
     --arg trans "$5" \
     --arg priority "$6" \
     --arg description "$7" \
     '
     {
       "resource_type": "NatRule",
       "display_name": $description,
       "description": $description,
       "logical_router_id": $t0id,
       "nat_pass": true,
       "action": $action,
       "logging": false,
       "rule_priority": $priority,
       "translated_network": $trans,
       "enabled": true
     }
     +
     if $dest != "Any" then
     {
       "match_destination_network": $dest,
     }
     else .
     end
     +
     if $source != "Any" then
     {
       "match_source_network": $source,
     }
     else .
     end
     '
   )
   #echo $nat_config
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules \
     -X POST -d "$nat_config"

 fi
}

Connect_NSX_T1T0() {
 # $1 T0 Name
 # $2 T1 Name
 # used internally
 local t0display_name="LinkedPort_$2"
 local t1display_name="LinkedPort_$1"

 local t0id=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-routers | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.router_type == "TIER0") | .id')

 local t1id=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-routers | \
   jq -r --arg name "$2" '.results[] | select(.display_name == $name) | select(.router_type == "TIER1") | .id')

 local chk=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-router-ports?logical_router_id=$t0id | \
   jq -r --arg name "$t0display_name" '.results[] | select(.display_name == $name) | .id')


 if [ -n "$chk" ]; then
   echo  "T0 link port to $2 already exists"
 else
   t0linkport_config=$(
     jq -n \
     --arg t0id "$t0id" \
     --arg display_name "$t0display_name" \
     '
     {
      "resource_type": "LogicalRouterLinkPortOnTIER0",
      "logical_router_id": $t0id,
      "display_name": $display_name
     }
     '
   )
   echo "Creating Linked port named $t0display_name on $1"
   local t0_linkport_id=$(
     curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
       -u $NSXUSERNAME:$NSXPASSWORD \
       $NSXHOSTNAME/api/v1/logical-router-ports \
       -X POST -d "$t0linkport_config" | \
     jq -r '.id'
   )

   t1linkport_config=$(
     jq -n \
     --arg t1id "$t1id" \
     --arg display_name "$t1display_name" \
     --arg t0_linkport_id "$t0_linkport_id" \
     '
     {
      "resource_type": "LogicalRouterLinkPortOnTIER1",
      "logical_router_id": $t1id,
      "display_name": $display_name,
      "linked_logical_router_port_id": {"target_type": "LogicalPort", "target_id": "'"$t0_linkport_id"'"}
     }
     '
     )
     #echo $t1linkport_config
     echo "Creating Linked port named $t1display_name on $2"
     curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
       -u $NSXUSERNAME:$NSXPASSWORD \
       $NSXHOSTNAME/api/v1/logical-router-ports \
       -X POST -d "$t1linkport_config"

 fi

}

Enable_Route_Advertisement_T1() {
 # $1 - T1 Name
 # Used Internally
 local t1id=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-routers | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.router_type == "TIER1") | .id')

  if [ -z "$t1id" ]; then
    echo "Router $1 does not exist, cannot proceed"
    return 1
  fi

 curr_rev=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-routers/${t1id}/routing/advertisement | \
   | jq '._revision')

 adv_config=$(
   jq -n \
   --arg rev $curr_rev \
   '
   {
    "resource_type": "AdvertisementConfig",
    "description": "Enable advertisement",
    "advertise_nsx_connected_routes": true,
    "advertise_static_routes": false,
    "advertise_nat_routes": false,
    "advertise_lb_vip": true,
    "advertise_lb_snat_ip": false,
    "enabled": true,
    "_revision": $rev
   }
   '
 )

 #echo $adv_config
 curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   ${NSXHOSTNAME}/api/v1/logical-routers/${t1id}/routing/advertisement/ \
   -X PUT -d "$adv_config"

}

Delete_NSX_NAT_rule() {
 # $1 T0 Router Name
 # $2 Type/Action
 # $3 Source
 # $4 Destination
 # $5 Translated
 # $6 Actually Delete
 # GET T0 ID
 local t0id=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-routers | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.router_type == "TIER0") | .id')
 if [ -z "$t0id" ]; then
   echo "Tier 0 Router $1 Does not exist, cannot proceed"
   return 1
 fi
 #check for existing rule matching action, source,  dest & Trans
 if [ $3 == "Any" ]; then
  #check for existing rule matching action, dest & Trans
  local chk=$(curl -s -k -H "Content-Type: Application/xml" -H "X-Allow-Overwrite: true" \
    -u $NSXUSERNAME:$NSXPASSWORD \
    $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules | \
    jq -r \
    --arg action "$2" \
    --arg dest "$4" \
    --arg trans "$5" \
    '.results[] | select(.action == $action) | select(.match_destination_network == $dest) | select(.translated_network == $trans) | .id')
 elif [ $4 == "Any" ]; then
   #check for existing rule matching action, source & Trans
   local chk=$(curl -s -k -H "Content-Type: Application/xml" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules | \
     jq -r \
     --arg action "$2" \
     --arg source "$3" \
     --arg trans "$5" \
     '.results[] | select(.action == $action) | select(.match_source_network == $source) | select(.translated_network == $trans) | .id')
 else
   #check for existing rule matching action, source & Trans
   local chk=$(curl -s -k -H "Content-Type: Application/xml" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules | \
     jq -r \
     --arg action "$2" \
     --arg source "$3" \
     --arg trans "$5" \
     --arg dest "$4" \
     '.results[] | select(.action == $action) | select(.match_source_network == $source) | select(.translated_network == $trans) | select(.match_destination_network == $dest) | .id')
 fi

 if [ -n "$chk" ]; then
   if [ $6 == "DELETE" ]; then
    echo "$2 rule exists, deleting it"
    curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
      -u $NSXUSERNAME:$NSXPASSWORD \
      $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules/$chk \
      -X DELETE
   else
     #Disable it instead
     echo "$2 rule exists, disabling it"
     natconfig=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
       -u $NSXUSERNAME:$NSXPASSWORD -X GET \
       $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules/$chk \
       | jq -r '.enabled = "false"')
     curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
       -u $NSXUSERNAME:$NSXPASSWORD \
       $NSXHOSTNAME/api/v1/logical-routers/${t0id}/nat/rules/$chk \
       -X PUT -d "$natconfig"
   fi
 else
   echo "$2 rule for $3 to $4, translated to $4 does not exist"
 fi
}

Delete_NSX_IP_Block() {
 # $1 - Name
 # Check that it exists and has zero allocations
 local chk=$(curl -s -k -H "Content-Type: Application/xml" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/pools/ip-blocks | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')

 if [ -n "$chk" ]; then
   echo "Block $1 exists, checking for subnets"
   subnet_count=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/pools/ip-subnets?block_id=${chk} | \
     jq -r '.result_count')
   if [ $subnet_count == "0" ]; then
    echo "Deleting IP Block $1"
    curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
      -u $NSXUSERNAME:$NSXPASSWORD \
      $NSXHOSTNAME/api/v1/pools/ip-blocks/${chk} \
      -X DELETE
   else
     echo "Block $1 exists, but has $subnet_count allocated subnets, not deleting"
   fi

 else
   echo "Block $1 does not exist"
 fi
}

Delete_NSX_IP_Pool() {
 # $1 - Name
 # Check that it exists and has zero allocations
 local chk=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/pools/ip-pools | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | select(.pool_usage.allocated_ids == 0)| .id')

 if [ -n "$chk" ]; then
   echo Pool $1 exists and has no allocations, deleting it
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/pools/ip-pools/${chk}?force=true \
     -X DELETE
 else
   echo "Pool $1 either does not exist or has allocated IPs"
 fi
}

Delete_NSX_T1Router(){
 # $1 - Logical Router Name
 local chk=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-routers | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')

 if [ -n "$chk" ]; then
   echo Router $1 exists, deleting it
   # get the logical router ports (and corresponding Linked ports on T0) and delete them
   local lrps=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-router-ports?logical_router_id=$chk | \
     jq -r --arg name "$1" '.results[] | .id, .linked_logical_router_port_id.target_id')
   for lrp in $lrps
     do
       if [ -n "$lrp" ]; then
         echo Deleting logical Router Port $lrp
         Delete_NSX_LogicalRouterPort $lrp
       fi
     done

   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-routers/${chk}?force=true \
     -X DELETE
 else
   echo Router $1 Does not exist
 fi
}

Delete_NSX_LogicalRouterPort(){
 # Delete by ID rather than name
 curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-router-ports/${1}?force=true \
   -X DELETE
}

Delete_NSX_LogicalSwitchPort(){
 # Delete by ID rather than name
 curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-ports/$1?detach=true \
   -X DELETE
}

Delete_NSX_LogicalSwitch(){
 # $1 - Logical Switch Name
 local chk=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/logical-switches | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')

 if [ -n "$chk" ]; then
   echo Switch $1 exists, deleting it
   #Find and delete the Logical Switch Ports
   local lsps=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/logical-ports?logical_switch_id=$chk | \
     jq -r --arg name "$1" '.results[] | .id')
   for lsp in $lsps
     do
       echo Deleting logical Switch Port $lsp
       Delete_NSX_LogicalSwitchPort $lsp
     done

   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD  -X DELETE \
     ${NSXHOSTNAME}/api/v1/logical-switches/${chk}?detach=true&cascade=true

 else
   echo Switch $1 Does not exist
 fi
}

Delete_NSX_LB_Monitor() {
 # $1 - monitor Name ex:  pas-web-monitor
 ###################################################
 ###  Deletes the Virtual Server if it existst   ###
 ###################################################
 local chk=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/loadbalancer/monitors | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')

 if [ -n "$chk" ]; then
   echo Monitor $1 exists, deleting it
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/monitors/$chk \
     -X DELETE
 else
   echo Virtual Server $1 Does not exist
 fi
}

Delete_NSX_LB_ServerPool() {
 # $1 - Virtual Server Name ex:  pas-web-vs
 ###################################################
 ###  Deletes the Virtual Server if it existst   ###
 ###################################################
 local chk=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/loadbalancer/pools | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')

 if [ -n "$chk" ]; then
   echo Server Pool $1 exists, deleting it
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/pools/$chk \
     -X DELETE
 else
   echo Server Pool $1 Does not exist

 fi
}

Delete_NSX_LB_VirtualServer() {
 # $1 - Virtual Server Name ex:  pas-web-vs
 # $2 - IP address to verify
 ###################################################
 ###  Deletes the Virtual Server if it exists    ###
 ###################################################
 local chk=$(curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/loadbalancer/virtual-servers | \
   jq -r --arg name "$1" --arg vip "$2" '.results[] | select(.display_name == $name) | select(.ip_address == $vip)| .id')

 if [ -n "$chk" ]; then
   echo Virtual Server $1 exists, deleting it
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/virtual-servers/${chk}?delete_associated_rules=true \
     -X DELETE
 else
   echo "Virtual Server $1 with IP $2 Does not exist"

 fi
}

Delete_NSX_LoadBalancer() {
 # $1 - Load Balancer Name ex:  pas-lb
 ###############################################
 ###  Deletes the Load Balancer if it exists ###
 ###############################################
 local chk=$(curl -s -k -H "Content-Type: Application/xml X-Allow-Overwrite: true" \
   -u $NSXUSERNAME:$NSXPASSWORD \
   $NSXHOSTNAME/api/v1/loadbalancer/services | \
   jq -r --arg name "$1" '.results[] | select(.display_name == $name) | .id')
   #'.results[].display_name' | grep "$1")
   #jq -r '.results[] | select(.display_name == "$1") | .id')
 #echo chk: $chk
 if [ -n "$chk" ]; then
   echo LB $1  exists, deleting
   curl -s -k -H "Content-Type: Application/json" -H "X-Allow-Overwrite: true" \
     -u $NSXUSERNAME:$NSXPASSWORD \
     $NSXHOSTNAME/api/v1/loadbalancer/services/$chk \
     -X DELETE
 else
   echo LB $1 Does not exist
 fi
}
