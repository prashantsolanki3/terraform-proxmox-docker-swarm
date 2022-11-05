#!/bin/bash

# https://gist.github.com/RafaelWO/290b764e88933b0c0769b6d2394fcad2

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update
apt-get upgrade -y
apt-get install -y nvidia-driver-515-server nvidia-docker2

# GPU_ID=$(nvidia-smi -a | grep UUID | awk '{print substr($4,0,12)}')
GPU_ID=GPU-3d7eaaf5
cat << EOF > /etc/docker/daemon.json
{ 
  "runtimes": { 
    "nvidia": { 
      "path": "/usr/bin/nvidia-container-runtime", 
      "runtimeArgs": [] 
    } 
  }, 
  "default-runtime": "nvidia", 
  "node-generic-resources": [ 
    "NVIDIA-GPU=$GPU_ID" 
    ] 
}
EOF

echo "swarm-resource = \"DOCKER_RESOURCE_GPU\"" >> /etc/nvidia-container-runtime/config.toml

systemctl restart docker



