# Homelab folder contains pipelines for the homelab team


## Preparation
### credhub
#### Login - on opsmanager
* Check that env vars are set in .profile
```
credhub api  https://192.168.102.11:8844 --ca-cert=/var/tempest/workspaces/default/root_ca_certificate
credhub login --client-name=$BOSH_CLIENT --client-secret=$BOSH_CLIENT_SECRET
```
#### Add/Set Credentials
```
credhub set --name /pipeline/vsphere/pivnet-refresh-token --type value --value your-credhub-refresh-token
credhub set --name /pipeline/vsphere/credhub_client --type value --value ops_manager
credhub set --name /concourse/main/pivnet-refresh-token --type value --value refreshtokenhere
credhub set --name /concourse/$TEAMNAME/pivnet-refresh-token --type value --value refreshtokenhere
# credhub
credhub set --name /concourse/$TEAMNAME/credhub_client --type value --value ops_manager
credhub set --name /concourse/$TEAMNAME/credhub_secret --type value --value clientsecrethere
credhub set --name /concourse/$TEAMNAME/credhub_server --type value --value https://192.168.102.11:8844
credhub set --name /concourse/$TEAMNAME/credhub_ca_cert --type certificate -c credhub.crt
# S3
credhub set --name /concourse/$TEAMNAME/s3_endpoint --type value --value https://minio.lab.brianragazzi.com
credhub set --name /concourse/$TEAMNAME/s3_buckets_pivnet_products --type value --value binaries
credhub set --name /concourse/$TEAMNAME/s3_region_name --type value --value us-east-1
credhub set --name /concourse/$TEAMNAME/s3_access_key_id --type value --value ACCESSKEYHERE
credhub set --name /concourse/$TEAMNAME/s3_secret_access_key --type value --value SECRETKEYHERE
# Github
credhub set --name /concourse/$TEAMNAME/github_token --type value --value githubtokenhere
```

### Login
```
fly -t ci login   -c "https://concourse.lab.brianragazzi.com/"  -n homelab -u "admin" -p PASSWORD
```

## Pipelines
```
fly -t ci set-pipeline -p fetch-platauto -c pipeline-fetch.yml -l private-params-homelab-fetch.yml --check-creds -n
```
