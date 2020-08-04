Create_Local_users() {
 # $1 - Config File
 users=$(yq r $1 'local_users[*].name' -j | jq -r '.[]')
 for username in $users
   do
     # username=$(echo $user | jq -r '.name')
     set +eu
     userchk=$(uaac user get $username -a username)
     set -eu
     if [ "$userchk" == "  username: $username" ]; then
       echo "User $username already exists"
     else
       useremail=$(yq r $1 'local_users[*]' -j | \
       jq -r --arg name "$username" '.[] | select(.name == $name) | .emails')
       if [ $useremail == "null" ]; then
         useremail=$username
       fi
       userpass=$(yq r $1 'local_users[*]' -j | \
       jq -r --arg name "$username" '.[] | select(.name == $name) | .password')
       uaac user add "$username" --emails "$useremail" -p "$userpass"
     fi
   done
}

Create_Local_clients() {
 # $1 - Config File
 clientct=$(yq r $1 'local_clients[*]' -j)
 if [ $clientct == "null" ]; then
   echo "no clients to add"
 else
   clients=$(yq r $1 'local_clients[*].client_name') # -j | jq -r '.[]')
   for clientname in $clients
     do
       set +eu
       clientchk=$(uaac client get $clientname)
       if [[ "$clientchk" == *"NotFound"* ]]; then
         echo "Creating client $clientname"
         authorities=$(yq r $1 'local_clients[*]' -j | \
         jq -r --arg name "$clientname" 'select(.client_name == $name) | .authorities')
         clientsecret=$(yq r $1 'local_clients[*]' -j | \
         jq -r --arg name "$clientname" 'select(.client_name == $name) | .client_secret')
         uaac client add $clientname -s $clientsecret --authorized_grant_types client_credentials --authorities $authorities
       else
         echo "client $clientname already exists"
       fi
       set -eu
     done
   fi
}


Group_Members_Maps() {
 # $1 - Config File
 set +eu
 SAVEIFS=$IFS
 IFS=$(echo -en "\n\b")
 groups=$(yq r $1 'groups[*].name') # -j | jq -r '.[]')
 for groupname in $groups
   do
     memberct=$(yq r $1 'groups[*]' -j | \
     jq -r --arg groupname $groupname 'select(.name == $groupname) | .members | length')
     if [ $memberct == "0" ]; then
       echo "group $groupname has no members"
     else
       groupmembers=$(yq r $1 'groups[*]' -j | \
       jq -r --arg groupname $groupname 'select(.name == $groupname) | .members[].name')
       for member in $groupmembers
        do
          if [ $member != "null" ]; then
            #echo uaac member add $groupname  "$member"
            uaac member add $groupname $member
          fi
        done
      fi
      mapct=$(yq r $1 'groups[*]' -j | \
      jq -r --arg groupname $groupname 'select(.name == $groupname) | .group_maps | length')
      if [ $mapct == "0" ]; then
        echo "group $groupname has no group_maps"
      else
        groupmaps=$(yq r $1 'groups[*]' -j | \
        jq -r --arg groupname $groupname 'select(.name == $groupname) | .group_maps[].dn')
        for dn in $groupmaps
         do
           if [ "$dn" != "null" ]; then
             #echo uaac group map $groupname  "$dn"
             uaac group map --name $groupname "$dn"
           fi
         done
      fi
   done
 IFS=$SAVEIFS
 set -eu
}
