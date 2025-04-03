
# Notes
https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/platform-automation-toolkit-for-tanzu/5-2/vmware-automation-toolkit/docs-how-to-guides-installing-opsman.html

https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/concourse-for-tanzu/7-0/tanzu-concourse/installation-platform-automation-connect-and-test.html

credhub set \
  -n /concourse/main/provided-by-credhub \
  -t value \
  -v "World"



Add pivnet token to credhub:

```
credhub set --name /concourse/main/pivnet-refresh-token --type value --value your-credhub-refresh-token
```

fly -t ci set-pipeline \
  -n \
  -p cred-pipeline \
  -c credtest.yml \
  --check-creds

fly -t ci set-pipeline -p fetch-platauto -c fetch-pipeline.yml -l private-params-homelab-fetch.yml --check-creds -n

fly -t ci up -p fetch-platauto




Add to credhub:
- name: /pipeline/vsphere/credhub_client
  type: value
  value: credhub
- name: /pipeline/vsphere/credhub_secret
  type: value
  value: VMware1!
- name: /pipeline/vsphere/credhub_server
  type: value
  value: https://credhub.pae.ragazzilab.com:8844
- name: /pipeline/vsphere/credhub_ca_cert
  type: value
  value: |
    -----BEGIN CERTIFICATE-----
    MIIDfzCCAmegAwIBAgIQLjYGHcW8Ia1JvAwqn7vuFDANBgkqhkiG9w0BAQUFADBS
    MRMwEQYKCZImiZPyLGQBGRYDY29tMRowGAYKCZImiZPyLGQBGRYKcmFnYXp6aWxh
    YjEfMB0GA1UEAxMWcmFnYXp6aWxhYi1DT1JFQURDMS1DQTAeFw0xNDEyMTgxOTMz
    MzlaFw0yNDEyMTgxOTQzMzlaMFIxEzARBgoJkiaJk/IsZAEZFgNjb20xGjAYBgoJ
    kiaJk/IsZAEZFgpyYWdhenppbGFiMR8wHQYDVQQDExZyYWdhenppbGFiLUNPUkVB
    REMxLUNBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+NGGixl/a5DB
    nv1RKMJz32aXvgYbcg03oEwdAQlM3ENvoGaC6ESFnki6izBl5tQ9EnUBvirq2LPZ
    RL/1a8Ah2RgDD1pdL4h3Wv2EY/8zqlK26OxYOapdysqWLojPUkdNfyyBw9W1dCk7
    YDwoC55aQVkmL83KIOSQP/GEc0E25CXKkA8scktXRBqUSL8VNqb4wH4UEXvIgK+x
    NVSR0bNjNdcaXBiwLQov7Dk7+9zZ4pXudogNh4mmGPfrgYnskc7TscFl1ymNOQ8+
    l412RqrO7/83mGbpf7LT+rGXXZWhY0CtqRew3PgljhBnuA2K/C+T8p05XA/GSETb
    CpskdZazFQIDAQABo1EwTzALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAd
    BgNVHQ4EFgQUYiWuvUtgt6ruwFYsGG22doeTOkIwEAYJKwYBBAGCNxUBBAMCAQAw
    DQYJKoZIhvcNAQEFBQADggEBAJDjTjVQXJJ51W+lefpuunpzT0EPDM3I1+/A94yl
    FzKX4FlONkYCj/7wNtZ+B65a3CihOf0/q0hqmcHKiu6Ldt5tTYL3hvWs7l9m17Jg
    1M9IpuOUuEPo0v9qUn45J+42Of1L1/cSq5Q1mM59oN1UmNy9ik9DyS/yKDVdLGLo
    gL5nn4UebvZ2ofiAEQQgKCVox3HXseQ5ZQHU50S/7UYoOySIwdEwcdZhrQ8iNvNE
    Y+ZO5iSv4zVA1BuzFSa1pq6RhOm4XRt2s09FZOIpWtMqbixUil5ddYmWpIGkpGGy
    SyIq7aD3tt6rkNFhFiPKgOC4lRmjNlLNKzJ8zJNAd6wEcMk=
    -----END CERTIFICATE-----
- name: /pipeline/vsphere/s3_secret_access_key
  type: value
  value: MYSECRETKEY
- name: /pipeline/vsphere/s3_access_key_id
  type: value
  value: MYACCESSKEY
