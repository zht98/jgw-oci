#!/bin/bash

# ====== 基础配置 ======
TENANCY_OCID="ocid1.tenancy.oc1..aaaaaaaavenwd4zk7hxkm2tnhogpvakbqkkjkve3bedgrunjt4xor7wa7jxa"
USER_OCID="ocid1.user.oc1..aaaaaaaacwifr74uz3w3ksxkrwxu5lbtbutbioados3na5otwkhsn6pvjz2q"
COMPARTMENT_OCID="ocid1.tenancy.oc1..aaaaaaaavenwd4zk7hxkm2tnhogpvakbqkkjkve3bedgrunjt4xor7wa7jxa"
KEY_FILE="$HOME/.oci/oci_api_key.pem"
REGION="us-phoenix-1"

# ====== AD 列表（按 AD2 → AD3 → AD1 顺序轮询）======
AVAILABILITY_DOMAINS=("GrMI:PHX-AD-2" "GrMI:PHX-AD-3" "GrMI:PHX-AD-1")

# ====== 实例配置 ======
SHAPE="VM.Standard.A1.Flex"
OCPUS=2
MEMORY_GBS=12
BOOT_VOLUME_SIZE=50

# ====== 网络配置 ======
SUBNET_OCID="ocid1.subnet.oc1.phx.aaaaaaaafkk55rb4rrbzefpfcawvw6rwe4zgfsvfwloy6lczos2h6zrya4na"
ASSIGN_PUBLIC_IP=true

# ====== 镜像（Ubuntu 22.04 2026.01.29-0）======
IMAGE_OCID="ocid1.image.oc1.phx.aaaaaaaahzur55ghl5ypjy27zsuh7adac4ppnofrp2d3wuxu7iam4ibgkaia"

# ====== 日志 ======
LOG_FILE="/opt/oracle_create/create.log"