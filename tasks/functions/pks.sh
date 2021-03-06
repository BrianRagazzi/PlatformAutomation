compare_clusters() {
 # $1 - Config File
 # $2  - PKSCLI

 # compare the name of each cluster that exists to the list
 # if a cluster exists that should not, delete it

 # compare the list of clusters to those that exist
 # if a listed cluster exists, compare the num_nodes
 #    if the num_nodes does not match, resize it
 # if a listed cluster does not exist, create it with the num_nodes

pks_clusters_json=$(yq r $1 -j)  

# Remove extra clusters
 clusterct=$($2 clusters --json | jq -r '. | length')
 if [ $clusterct == "0" ]; then
   echo "No existing clusters"
 else
   currclusters=$($2 clusters --json | jq -r '.[] | .name')
   for clustername in $currclusters
     do
       namechk=$(echo $pks_clusters_json | jq -r --arg name "$clustername" '.clusters[] | select(.name == $name) | .name')
       if [ -z $namechk ]; then
         echo "Cluster $clustername will be deleted"
         $2 delete-cluster $clustername --non-interactive
       # else
       #   echo "Cluster $clustername already exists"
       fi
     done
 fi

#Create Missing Clusters, resize current clusters
 reqclusterct=$(echo $pks_clusters_json | jq -r '.clusters[] | length')
 if [ reqclusterct == "0" ]; then
   echo "No requested clusters!!?"
 else
  reqclusters=$(echo $pks_clusters_json | jq -r '.clusters[] | .name')
  for reqclustername in $reqclusters
    do
      # set +eu
      reqnodes=$(echo $pks_clusters_json | jq -r --arg name "$reqclustername" '.clusters[] | select(.name == $name) | .num_nodes')
      clusterchk=$($PKSCLI clusters --json | jq '.[] | .name')
      if [[ "$clusterchk" != *"$reqclustername"* ]]; then
        reqext=$(echo $pks_clusters_json | jq -r --arg name "$reqclustername" '.clusters[] | select(.name == $name) | .exthostname')
        reqplan=$(echo $pks_clusters_json | jq -r --arg name "$reqclustername" '.clusters[] | select(.name == $name) | .plan')
        if [ -z $reqplan ]; then
          echo "Cluster $reqclustername missing Plan"
        else
          if [ -z $reqext ]; then
            echo "Cluster $reqclustername missing External FQDN"
          else
            plannamechk=$($PKSCLI plans --json | jq '.[] | .name')
            if [[ "$plannamechk" == *"$reqplan"* ]]; then
              echo "cluster $reqclustername does not exist, create it"
              $2 create-cluster $reqclustername -e $reqext -p $reqplan -n $reqnodes --non-interactive
            else
              echo "Cannot create requested cluster; $reqplan is not a valid plan name"
            fi
          fi
        fi
      else
        echo "cluster $reqclustername already exists, check size"
        currnodes=$($2 cluster $reqclustername --json | jq '.parameters.kubernetes_worker_instances')
        if [ $currnodes == $reqnodes ]; then
          echo "$reqclustername already has $currnodes nodes"
        else
          echo "Need to scale cluster from $currnodes to $reqnodes"
          $2 resize $clustername --num-nodes $reqnodes --non-interactive
        fi
      fi
      # set -eu
    done
  fi

}
