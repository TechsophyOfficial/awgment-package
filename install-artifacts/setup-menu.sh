namespace=default
while getopts n: flag
do
    case "${flag}" in
        n) namespace=${OPTARG};;
    esac
done
kubectl delete -f install-menu.yaml -n $namespace
kubectl delete configmap menu-config -n $namespace
kubectl create configmap menu-config --from-file=menu_artifacts -n $namespace
kubectl apply -f install-menu.yaml -n $namespace