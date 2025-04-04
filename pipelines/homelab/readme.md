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
```



### Login
```
fly -t ci login   -c "https://concourse.lab.brianragazzi.com/"  -n homelab -u "admin" -p PASSWORD
```

## Pipelines
```
fly -t ci set-pipeline -p fetch-platauto -c pipeline-fetch.yml -l private-params-homelab-fetch.yml --check-creds -n
```
