#!/bin/bash

export RESONITE_HEADLESS_ENVIRONMENT="東京"
export VPC_NAME=resonite-headless-network
export SUBNET_NAME=subnet-${VPC_NAME}
export REGION="asia-northeast1"
export ZONE="asia-northeast1-b"
export SUBNET_RANGE="192.168.1.0/24"
export FIREWALL_TAG_NAME=resonite-headless
export RESONITE_HEADLESS_SERVER_INSTANCE_NAME=resonite-headless-server
export IMAGE_PROJECT="ubuntu-os-cloud"
export IMAGE_FAMILY_SCOPE="zonal"
export IMAGE_FAMILY="ubuntu-minimal-2404-lts-amd64"
export MACHINE_TYPE="t2d-standard-2"
export SETUP_RESONITE_HEADLESS_SERVER_SCRIPT="setup-config.yaml"
export MACHINE_IMAGE_NAME=resonite-headless
PROJECT_ID=$(gcloud projects list --format="value(projectId)"|fzf)
export CLOUDSDK_CORE_PROJECT=${PROJECT_ID}
export CLOUDSDK_COMPUTE_ZONE=${ZONE}
export CLOUDSDK_COMPUTE_REGION=${REGION}

