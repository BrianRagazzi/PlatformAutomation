#!/bin/bash


web_json=$(cat <<-EOF
{
    "name": "pas_web_vm_extension",
    "cloud_properties": {
        "nsxt": {
            "lb": {
                "server_pools": [
                    {
                        "name": "pas-web-pool"
                    }
                ]
            }
        }
    }
}
EOF
)


echo $web_json
jq -r "$web_json"
