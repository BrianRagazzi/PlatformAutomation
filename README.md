# PlatformAutomation


# Pipelines

## RETRIEVE
Save binaries for run-time pipelines to local S3


### To Do ###
* Issue with Harbor stemcell - RESOLVED

### Icebox ###
* Save Kubectl & PKS cli tools to S3 - Investigated.  Using om prevents use of mutliple globs,would have to create a download-product-config and resource for each OS for both PKs cli and kubectl

## PAS
Install PAS, NSX-T NCP & Healthwatch onto 3 AZs

### To Do ###
* Use S3 resource paths that match retrieve pipeline
* Add step to create ssh keypair in credhub for opsman, apply public ssh key to OVF

## PKS
Install PKS & Harbor on 3 AZs
### To Do ###
* Use S3 resource paths that match retrieve pipeline
* Add step to create ssh keypair in credhub for opsman, apply public ssh key to OVF
* Allow generation of certs via credhub vs import ent CA-signed
