# PlatformAutomation


# Pipelines

## PAS
Install PAS, NSX-T NCP & Healthwatch onto 3 AZs using binaries from local S3

### Features ###
* Configure NSX-T Objects, including load-balancer from yml
* Credhub for secrets
* Syslog configured
* LDAP integration configured
* Add LDAP groups to UAA admin scopes post-deploy
* Disable CF errands post-deploy

### To Do ###
* Add/include PCF Metrics
* Auto-create Orgs, spaces and LDAP-linked users (https://github.com/pivotalservices/uaausersimport)

## PKS
Configure NSX-T Objects, Install PKS & Harbor on 3 AZs using binaries from local S3

### Features ###
* Credhub for secrets
* LDAP Integration
* Syslog configured
* Auto-add LDAP group to role
* Configures NSX-T Objects (minus super-user)

### To Do ###
* Prep cluster for helm & tiller



## RETRIEVE
Save binaries for run-time pipelines to local S3

### To Do ###
* Set builds-to-keep to a small number to prevent exhausting storage on workers

### Icebox ###
* Save Kubectl & PKS cli tools to S3 - Investigated.  Using om prevents use of multiple globs,would have to create a download-product-config and resource for each OS for both PKs cli and kubectl


## backup

### To Do ###
* May abandon since concourse cannot get to deployments via FQDN
* New Tasks
* Determine where it can be run, what is needed in order for concourse to reach targets


# Functions & Custom Tasks
## nsxt.sh
### To Do ###
* Add and finish creation of superuser; figure out how to save cert and key
