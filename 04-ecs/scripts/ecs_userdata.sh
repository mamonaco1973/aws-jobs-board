#!/bin/bash
cat <<EOF > /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_ENABLE_CONTAINER_METADATA=true
ECS_AWSVPC_BLOCK_IMDSV1=true
EOF

