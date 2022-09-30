kubectl delete -f install-menu.yaml -n dev
kubectl delete configmap menu-config -n dev
kubectl create configmap menu-config --from-file=menu_artifacts -n dev
kubectl apply -f install-menu.yaml -n dev
