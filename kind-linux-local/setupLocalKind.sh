#!/bin/sh
set -e

sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512

FILE=./localEnv.sh
if test -f "$FILE"; then
  echo "utilising env as per ./localEnv.sh"
  cat localEnv.sh
  . ./localEnv.sh
else
  echo "Please create the ./localEnv.sh for your environment with following values"
  echo "export reg_name='kind-registry'"
  echo "export reg_port='5001'"
  echo "export http_port=8080"
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
cat <<EOF | kind create cluster --name ${cluster_name} --config=-
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
    hostPort: ${http_port}
    protocol: TCP
  # - containerPort: 443
  #   hostPort: 8443
  #   protocol: TCP
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


kubectl cluster-info --context kind-${cluster_name}

# echo "Installing certificate manager, though we currently dont support  "
# kubectl create namespace cert-manager
# kubectl apply  \
#   -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml

echo "Installing nginx "

./nginx.sh


# kubectl apply -f dependency/cert-manager.yaml --validate=false

# env


echo \
'Please setup your db(postgres/mongo) as per readme and setup local.values.yaml appropriately'

