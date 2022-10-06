#kubectl delete -f install-admin.yaml -n dev
#kubectl delete configmap admin-config -n dev
#
#kubectl create configmap admin-config --from-file=keycloak_clientscopes.postman_collection.json  -n dev
#kubectl apply -f install-admin.yaml -n dev
namespace=default
while getopts n: flag
do
    case "${flag}" in
        n) namespace=${OPTARG};;
    esac
done
echo $namespace
kubectl delete -f install-admin.yaml -n $namespace
kubectl delete configmap admin-config -n  $namespace

kubectl create configmap admin-config --from-file=keycloak_clientscopes.postman_collection.json  -n $namespace
kubectl apply -f install-admin.yaml -n $namespace
