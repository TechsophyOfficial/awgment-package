#kubectl delete -f install-menu.yaml -n dev
#kubectl delete configmap menu-config -n dev
#kubectl create configmap menu-config --from-file=menu_artifacts -n dev
#kubectl apply -f install-menu.yaml -n dev
namespace=default
while getopts n: flag
do
    case "${flag}" in
        n) namespace=${OPTARG};;
    esac
done
echo $namespace
kubectl delete -f install-menu.yaml -n $namespace
kubectl delete configmap menu-config -n $namespace
kubectl create configmap menu-config --from-file=menu_artifacts -n $namespace
kubectl apply -f install-menu.yaml -n $namespace