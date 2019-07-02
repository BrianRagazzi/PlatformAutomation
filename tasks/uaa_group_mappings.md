as long as UAA is configured to use LDAP,
login to uaac targeting uaa on PKS api

uaac group map --name pks.clusters.admin GROUP_DN
uaac group map --name pks.clusters.manager GROUP_DN

GROUP_DN example: CN=PKS-admins,OU=Security Groups,DC=ragazzilab,DC=com

 
