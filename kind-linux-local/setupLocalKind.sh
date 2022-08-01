#!/bin/sh
set -xe

sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512

FILE=./localEnv.sh
if test -f "$FILE"; then
  . ./localEnv.sh
else
  echo "Please create the ./localEnv.sh for your environment with following values"
  echo "export reg_name='kind-registry'"
  echo "export reg_port='5001'"
  echo "#your external ip like 192.168.1.101"
  echo "export postgres_host=192.168.1.101"
  echo "export postgres_port=5432"
  echo "export mongo_host=192.168.1.101"
  echo "export mongo_port=27017"
  echo "export docker_user="
  echo "export docker_password="
fi


. ./localEnv.sh

if [ $postgres_port = "your_postgres_port" ] ;then
  echo "Please create the ./localEnv.sh for your environment"
  exit 1
fi

#clean up
kind delete clusters --all




if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:5000"]
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
EOF

# connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF


kubectl cluster-info --context kind-kind


kubectl create namespace cert-manager
kubectl apply  \
  -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml

sleep 100


echo 'before setting up keycloak you need to create a fresh database for keycloak in\
 and configure environment appropriately postgres'



cat <<EOF | kubectl apply -f -
---
kind: "Service"
apiVersion: "v1"
metadata:
  name: "postgres"
spec:
  ports:
    -
      name: "postgres"
      protocol: "TCP"
      port: 5432
      targetPort: ${postgres_port}
      nodePort: 0
---
kind: "Endpoints"
apiVersion: "v1"
metadata:
  name: "postgres"
subsets:
  -
    addresses:
      -
        ip: "${postgres_host}"
    ports:
      -
        port: ${postgres_port}
        name: "postgres"
---
kind: "Service"
apiVersion: "v1"
metadata:
  name: "mongo"
spec:
  ports:
    -
      name: "mongo"
      protocol: "TCP"
      port: 27017
      targetPort: ${mongo_port}
      nodePort: 0
---
kind: "Endpoints"
apiVersion: "v1"
metadata:
  name: "mongo"
subsets:
  -
    addresses:
      -
        ip: "${mongo_host}"
    ports:
      -
        port: ${mongo_port}
        name: "mongo"
EOF

./nginx.sh


kubectl create secret docker-registry \
  ts-nexus \
  --docker-server=http://nexus.techsophy.com \
  --docker-username=${docker_user} \
  --docker-password=${docker_password} 




kubectl apply -f dependency/cert-manager.yaml --validate=false

env