# awgment-package
Package awgment




# Deployment - local linux machine using Kind
## Prerequisite

1- Linux OS
2- Kind 
3- Kubectl
4- Postgres db
5- Mongodb

Create two databases in postgres and a user with appropriate priviledges
- For keycloak - <Keyclaokdb>
- For Camunda - <camunda>

## install kind on linux


Add a file localEnv.sh with below environment details
        export reg_name='kind-registry'
        export reg_port='5001'
        export postgres_host=<postgres hostname>
        export postgres_port=<postgres port>
        export mongo_host=<mongo hostname>
        export mongo_port=<mongo port>
        export docker_user=<repo username>
        export docker_password=<repo password>

Execute the following commands
        awgment-package$ cd kind-linux-local/
        awgment-package/kind-linux-local$ ./setupLocalKind.sh


## install keycloak and add admin user
update local.values.yaml with your environment details
Install keycloak via helm chart
        cd <awgment-package repo folder>
        awgment-package$ helm install -f kind-linux-local/local.values.yaml keycloak-tsf charts/keycloak-tsf/
Add an admin user for awgment
        awgment-package$ cd install-artifacts/
        awgment-package/install-artifacts$ ./setup-keycloak-admin.sh
Above shall add a default user with username as admin, and password as admin to techsophy-realm


## install augment deployment
Install awgment chart 
        cd <awgment-package repo folder>
        awgment-package$ helm install -f kind-linux-local/local.values.yaml awgment-tsf charts/awgment-tsf/




