kubectl delete -f install-admin.yaml -n dev
kubectl delete configmap admin-config -n dev

kubectl create configmap admin-config --from-file=keycloak_clientscopes.postman_collection.json  -n dev
kubectl apply -f install-admin.yaml -n dev
