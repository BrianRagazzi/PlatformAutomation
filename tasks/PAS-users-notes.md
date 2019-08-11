
# Add admin user to PAS
## Notes
  * This adds a LOCAL account as an admin, not tied to LDAP

uaac target uaa.system.domain.com --skip-ssl-validation

uaac token client get admin -s <uaa.admin_client.credential.password>

uaac user add pasadmin -p password --emails pasadmin@domain.com

uaac member add cloud_controller.admin pasadmin

uaac member add uaa.admin pasadmin

uaac member add scim.read pasadmin

uaac member add scim.write pasadmin

# Add admin user to PAS
## Notes
  * This adds an LDAP account as an admin
## Assumptions
  * "group-distinguished-name" is the DN for an existing group in LDAP

uaac target uaa.system.domain.com --skip-ssl-validation

uaac token client get admin -s <uaa.admin_client.credential.password>

uaac user add pasadmin@domain.com --email pasadmin@domain.local --origin ldap

uaac member add cloud_controller.admin pasadmin@domain.com

uaac member add uaa.admin pasadmin@domain.com

uaac member add scim.read pasadmin@domain.com

uaac member add scim.write pasadmin@domain.com


# Grant Admin roles to LDAP Group
## Assumptions
  * "group-distinguished-name" is the DN for an existing group in LDAP

uaac target uaa.system.domain.com --skip-ssl-validation

uaac token client get admin -s <uaa.admin_client.credential.password>

uaac group map --name cloud_controller.admin  "group-distinguished-name"

uaac group map --name scim.read  "group-distinguished-name"

uaac group map --name scim.write  "group-distinguished-name"


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
