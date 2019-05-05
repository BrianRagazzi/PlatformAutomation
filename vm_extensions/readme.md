Get UAA Token by:

1. SSH into Ops manager
2. Add FQDN of opsmanager to /etc/hosts using the internal/non-NAT address
3. run "uaac target https://OPS-MAN-FQDN/uaa"
4. run "uaac token owner get".  
 Enter "opsman" for Client ID
 Leave client secret blank (hit enter)
 Enter "admin" (where this is the account you logon to OpsMan GUI with)
 Enter the password for that account
5. run "uaac contexts"
6. Save the access_token value for the opsman client_id
 
