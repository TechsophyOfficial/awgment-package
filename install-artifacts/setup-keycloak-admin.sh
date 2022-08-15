kubectl create configmap admin-config --from-file=keycloak_clientscopes.postman_collection.json 
kubectl apply -f install-admin.yaml