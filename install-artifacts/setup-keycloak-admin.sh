namespace=default
while getopts n: flag
do
    case "${flag}" in
        n) namespace=${OPTARG};;
    esac
done
kubectl delete -f install-admin.yaml -n $namespace
kubectl delete configmap admin-config -n  $namespace

kubectl create configmap admin-config --from-file=keycloak_clientscopes.postman_collection.json  -n $namespace
kubectl apply -f install-admin.yaml -n $namespace
