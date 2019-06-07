Get the Director Config from:

https://opsman/api/v0/staged/director/properties

IaaS configurations:

https://opsman/api/v0/staged/director/iaas_configurations



staged-director-config:
om --target https://opsman -u admin -p Password -k staged-director-config --include--placeholders
or
om --env env.yml staged-director-config --include--placeholders
