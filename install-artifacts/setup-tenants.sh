namespace=default
while getopts n: flag
do
    case "${flag}" in
        n) namespace=${OPTARG};;
    esac
done
# kubectl delete -f install-menu.yaml -n $namespace
kubectl delete configmap tenant-config -n $namespace
kubectl create configmap tenant-config --from-file=tenants -n $namespace
# kubectl apply -f install-menu.yaml -n $namespace
