
# Add admin user to PAS

uaac target uaa.system.domain --skip-ssl-validation
uaac token client get admin -s <uaa.admin_client.credential.password>

uaac user add pksadmin -p password --emails pksadmin@domain

uaac member add cloud_controller.admin pksadmin
uaac member add uaa.admin pksadmin
uaac member add scim.read pksadmin
uaac member add scim.write pksadmin


# Add cf LDAP user
## Assumptions:
 * domain.com is LDAP
 * LDAP is configured in CF config
 * my-org exists


cf target https://api.system.domain.com
cf login (login as admin with admin_client_credentials)

cf create-user cfadmin@domain.com --origin ldap
cf set-org-role cfadmin@domain.com my-org OrgManager
cf set-org-role cfadmin@domain.com my-org BillingManager
cf set-org-role cfadmin@domain.com my-org OrgAuditor
