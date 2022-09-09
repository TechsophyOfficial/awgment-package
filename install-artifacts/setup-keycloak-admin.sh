kubectl delete -f install-admin.yaml
kubectl delete configmap admin-config

kubectl create configmap admin-config --from-file=keycloak_clientscopes.postman_collection.json 
kubectl apply -f install-admin.yaml