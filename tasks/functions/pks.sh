compare_clusters() {
 # $1 - Config File
 # $2  - PKSCLI

 # compare the name of each cluster that exists to the list
 # if a cluster exists that should not, delete it

 # compare the list of clusters to those that exist
 # if a listed cluster exists, compare the num_nodes
 #    if the num_nodes does not match, resize it
 # if a listed cluster does not exist, create it with the num_nodes

pks_clusters_json=$(yq -t r $1 -j)

# Remove extra clusters
 clusterct=$($2 clusters --json | jq '.[] | length')
 if [ $clusterct == "0" ]; then
   echo "No existing clusters"
 else
   currclusters=$($2 clusters --json | jq '.[] | .name')
   for clustername in $currclusters
     do
       namechk=$(echo pks_clusters_json | jq -r --arg name "$clustername" '.clusters[] | select(.name == $name) | .name')
       if [ $namechk == $clustername ]; then
         echo "Cluster $clustername alreeady exists"
       else
         echo "Cluster $clustername will be deleted"
         echo "$2 delete-cluster $clustername --non-interactive"
       fi
     done
 fi

#Create Missing Clusters, resize current clusters
 reclusterct=$(echo pks_clusters_json | jq -r '.clusters[] | length')
 if [ reqclusterct == "0" ]; then
   echo "No requested clusters!!?"
 else
  reqclusters=$(echo pks_clusters_json | jq -r '.clusters[] | .name')
  for reqclustername in $reqclusters
    do
      reqnodes=$(echo pks_clusters_json | jq -r --arg name "$reqclustername" '.clusters[] | select(.name == $name) | .num_nodes')
      clusterchk=$($2 cluster $reqclustername)
      if [[ "$clusterchk" == *"not found"* ]]; then
        reqext=$(echo pks_clusters_json | jq -r --arg name "$reqclustername" '.clusters[] | select(.name == $name) | .exthostname')
        reqplan=$(echo pks_clusters_json | jq -r --arg name "$reqclustername" '.clusters[] | select(.name == $name) | .plan')
        echo "cluster $reqclustername does not exist, create it"
        echo "$2 create-cluster $reqclustername -e $reqext -p $reqplan -n $reqnodes --non-interactive"
      else
        echo "cluster $reqclustername already exists, check size"
        currnodes=$($2 cluster $reqclustername --json | jq '.parameters.kubernetes_worker_instances')
        if [ $currnodes == $reqnodes ]; then
          echo "num_nodes already correct"
        else
          echo "Need to scale cluster from $currnodes to $reqnodes"
          echo "$2 resize $clustername --num-nodes $reqnodes --non-interactive"
        fi
      fi
    done
  fi

}
