Credhub_Set_Cred() {
 # $1 = CREDHUB_CLIENT
 # $2 = CREDHUB_SECRET
 # $3 = CREDHUB_SERVER ex: 192.168.100.200:8844
 # $4 = CRED_NAME
 # $5 = CRED_TYPE
 # $6 = CRED_VALUE

 export CREDHUB_CLIENT=$1
 export CREDHUB_SECRET=$2
 export CREDHUB_SERVER=$3

 credhub --version

 credhub set -n $CRED_NAME -t $CRED_TYPE -v $CRED_VALUE

}
