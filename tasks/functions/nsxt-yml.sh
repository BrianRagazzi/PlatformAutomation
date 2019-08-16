# Collection of functions to parse YML file and call downstream NSX functions

Create_Logical_Switches() {
 # $1 - Config File
 lss=$(yq -t r $1 'logical_switches[*].name' -j | jq -r '.[]')
 for ls_name in $lss
   do
    tz_name=$(yq r $1 'logical_switches[*]' -j | \
    jq -r --arg name "$ls_name" '.[] | select(.name == $name) | .transport_zone_name')
    echo $ls_name in $tz_name
    Create_NSX_LogicalSwitch "$ls_name" "$tz_name"
   done
}

Delete_Logical_Switches() {
 # $1 - Config File
 lss=$(yq -t r $1 'logical_switches[*].name' -j | jq -r '.[]')
 for ls_name in $lss
   do
     Delete_NSX_LogicalSwitch "$ls_name"
   done
}

Create_T1_Routers() {
 # $1 - Config File
 # Params of Create_NSX_T1Router
 # $1 - T1 Router name
 # $2 - T0 to attach to
 # $3 - Edge Cluster Name
 lrs=$(yq -t r $1 't1_logical_routers[*].name' -j | jq -r '.[]')
 for lr_name in $lrs
   do
     t0_name=$(yq -t r $1 't1_logical_routers[*]' -j | \
     jq -r --arg name "$lr_name" '.[] | select(.name == $name) | .t0_name')
     ec_name=$(yq r $1 't1_logical_routers[*]' -j | \
     jq -r --arg name "$lr_name" '.[] | select(.name == $name) | .edgecluster_name')
     echo "Create T1 named $lr_name attached to T0 $t0_name and using ec $ec_name"
     Create_NSX_T1Router "$lr_name" "$t0_name" "$ec_name"

     lss=$(yq -t r $1 't1_logical_routers[*]' -j | \
     jq -r --arg name "$lr_name" '.[] | select(.name == $name) | .downlinks[].logical_switch_name')
     for ls_name in $lss
       do
        rp_cidr=$(yq -t r $1 't1_logical_routers[*]' -j | \
        jq -r --arg router_name "$lr_name" --arg switch_name "$ls_name" \
        '.[] | select(.name == $router_name) | .downlinks[] | select(.logical_switch_name == $switch_name) | .router_port_cidr')
        echo "Adding downlink to $lr_name for $ls_name with IP: $rp_cidr"
        Create_NSX_T1DownlinkPort "$lr_name" "$ls_name" "$rp_cidr"
       done
     Enable_Route_Advertisement_T1 $lr_name
   done
}

Delete_T1_Routers() {
 # $1 - Config File
 lrs=$(yq -t r $1 't1_logical_routers[*].name' -j | jq -r '.[]')
 for lr_name in $lrs
   do
     Delete_NSX_T1Router "$lr_name"
   done
}

Create_T0_NAT_Rules() {
 # $1 - Config File
 # Params of Create_NSX_NAT_rule
 # $1 T0 Router Name
 # $2 Type/Action
 # $3 Source
 # $4 Destination
 # $5 Translated
 # $6 Priority
 # $7 Description
 nrs=$(yq -t r $1 't0_nat_rules[*].name' -j | jq -r '.[]')
 for nr_name in $nrs
   do
     t0_name=$(yq -t r $1 't0_nat_rules[*]' -j | \
     jq -r --arg name "$nr_name" '.[] | select(.name == $name) | .t0_name')
     action=$(yq -t r $1 't0_nat_rules[*]' -j | \
     jq -r --arg name "$nr_name" '.[] | select(.name == $name) | .action')
     source=$(yq -t r $1 't0_nat_rules[*]' -j | \
     jq -r --arg name "$nr_name" '.[] | select(.name == $name) | .source')
     dest=$(yq -t r $1 't0_nat_rules[*]' -j | \
     jq -r --arg name "$nr_name" '.[] | select(.name == $name) | .dest')
     trans=$(yq -t r $1 't0_nat_rules[*]' -j | \
     jq -r --arg name "$nr_name" '.[] | select(.name == $name) | .trans')
     priority=$(yq -t r $1 't0_nat_rules[*]' -j | \
     jq -r --arg name "$nr_name" '.[] | select(.name == $name) | .priority')
     Create_NSX_NAT_rule "$t0_name" "$action" "$source" "$dest" "$trans" "$priority" "$nr_name"
   done
}

Delete_T0_NAT_Rules() {
 # $1 - Config File
 # $2 - Actually Delete
 # Params of Delete_NSX_NAT_rule
 # $1 T0 Router Name
 # $2 Type/Action
 # $3 Source
 # $4 Destination
 # $5 Translated
 # $6 Actually Delete "DELETE"
 nrs=$(yq -t r $1 't0_nat_rules[*].name' -j | jq -r '.[]')
 for nr_name in $nrs
   do
    t0_name=$(yq -t r $1 't0_nat_rules[*]' -j | \
    jq -r --arg name "$nr_name" '.[] | select(.name == $name) | .t0_name')
    action=$(yq -t r $1 't0_nat_rules[*]' -j | \
    jq -r --arg name "$nr_name" '.[] | select(.name == $name) | .action')
    source=$(yq -t r $1 't0_nat_rules[*]' -j | \
    jq -r --arg name "$nr_name" '.[] | select(.name == $name) | .source')
    dest=$(yq -t r $1 't0_nat_rules[*]' -j | \
    jq -r --arg name "$nr_name" '.[] | select(.name == $name) | .dest')
    trans=$(yq -t r $1 't0_nat_rules[*]' -j | \
    jq -r --arg name "$nr_name" '.[] | select(.name == $name) | .trans')
    Delete_NSX_NAT_rule "$t0_name" "$action" "$source" "$dest" "$trans" "$2"
   done
}

Create_IP_Pools() {
 # $1 - Config File
 # Params of Create_NSX_IP_Pool
 # $1 - Name
 # $2 - CIDR
 # $3 - Description
 # $4 - Gateway address
 # $5 - Allocation Range ex: 192.168.1.20-192.168.1.40
 # $6 - DNS Servers (Comma separated, optional)
 ipps=$(yq -t r $1 'ip_pools[*].name' -j | jq -r '.[]')
 for ipp_name in $ipps
   do
    cidr=$(yq -t r $1 'ip_pools[*]' -j | \
    jq -r --arg name "$ipp_name" '.[] | select(.name == $name) | .cidr')
    desc=$(yq -t r $1 'ip_pools[*]' -j | \
    jq -r --arg name "$ipp_name" '.[] | select(.name == $name) | .description')
    gateway=$(yq -t r $1 'ip_pools[*]' -j | \
    jq -r --arg name "$ipp_name" '.[] | select(.name == $name) | .gateway')
    range=$(yq -t r $1 'ip_pools[*]' -j | \
    jq -r --arg name "$ipp_name" '.[] | select(.name == $name) | .range')
    dns=$(yq -t r $1 'ip_pools[*]' -j | \
    jq -r --arg name "$ipp_name" '.[] | select(.name == $name) | .dns_servers')
    #echo "Creating IP Pool named $ipp_name for $cidr, $desc"
    Create_NSX_IP_Pool "$ipp_name" "$cidr" "$desc" "$gateway" "$range" "$dns"
   done
}

Delete_IP_Pools() {
 # $1 - Config File
 # Params of Delete_NSX_IP_Pool
 # $1 - Name
 ipps=$(yq -t r $1 'ip_pools[*].name' -j | jq -r '.[]')
 for ipp_name in $ipps
   do
    Delete_NSX_IP_Pool "$ipp_name"
   done
}

Create_IP_Blocks() {
 # $1 - Config File
 # Params of Create_NSX_IP_Pool
 # $1 - Name
 # $2 - CIDR
 # $3 - Description
 ipbchk=$(yq -t r $1 'ip_blocks[*].name')
 if [ $ipbchk == "null" ]; then
   echo "No IP Blocks to create"
 else
  ipbs=$(yq -t r $1 'ip_blocks[*].name' -j | jq -r '.[]')
  for ipb_name in $ipbs
    do
     cidr=$(yq -t r $1 'ip_blocks[*]' -j | \
     jq -r --arg name "$ipb_name" '.[] | select(.name == $name) | .cidr')
     desc=$(yq -t r $1 'ip_blocks[*]' -j | \
     jq -r --arg name "$ipb_name" '.[] | select(.name == $name) | .description')
     #echo "Creating IP Pool named $ipp_name for $cidr, $desc"
     Create_NSX_IP_Block "$ipb_name" "$cidr" "$desc"
    done
 fi
}

Delete_IP_Blocks() {
 # $1 - Config File
 # Params of Delete_NSX_IP_Pool
 # $1 - Name
 ipbchk=$(yq -t r $1 'ip_blocks[*].name')
 if [ $ipbchk == "null" ]; then
   echo "No IP Blocks to delete"
 else
  ipps=$(yq -t r $1 'ip_blocks[*].name' -j | jq -r '.[]')
  for ipp_name in $ipps
    do
     Delete_NSX_IP_Block "$ipp_name"
    done
 fi
}

Create_Load_Balancers() {
 # $1 Config_file
 lbchk=$(yq -t r $1 'load_balancers[*].name')
 if [ $lbchk == "null" ]; then
   echo "No Load-Balancers to create"
 else
   lbs=$(yq -t r $1 'load_balancers[*].name' -j | jq -r '.[]')
   for lb_name in $lbs
     do
       # monitors: yq -t r $1 'load_balancers[*]' -j | jq -r '.[] | .monitors[]'
       monitors=$(yq -t r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .monitors[] | .name')
       for mon_name in $monitors
         do
           mon_port=$(yq -t r $1 'load_balancers[*]' -j | \
           jq -r --arg lb_name  "$lb_name" --arg mon_name "$mon_name" \
           '.[] | select(.name == $lb_name)| .monitors[] | select(.name == $mon_name) | .port')
           mon_protocol=$(yq -t r $1 'load_balancers[*]' -j | \
           jq -r --arg lb_name  "$lb_name" --arg mon_name "$mon_name" \
           '.[] | select(.name == $lb_name)| .monitors[] | select(.name == $mon_name) | .protocol')
           mon_url=$(yq -t r $1 'load_balancers[*]' -j | \
           jq -r --arg lb_name  "$lb_name" --arg mon_name "$mon_name" \
           '.[] | select(.name == $lb_name)| .monitors[] | select(.name == $mon_name) | .url')
           Create_NSX_LB_Monitor "$mon_name" "$mon_port" "$mon_protocol" "$mon_url"
         done

       serverpools=$(yq -t r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .server_pools[] | .name')
       for pool_name in $serverpools
         do
          pool_mon=$(yq -t r $1 'load_balancers[*]' -j | \
          jq -r --arg lb_name  "$lb_name" --arg pool_name "$pool_name" \
          '.[] | select(.name == $lb_name)| .server_pools[] | select(.name == $pool_name) | .monitor_name')
          pool_trans=$(yq -t r $1 'load_balancers[*]' -j | \
          jq -r --arg lb_name  "$lb_name" --arg pool_name "$pool_name" \
          '.[] | select(.name == $lb_name)| .server_pools[] | select(.name == $pool_name) | .translation_mode')
          #echo "trying $pool_name $pool_mon $pool_trans"
          Create_NSX_LB_ServerPool "$pool_name" "$pool_mon" "$pool_trans"
         done

       virtualservers=$(yq -t r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .virtual_servers[] | .name')
       for vs_name in $virtualservers
         do
          vs_pool=$(yq -t r $1 'load_balancers[*]' -j | \
          jq -r --arg lb_name  "$lb_name" --arg vs_name "$vs_name" \
          '.[] | select(.name == $lb_name)| .virtual_servers[] | select(.name == $vs_name) | .pool_name')
          vs_port=$(yq -t r $1 'load_balancers[*]' -j | \
          jq -r --arg lb_name  "$lb_name" --arg vs_name "$vs_name" \
          '.[] | select(.name == $lb_name)| .virtual_servers[] | select(.name == $vs_name) | .port')
          vs_vip=$(yq -t r $1 'load_balancers[*]' -j | \
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
       t1_name=$(yq -t r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .t1_name')
       #echo "Passing $vs_names"
       Create_NSX_LoadBalancer "$lb_name" "$t1_name" "$vs_names"

     done
 fi
}

Delete_Load_Balancers() {
 # $1 Config file
 lbchk=$(yq -t r $1 'load_balancers[*].name')
 if [ $lbchk == "null" ]; then
   echo "No Load-Balancers to create"
 else
   lbs=$(yq -t r $1 'load_balancers[*].name' -j | jq -r '.[]')
   for lb_name in $lbs
     do
       Delete_NSX_LoadBalancer $lb_name

       virtualservers=$(yq -t r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .virtual_servers[] | .name')
       for vs_name in $virtualservers
         do
           vs_vip=$(yq -t r $1 'load_balancers[*]' -j | \
           jq -r --arg lb_name  "$lb_name" --arg vs_name "$vs_name" \
           '.[] | select(.name == $lb_name)| .virtual_servers[] | select(.name == $vs_name) | .virtual_ip')
           Delete_NSX_LB_VirtualServer "$vs_name" "$vs_vip"
         done

       serverpools=$(yq -t r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .server_pools[] | .name')
       for pool_name in $serverpools
         do
          Delete_NSX_LB_ServerPool "$pool_name"
         done

       # monitors: yq -t r $1 'load_balancers[*]' -j | jq -r '.[] | .monitors[]'
       monitors=$(yq -t r $1 'load_balancers[*]' -j | \
       jq -r --arg lb_name "$lb_name" '.[] | select(.name = $lb_name)| .monitors[] | .name')
       for mon_name in $monitors
         do
           Delete_NSX_LB_Monitor "$mon_name"
         done
     done
 fi
}
