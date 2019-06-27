# PlatformAutomation


# Pipelines


## PAS
Install PAS, NSX-T NCP & Healthwatch onto 3 AZs using binaries from local S3

### To Do ###
* Enable LDAP integration
* Create new users and add to scopes post-deploy
* Validate NSX-T configuration meets requirements

## PKS
Install PKS & Harbor on 3 AZs using binaries from local S3
### Features ###
* Credhub for secrets
* LDAP Integration
* Syslog configured
* Auto-add LDAP group to role

### To Do ###
* Validate NSX-T configuration meets requirements


## RETRIEVE
Save binaries for run-time pipelines to local S3


### To Do ###


### Icebox ###
* Save Kubectl & PKS cli tools to S3 - Investigated.  Using om prevents use of mutliple globs,would have to create a download-product-config and resource for each OS for both PKs cli and kubectl
