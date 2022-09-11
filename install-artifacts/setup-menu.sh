kubectl delete -f install-menu.yaml
kubectl delete configmap menu-config
kubectl create configmap menu-config --from-file=menu_artifacts
kubectl apply -f install-menu.yaml