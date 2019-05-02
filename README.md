# PlatformAutomation


Starting from:
http://docs.pivotal.io/platform-automation/v2.1/


Prereqs:

* Deployed concourse
* Platform automation
* env file:  (env.yml) Credentials for om cli login to Ops Manager
* auth file: Subnet of env file
* opsmanager config: (opsman.yml)  
  * Run https://opsman/api/v0/staged/director/properties
  * Save output as json
  * convert json to yaml
* director config: (director.yml)
  * use om cli tool to get config from manually-deployed opsmgr
  * om --target https://opsman -u admin -p Password -k staged-director-config
* product config files:
* optional credhub
