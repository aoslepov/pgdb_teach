#!/bin/bash

#yc config set service-account-key key.json
#yc config set cloud-id b1gi89kth4ma2ek6b8i3
#yc config set folder-id b1g7jn3kmfd43b53ui4s

#yc iam create-token

export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)


terraform plan
terraform apply
#terraform destroy
