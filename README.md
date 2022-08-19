# awgment-package
Package awgment




# Deployment - local linux machine using Kind
## Prerequisite

1. Linux OS
2. [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
3. [Kubectl](https://kubernetes.io/docs/tasks/tools/)
4. [Helm](https://helm.sh/docs/intro/install/)
5. Postgres db
6. Mongodb

Create two databases in postgres and a user with appropriate priviledges
- For keycloak - Keyclaokdb
- For Camunda - camunda

Notes-
If you get errors for open file handles
```
        "too many open files"
```
Set the following on your system settings
```
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512
```


## setup kind for awgment on linux

Goto the kind-linux-local folder under package repo
```
                awgment-package$ cd kind-linux-local/
```
Add a file localEnv.sh with below variable definition for your environment details.

```
                export reg_name='kind-registry'
                export reg_port='5001'
                export postgres_host=postgres hostname
                export postgres_port=postgres port
                export mongo_host=mongo hostname
                export mongo_port=mongo port
                export docker_user=repo username
                export docker_password=repo password
```
<p>
Please ensure that the ports are allowed in your firewall and you are able to connect using default clients with  details
</p>
Execute the following commands to create kind cluster and set it up with basic installations
<p>

```        
        awgment-package/kind-linux-local$ ./setupLocalKind.sh
```
</p>

## install keycloak and add admin user
update local.values.yaml with your environment details\
Install keycloak via helm chart
```
        cd awgment-package repo folder>
        awgment-package$ helm install -f kind-linux-local/local.values.yaml keycloak-tsf charts/keycloak-tsf/
```
<p>Add an admin user for awgment</p>

```
        awgment-package$ cd install-artifacts/
        awgment-package/install-artifacts$ ./setup-keycloak-admin.sh
```
Above shall import a `techsophy-platform` realm and add a default user with username as `admin`, and password as `admin` to the same.\
Please reset the password once you finish installing the awgment specifically in prod environments
<p>
Verify the installation by logging into keycloak at `ingress.hosts.keycloak` with `keycloak.adminUser` and `keycloak.adminPassword` as per your local.values.yaml file.
<p>
You can regenerate the  client secret for camunda-identity-service and update the same values in your local.values.yaml file under `keycloak.client.secret` before proceeding to the next steps to enhance security. 
<p>
This is highly recommended for production deployments.
</p>

## install augment deployment
Install awgment chart 
```
        cd <awgment-package repo folder>
        awgment-package$ helm install -f kind-linux-local/local.values.yaml awgment-tsf charts/awgment-tsf/
```



## Post install
Check for any jobs using kubectl and delete them
```
        kubectl get jobs
        kubectl delete jobs <jobname>
```
Reset password for admin user for both 
- master realm
- techsophy-platform realm
