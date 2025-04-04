#!/usr/bin/env bash

cat << 'EOF' > "credhub.crt"
-----BEGIN CERTIFICATE-----
MIIDUTCCAjmgAwIBAgIVAMpKOuiNNerWf6AbKoXmQkrsYH1bMA0GCSqGSIb3DQEB
CwUAMB8xCzAJBgNVBAYTAlVTMRAwDgYDVQQKDAdQaXZvdGFsMB4XDTI1MDIxOTE2
MTk0MFoXDTI5MDIxOTE2MTk0MFowHzELMAkGA1UEBhMCVVMxEDAOBgNVBAoMB1Bp
dm90YWwwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCcz1YPJPcqOsaW
j5vSGPiWfZ7F3Sjkcn4eTFeF5BzY3zwWl/PY2kXvI1p90uNv90raAuiKk40A+8hj
II+FZ4aoI6Hv1YKtPx7boL8dX6d4ZTdLW9UwkR5DEfLl6Jh89kBgbYxw8YpnGv3A
knZBbaFU4ik1z+nE9ufBsc6bWIFGlSHUycC49TSP6Ck1tAuz5TvNA8K92KyZPL+B
OWcQ8fEhsNp7Hc2IHhY4BQpk0JNvFbpRI5ZxFwqw2pLveMGAl8QlNR+Odvy5MDVY
qTyu2CeB7RBLqImGR7NAd4MfBlNQjlcBxThqzsEYSdnB1ie/wg==
-----END CERTIFICATE-----
EOF

export TEAMNAME=homelab

# pivnet token
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
