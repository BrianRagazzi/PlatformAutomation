Create_Local_users() {
 # $1 - Config File
 users=$(yq -t r $1 'local_users[*].name' -j | jq -r '.[]')
 for username in $users
   do
     # username=$(echo $user | jq -r '.name')
     userchk=$(uaac user get $username -a username)
     if [ "$userchk" == " username: $username" ]; then
       echo "User $username already exists"
     else
       useremail=$(yq -t r $1 'local_users[*]' -j | \
       jq -r --arg name "$username" '.[] | select(.name == $name) | .emails')
       if [ $useremail == "null" ]; then
         useremail = $username
       fi
       userpass=$(yq -t r $1 'local_users[*]' -j | \
       jq -r --arg name "$username" '.[] | select(.name == $name) | .password')
       uaac user add "$username" --emails "$useremail" -p "$userpass"
     fi
   done
}


Group_Members_Maps() {
 # $1 - Config File
 groups=$(yq -t r $1 'groups[*].name' -j | jq -r '.[]')
 for groupname in $groups
   do
     memberct=$(yq -t r $1 'groups[*]' -j | \
     jq -r --arg groupname $groupname '.[] | select(.name == $groupname) | .members | length')
     if [ $memberct == "0" ]; then
       echo "group $groupname has no members"
     else
       groupmembers=$(yq -t r $1 'groups[*]' -j | \
       jq -r --arg groupname $groupname '.[] | select(.name == $groupname) | .members[].name')
       for member in $groupmembers
        do
          if [ $member != "null" ]; then
            #echo uaac member add $groupname  "$member"
            uaac member add $groupname $member
          fi
        done
      fi
      mapct=$(yq -t r $1 'groups[*]' -j | \
      jq -r --arg groupname $groupname '.[] | select(.name == $groupname) | .group_maps | length')
      if [ $mapct == "0" ]; then
        echo "group $groupname has no group_maps"
      else
        groupmaps=$(yq -t r $1 'groups[*]' -j | \
        jq -r --arg groupname $groupname '.[] | select(.name == $groupname) | .group_maps[].dn')
        for dn in $groupmaps
         do
           if [ $dn != "null" ]; then
             #echo uaac group map $groupname  "$dn"
             uaac group map $groupname "$dn"
           fi
         done


      fi
   done
}
