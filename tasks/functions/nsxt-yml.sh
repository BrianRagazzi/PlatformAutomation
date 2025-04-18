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


Create_LB_Monitors() {
  # $1 Config File
  local yaml_file=$1
  local item_count=$(yq eval '.lb_monitors | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    #echo $gw_name
    # Extract each value from the YAML for the gateway
    local name=$(yq eval ".lb_monitors [$i].name" "$yaml_file")
    local type=$(yq eval ".lb_monitors [$i].type" "$yaml_file")
    local mon_port=$(yq eval ".lb_monitors [$i].monitor_port" "$yaml_file")
    local http_request_method=$(yq eval ".lb_monitors [$i].http_request.method" "$yaml_file")
    local http_request_url=$(yq eval ".lb_monitors [$i].http_request.url" "$yaml_file")
    local http_request_version=$(yq eval ".lb_monitors [$i].http_request.version" "$yaml_file")
    local response_code=$(yq eval ".lb_monitors [$i].http_request.response_code" "$yaml_file")

    Create_NSX_LB_Monitor \
      "$name" \
      "$type" \
      "$mon_port" \
      "$http_request_method" \
      "$http_request_url" \
      "$http_request_version" \
      "$response_code"
  done
}

Delete_LB_Monitors() {
  # $1 Config File
  local yaml_file=$1
  local item_count=$(yq eval '.lb_monitors | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    local name=$(yq eval ".lb_monitors [$i].name" "$yaml_file")
    Delete_NSX_LB_Monitor "$name"
  done
}

Create_LB_Pools() {
  # $1 Config File
  local yaml_file=$1
  local item_count=$(yq eval '.lb_server_pools | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    #echo $gw_name
    # Extract each value from the YAML for the gateway
    local name=$(yq eval ".lb_server_pools [$i].name" "$yaml_file")
    local monitor=$(yq eval ".lb_server_pools [$i].active_monitor" "$yaml_file")
    local snat_mode=$(yq eval ".lb_server_pools [$i].snat_mode" "$yaml_file")

    Create_NSX_LB_ServerPool \
      "$name" \
      "$monitor" \
      "$snat_mode"
  done
}


Delete_LB_Pools() {
  # $1 Config File
  local yaml_file=$1
  local item_count=$(yq eval '.lb_server_pools | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    local name=$(yq eval ".lb_server_pools [$i].name" "$yaml_file")
    Delete_NSX_LB_ServerPool "$name"
  done
}

Create_Load_Balancers() {
  # Loop through LBs, Loop through VSs for each
  # $1 Config File
  local yaml_file=$1
  local item_count=$(yq eval '.load_balancers | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    #echo $gw_name
    # Extract each value from the YAML for the gateway
    local name=$(yq eval ".load_balancers [$i].name" "$yaml_file")
    local size=$(yq eval ".load_balancers [$i].size" "$yaml_file")
    local t1_name=$(yq eval ".load_balancers [$i].attachment" "$yaml_file")

    Create_NSX_LoadBalancer \
      "$name" \
      "$size" \
      "$t1_name"
    #echo "Create Load Balancer $name $size $t1_name"
    local vs_count=$(yq eval '.load_balancers [$i].virtual_servers | length' "$yaml_file")
    for ((vs=0; vs<vs_count; vs++)); do
      local vs_name=$(yq eval ".load_balancers [$i].virtual_servers [$vs].name" "$yaml_file")
      local vs_ap_name=$(yq eval ".load_balancers [$i].virtual_servers [$vs].app_profile" "$yaml_file")
      local vs_sp_name=$(yq eval ".load_balancers [$i].virtual_servers [$vs].server_pool" "$yaml_file")
      local vs_ip=$(yq eval ".load_balancers [$i].virtual_servers [$vs].ip_address" "$yaml_file")
      local vs_ports=$(yq eval ".load_balancers [$i].virtual_servers [$vs].ports" "$yaml_file")
      #echo "Create VS $name $vs_name $vs_ap_name $vs_sp_name $vs_ip $vs_ports"

      Create_NSX_LB_VirtualServer \
        "$name" \
        "$vs_name" \
        "$vs_ap_name" \
        "$vs_sp_name" \
        "$vs_ip" \
        "$vs_ports"
    done
  done
}

Delete_Load_Balancers() {
  # Loop through LBs, Loop through VSs for each
  # $1 Config File
  local yaml_file=$1
  local item_count=$(yq eval '.load_balancers | length' "$yaml_file")
  for ((i=0; i<item_count; i++)); do
    local name=$(yq eval ".load_balancers [$i].name" "$yaml_file")
    local vs_count=$(yq eval '.load_balancers [$i].virtual_servers | length' "$yaml_file")
    for ((vs=0; vs<vs_count; vs++)); do
      local vs_name=$(yq eval ".load_balancers [$i].virtual_servers [$vs].name" "$yaml_file")
      Delete_NSX_LB_VirtualServer "$vs_name"
    done
    Delete_NSX_LoadBalancer "$name"
  done
}
