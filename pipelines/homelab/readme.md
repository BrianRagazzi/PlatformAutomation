# Homelab folder contains pipelines for the homelab team


## Preparation
### credhub
#### Login - on opsmanager
```
ssh ubuntu@om-pa.lab.brianragazzi.com -i ~/.ssh/ops-mgr-ssh-key
```
* Check that env vars are set in .profile
```
credhub api  https://192.168.102.11:8844 --ca-cert=/var/tempest/workspaces/default/root_ca_certificate
credhub login --client-name=$BOSH_CLIENT --client-secret=$BOSH_CLIENT_SECRET
export CONCOURSE_CREDHUB_SECRET=$(credhub get -n /p-bosh/concourse/credhub_admin_secret -q)
export CONCOURSE_CA_CERT=$(credhub get -n /p-bosh/concourse/atc_tls -k ca -q)
```
### login to credhub on concourse:
```
credhub login \
  --server "https://concourse.lab.brianragazzi.com:8000" \
  --client-name=credhub_admin \
  --client-secret="${CONCOURSE_CREDHUB_SECRET}" \
  --ca-cert "${CONCOURSE_CA_CERT}"

```


#### Add/Set Credentials
```
export TEAMNAME=homelab
# Pivnet
credhub set --name /pipeline/vsphere/pivnet-refresh-token --type value --value your-credhub-refresh-token
credhub set --name /pipeline/vsphere/credhub_client --type value --value ops_manager
credhub set --name /concourse/main/pivnet-refresh-token --type value --value refreshtokenhere
credhub set --name /concourse/$TEAMNAME/pivnet-refresh-token --type value --value refreshtokenhere

# credhub
credhub set --name /concourse/$TEAMNAME/credhub_client --type value --value ops_manager
credhub set --name /concourse/$TEAMNAME/credhub_secret --type value --value clientsecrethere
credhub set --name /concourse/$TEAMNAME/credhub_server --type value --value https://192.168.102.11:8844
credhub set --name /concourse/$TEAMNAME/credhub_ca_cert --type value --value "$(cat /var/tempest/workspaces/default/root_ca_certificate)"

# S3
credhub set --name /concourse/$TEAMNAME/s3_endpoint --type value --value https://minio.lab.brianragazzi.com
credhub set --name /concourse/$TEAMNAME/s3_buckets_pivnet_products --type value --value binaries
credhub set --name /concourse/$TEAMNAME/s3_buckets_backup_bucket  --type value --value platform-backup
credhub set --name /concourse/$TEAMNAME/s3_region_name --type value --value us-east-1
credhub set --name /concourse/$TEAMNAME/s3_access_key_id --type value --value ACCESSKEYHERE
credhub set --name /concourse/$TEAMNAME/s3_secret_access_key --type value --value SECRETKEYHERE

# Github
credhub set --name /concourse/$TEAMNAME/github_token --type value --value githubtokenhere

# NSX
credhub set --name /concourse/$TEAMNAME/nsx_admin_password --type value --value nsxadminpassword
credhub set --name /concourse/$TEAMNAME/nsx_ca_cert --type value --value "$(cat ./test/nsx.crt)"

# vCenter
credhub set --name /concourse/$TEAMNAME/vcenter_admin_password --type value --value password

# OpsMgr
# credhub set --name /concourse/$TEAMNAME/opsman_host --type value --value 'https://om-tkgi.lab.brianragazzi.com'
credhub set --name /concourse/$TEAMNAME/opsman_host --type value --value 'https://om-tpcf.lab.brianragazzi.com'
credhub set --name /concourse/$TEAMNAME/opsman_ssh_public_key --type value --value "$(cat /home/ubuntu/.ssh/authorized_keys)"
credhub set --name /concourse/$TEAMNAME/opsman_password --type value --value  opsmanpass
credhub set --name /concourse/$TEAMNAME/opsman_decryption_passphrase --type value --value opsmandecrypt

# AD
## Bind Service Account PW:
credhub set --name /concourse/$TEAMNAME/properties_uaa_ldap_credentials_password --type value --value mypassword

##
TLS Cert
credhub set --name /concourse/$TEAMNAME/ldap_server_ssl_cert --type value --value "$(cat ./test/rootca.crt)"

# TKGI Cert - Also used by TAS/TPCF!
credhub set --name /concourse/$TEAMNAME/pivotal-container-service_pks_tls_cert_pem --type value --value "$(cat ./test/wildcard.crt)"
credhub set --name /concourse/$TEAMNAME/pivotal-container-service_pks_tls_private_key_pem --type value --value "$(cat ./test/wildcard.key)"

```
#### Dump to check
```
credhub export
```


### Login
```
fly -t ci login -k  -c "https://concourse.lab.brianragazzi.com/"  -n homelab -u "admin" -p PASSWORD
```

## Pipelines
```
fly -t ci set-pipeline -p fetch-binaries -c pipeline-fetch.yml -l ../../params/homelab/params-homelab-fetch.yml --check-creds -n
fly -t ci up -p fetch-binaries
```
```
fly -t ci set-pipeline -p nsx-configure -c pipeline-nsx.yml -l ../../params/homelab/params-homelab-tas.yml --check-creds -n
fly -t ci up -p nsx-configure
```
```
fly -t ci set-pipeline -p tkgi-configure -c pipeline-tkgi.yml -l ../../params/homelab/params-homelab.yml --check-creds -n
fly -t ci up -p tkgi-configure
```
```
fly -t ci set-pipeline -p test-opsman -c opsman.yml -l ../../params/homelab/params-homelab.yml --check-creds -n
fly -t ci up -p test-opsman
```
```
fly -t ci set-pipeline -p tpcf-configure -c pipeline-tpcf.yml -l ../../params/homelab/params-homelab-tas.yml --check-creds -n
fly -t ci up -p tpcf-configure
```
```
fly -t ci set-pipeline -p genai-configure -c pipeline-genai.yml -l ../../params/homelab/params-homelab-tas.yml --check-creds -n
fly -t ci up -p genai-configure
```
```
fly -t ci set-pipeline -p hub-configure -c pipeline-hub.yml -l ../../params/homelab/params-homelab-hub.yml --check-creds -n
fly -t ci up -p genai-configure
```
