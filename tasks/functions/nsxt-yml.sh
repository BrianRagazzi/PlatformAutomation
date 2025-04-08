# Collection of functions to parse YML file and call downstream NSX functions

# Refactored - 2025





Create_T1_Gateways() {
  # $1 Config File
  local yaml_file=$1
  # Iterate through the t1_gateways array using yq
  yq eval '.t1_gateways[] | .gateway_name' "$yaml_file" | while read -r gw_name; do
        #echo $gw_name
        # Extract each value from the YAML for the gateway
        gateway_name=$gw_name
        t0_name=$(gw_name=$gw_name yq eval '.t1_gateways[] | select(.gateway_name == strenv(gw_name)) .t0_name' $yaml_file)
        edgecluster_name=$(gw_name=$gw_name yq eval ".t1_gateways[] | select(.gateway_name == strenv(gw_name)) .edgecluster_name" "$yaml_file")
        route_adv_types=$(gw_name=$gw_name yq eval ".t1_gateways[] | select(.gateway_name == strenv(gw_name)) .route_adv_types" "$yaml_file")
        description=$(gw_name=$gw_name yq eval ".t1_gateways[] | select(.gateway_name == strenv(gw_name)) .description" "$yaml_file")
        ha_mode=$(gw_name=$gw_name yq eval ".t1_gateways[] | select(.gateway_name == strenv(gw_name)) .ha_mode" "$yaml_file")
        pool_alloc=$(gw_name=$gw_name yq eval ".t1_gateways[] | select(.gateway_name == strenv(gw_name)) .pool_allocation" "$yaml_file")


        # Call the Create_NSX_T1_Gateway function with extracted values
        #Create_NSX_T1_Gateway "$gateway_name" "$t0_name" "$edgecluster_name" "$route_adv_types" "$description" "$ha_mode" "$pool_alloc"
        Create_NSX_T1_Gateway "$gateway_name" "$t0_name" "$edgecluster_name" "$route_adv_types" "$description" "$ha_mode"
    done
}

Delete_T1_Gateways() {
  # $1 Config File
  local yaml_file=$1
  # Iterate through the t1_gateways array using yq
  #yq eval '.segments[] | .segment_name' "$yaml_file" | while read -r seg_name; do
  local gateway_count=$(yq eval '.t1_gateways | length' "$yaml_file")
  for ((i=0; i<gateway_count; i++)); do
        #echo $gw_name
        # Extract each value from the YAML for the gateway
        local gw_name=$(yq eval ".t1_gateways[$i].gateway_name" "$yaml_file")

        Delete_NSX_T1_Gateway "$gw_name"
  done
}

Create_Segments() {
  # $1 Config File
  local yaml_file=$1
  # Iterate through the t1_gateways array using yq
  #yq eval '.segments[] | .segment_name' "$yaml_file" | while read -r seg_name; do
  local segment_count=$(yq eval '.segments | length' "$yaml_file")
  for ((i=0; i<segment_count; i++)); do
        #echo $gw_name
        # Extract each value from the YAML for the gateway
        local segment_name=$(yq eval ".segments[$i].segment_name" "$yaml_file")
        local transport_zone=$(yq eval ".segments[$i].transport_zone" "$yaml_file")
        local gateway=$(yq eval ".segments[$i].gateway" "$yaml_file")
        local subnet_gateway_address=$(yq eval ".segments[$i].subnet.gateway_address" "$yaml_file")
        local subnet_cidr=$(yq eval ".segments[$i].subnet.cidr" "$yaml_file")

        Create_NSX_Segment \
            "$segment_name" \
            "$transport_zone" \
            "$gateway" \
            "$subnet_gateway_address" \
            "$subnet_cidr"
  done
}

Delete_Segments() {
  # $1 Config File
  local yaml_file=$1
  # Iterate through the t1_gateways array using yq
  #yq eval '.segments[] | .segment_name' "$yaml_file" | while read -r seg_name; do
  local segment_count=$(yq eval '.segments | length' "$yaml_file")
  for ((i=0; i<segment_count; i++)); do
        #echo $gw_name
        # Extract each value from the YAML for the gateway
        local segment_name=$(yq eval ".segments[$i].segment_name" "$yaml_file")

        Delete_NSX_Segment "$segment_name"
    done
}

Create_IP_Pools() {
  # $1 Config File
  local yaml_file=$1
  # Iterate through the t1_gateways array using yq
  #yq eval '.segments[] | .segment_name' "$yaml_file" | while read -r seg_name; do
  local item_count=$(yq eval '.ip_pools | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    #echo $gw_name
    # Extract each value from the YAML for the gateway
    local pool_name=$(yq eval ".ip_pools[$i].name" "$yaml_file")
    local cidr=$(yq eval ".ip_pools[$i].cidr" "$yaml_file")
    local desc=$(yq eval ".ip_pools[$i].description" "$yaml_file")
    local gateway=$(yq eval ".ip_pools[$i].gateway" "$yaml_file")
    local ip_range=$(yq eval ".ip_pools[$i].range" "$yaml_file")
    local dns_servers=$(yq eval ".ip_pools[$i].dns_servers" "$yaml_file")

    Create_NSX_IP_Pool \
      "$pool_name" \
      "$cidr" \
      "$gateway" \
      "$ip_range" \
      "$dns_servers" \
      "$desc"
  done
}

Delete_IP_Pools() {
  # $1 Config File
  local yaml_file=$1
  local item_count=$(yq eval '.ip_pools | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    local pool_name=$(yq eval ".ip_pools[$i].name" "$yaml_file")

    Delete_NSX_IP_Pool "$pool_name"
  done
}

Create_IP_Blocks() {
  # $1 Config File
  local yaml_file=$1
  # Iterate through the t1_gateways array using yq
  #yq eval '.segments[] | .segment_name' "$yaml_file" | while read -r seg_name; do
  local item_count=$(yq eval '.ip_blocks | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    #echo $gw_name
    # Extract each value from the YAML for the gateway
    local block_name=$(yq eval ".ip_blocks[$i].name" "$yaml_file")
    local cidr=$(yq eval ".ip_blocks[$i].cidr" "$yaml_file")
    local desc=$(yq eval ".ip_blocks[$i].description" "$yaml_file")

    Create_NSX_IP_Block \
      "$block_name" \
      "$cidr" \
      "$desc"
  done
}

Delete_IP_Blocks() {
  # $1 Config File
  local yaml_file=$1
  local item_count=$(yq eval '.ip_blocks | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    local block_name=$(yq eval ".ip_blocks[$i].name" "$yaml_file")

    Delete_NSX_IP_Block "$block_name"
  done
}


Create_T0_NAT_Rules() {
  # $1 Config File
  local yaml_file=$1
  local item_count=$(yq eval '.t0_nat_rules | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    #echo $gw_name
    # Extract each value from the YAML for the gateway
    local name=$(yq eval ".t0_nat_rules [$i].name" "$yaml_file")
    local t0_name=$(yq eval ".t0_nat_rules [$i].t0_name" "$yaml_file")
    local action=$(yq eval ".t0_nat_rules [$i].action" "$yaml_file")
    local source=$(yq eval ".t0_nat_rules [$i].source" "$yaml_file")
    local dest=$(yq eval ".t0_nat_rules [$i].dest" "$yaml_file")
    local trans=$(yq eval ".t0_nat_rules [$i].trans" "$yaml_file")

    Create_NSX_T0_NAT_Rule \
      "$name" \
      "$t0_name" \
      "$action" \
      "$source" \
      "$trans" \
      "$dest"
  done
}

Delete_T0_NAT_Rules() {
  # $1 Config File
  local yaml_file=$1
  local item_count=$(yq eval '.t0_nat_rules | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    #echo $gw_name
    # Extract each value from the YAML for the gateway
    local name=$(yq eval ".t0_nat_rules [$i].name" "$yaml_file")
    local t0_name=$(yq eval ".t0_nat_rules [$i].t0_name" "$yaml_file")

    Delete_NSX_T0_NAT_Rule \
      "$name" \
      "$t0_name"
  done
}


# NOT YET Refactored - 2025
Create_Load_Balancers() {
 # $1 Config_file
 lbchk=$(yq r $1 'load_balancers[*].name')
 if [ $lbchk == "null" ]; then
   echo "No Load-Balancers to create"
 else
   lbs=$(yq r $1 'load_balancers[*].name' -j | jq -r '.[]')
   for lb_name in $lbs
     do
       # monitors: yq r $1 'load_balancers[*]' -j | jq -r '.[] | .monitors[]'
       monitors=$(yq r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .monitors[] | .name')
       for mon_name in $monitors
         do
           mon_port=$(yq r $1 'load_balancers[*]' -j | \
           jq -r --arg lb_name  "$lb_name" --arg mon_name "$mon_name" \
           '.[] | select(.name == $lb_name)| .monitors[] | select(.name == $mon_name) | .port')
           mon_protocol=$(yq r $1 'load_balancers[*]' -j | \
           jq -r --arg lb_name  "$lb_name" --arg mon_name "$mon_name" \
           '.[] | select(.name == $lb_name)| .monitors[] | select(.name == $mon_name) | .protocol')
           mon_url=$(yq r $1 'load_balancers[*]' -j | \
           jq -r --arg lb_name  "$lb_name" --arg mon_name "$mon_name" \
           '.[] | select(.name == $lb_name)| .monitors[] | select(.name == $mon_name) | .url')
           Create_NSX_LB_Monitor "$mon_name" "$mon_port" "$mon_protocol" "$mon_url"
         done

       serverpools=$(yq r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .server_pools[] | .name')
       for pool_name in $serverpools
         do
          pool_mon=$(yq r $1 'load_balancers[*]' -j | \
          jq -r --arg lb_name  "$lb_name" --arg pool_name "$pool_name" \
          '.[] | select(.name == $lb_name)| .server_pools[] | select(.name == $pool_name) | .monitor_name')
          pool_trans=$(yq r $1 'load_balancers[*]' -j | \
          jq -r --arg lb_name  "$lb_name" --arg pool_name "$pool_name" \
          '.[] | select(.name == $lb_name)| .server_pools[] | select(.name == $pool_name) | .translation_mode')
          #echo "trying $pool_name $pool_mon $pool_trans"
          Create_NSX_LB_ServerPool "$pool_name" "$pool_mon" "$pool_trans"
         done

       virtualservers=$(yq r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .virtual_servers[] | .name')
       for vs_name in $virtualservers
         do
          vs_pool=$(yq r $1 'load_balancers[*]' -j | \
          jq -r --arg lb_name  "$lb_name" --arg vs_name "$vs_name" \
          '.[] | select(.name == $lb_name)| .virtual_servers[] | select(.name == $vs_name) | .pool_name')
          vs_port=$(yq r $1 'load_balancers[*]' -j | \
          jq -r --arg lb_name  "$lb_name" --arg vs_name "$vs_name" \
          '.[] | select(.name == $lb_name)| .virtual_servers[] | select(.name == $vs_name) | .port')
          vs_vip=$(yq r $1 'load_balancers[*]' -j | \
          jq -r --arg lb_name  "$lb_name" --arg vs_name "$vs_name" \
          '.[] | select(.name == $lb_name)| .virtual_servers[] | select(.name == $vs_name) | .virtual_ip')
          Create_NSX_LB_VirtualServer "$vs_name" "$vs_pool" "$vs_port" "$vs_vip"
         done
       #Load-Balancer comma-separated virtual server names
       vs_names=""
       for vs_name in $virtualservers
         do
           vs_names+="${vs_name},"
         done
       t1_name=$(yq r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .t1_name')
       #echo "Passing $vs_names"
       Create_NSX_LoadBalancer "$lb_name" "$t1_name" "$vs_names"

     done
 fi
}

Delete_Load_Balancers() {
 # $1 Config file
 lbchk=$(yq r $1 'load_balancers[*].name')
 if [ $lbchk == "null" ]; then
   echo "No Load-Balancers to create"
 else
   lbs=$(yq r $1 'load_balancers[*].name' -j | jq -r '.[]')
   for lb_name in $lbs
     do
       Delete_NSX_LoadBalancer $lb_name

       virtualservers=$(yq r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .virtual_servers[] | .name')
       for vs_name in $virtualservers
         do
           vs_vip=$(yq r $1 'load_balancers[*]' -j | \
           jq -r --arg lb_name  "$lb_name" --arg vs_name "$vs_name" \
           '.[] | select(.name == $lb_name)| .virtual_servers[] | select(.name == $vs_name) | .virtual_ip')
           Delete_NSX_LB_VirtualServer "$vs_name" "$vs_vip"
         done

       serverpools=$(yq r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .server_pools[] | .name')
       for pool_name in $serverpools
         do
          Delete_NSX_LB_ServerPool "$pool_name"
         done

       # monitors: yq r $1 'load_balancers[*]' -j | jq -r '.[] | .monitors[]'
       monitors=$(yq r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .monitors[] | .name')
       for mon_name in $monitors
         do
           Delete_NSX_LB_Monitor "$mon_name"
         done
     done
 fi
}
