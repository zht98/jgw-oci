#!/bin/bash

source /opt/oracle_create/config.sh
source /opt/oracle_create/utils.sh

log "开始尝试创建实例（轮询 AD2/AD3/AD1）..."

# ====== Cloud-Init 自动挂载脚本 ======
CLOUD_INIT=$(cat <<EOF
#cloud-config
runcmd:
  - lsblk
  - echo "等待数据盘 /dev/sdb 出现..."
  - sleep 5
  - sudo mkfs.ext4 /dev/sdb
  - sudo mkdir -p /data
  - sudo mount /dev/sdb /data
  - UUID=\$(blkid -s UUID -o value /dev/sdb)
  - echo "UUID=\$UUID /data ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
  - sudo chmod 777 /data
  - sudo mount -a
EOF
)

# base64 编码 cloud-init
CLOUD_INIT_B64=$(echo "$CLOUD_INIT" | base64 -w 0)

for AD in "${AVAILABILITY_DOMAINS[@]}"; do
    log "尝试 AD: $AD"

    RESPONSE=$(oci compute instance launch \
        --availability-domain "$AD" \
        --compartment-id "$COMPARTMENT_OCID" \
        --shape "$SHAPE" \
        --shape-config "{\"ocpus\": $OCPUS, \"memoryInGBs\": $MEMORY_GBS}" \
        --subnet-id "$SUBNET_OCID" \
        --assign-public-ip "$ASSIGN_PUBLIC_IP" \
        --image-id "$IMAGE_OCID" \
        --boot-volume-size-in-gbs "$BOOT_VOLUME_SIZE" \
        --metadata "{\"user_data\":\"$CLOUD_INIT_B64\"}" \
        --region "$REGION" \
        --auth api_key 2>&1)

    # ====== 成功判断 ======
    if echo "$RESPONSE" | grep -q "\"lifecycle-state\": \"PROVISIONING\""; then
        log "实例创建成功！"

        INSTANCE_ID=$(echo "$RESPONSE" | grep -o 'ocid1.instance[^"]*')
        log "实例 ID: $INSTANCE_ID"

        # ====== 创建 120GB 数据盘 ======
        log "创建 120GB 数据盘..."
        VOLUME_ID=$(oci bv volume create \
            --availability-domain "$AD" \
            --compartment-id "$COMPARTMENT_OCID" \
            --size-in-gbs 120 \
            --display-name "data-120" \
            --query 'data.id' \
            --raw-output \
            --region "$REGION")

        log "数据盘 ID: $VOLUME_ID"

        # ====== 等待数据盘可用 ======
        log "等待数据盘变为 AVAILABLE..."
        oci bv volume wait-for-state --volume-id "$VOLUME_ID" --state AVAILABLE --region "$REGION"

        # ====== 挂载数据盘到实例 ======
        log "挂载数据盘到实例..."
        oci compute volume-attachment attach \
            --instance-id "$INSTANCE_ID" \
            --volume-id "$VOLUME_ID" \
            --type paravirtualized \
            --region "$REGION"

        log "数据盘已挂载，Cloud-Init 将自动格式化、挂载到 /data，并设置权限 777"

        exit 0
    fi

    # ====== 容量不足 ======
    if echo "$RESPONSE" | grep -q "Out of host capacity"; then
        log "AD $AD 无容量，继续尝试下一个 AD..."
        continue
    fi

    # ====== 限流处理 ======
    if echo "$RESPONSE" | grep -q "\"status\": 429"; then
        log "API 限流（429），等待 3 秒后继续..."
        sleep 3
        continue
    fi

    log "其他错误：$RESPONSE"
done

# ====== 本轮结束 ======
RANDOM_WAIT=$((RANDOM % 4 + 2))
log "三个 AD 都失败，本轮结束，随机等待 ${RANDOM_WAIT} 秒..."
sleep $RANDOM_WAIT

exit 1