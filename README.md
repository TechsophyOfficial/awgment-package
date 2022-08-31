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
- For keycloak - Keycloakdb
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
Please refer to [Troubleshooting](##Troubleshooting) for solution to common issues.


## setup kind for awgment on linux

Goto the kind-linux-local folder under package repo
<p/>
```
                awgment-package$ cd kind-linux-local/
```

Add a file localEnv.sh with below variable definition for your environment details.

```
                export reg_name='kind-registry'
                export reg_port='5001'
                export postgres_host=<postgres hostname>
                export postgres_port=<postgres port>
                export mongo_host=<mongo hostname>
                export mongo_port=<mongo port>
                export docker_user=<repo username>
                export docker_password=<repo password>
```
<p>
Please ensure that the ports are allowed in your firewall and you are able to connect using default clients with  details.\
Please refer to [Troubleshooting](##Troubleshooting) for solution to common issues.
</p>
Execute the following commands to create kind cluster and set it up with basic installations
<p>

```        
        awgment-package/kind-linux-local$ ./setupLocalKind.sh
```
</p>

## install keycloak and add admin user
update local.values.yaml with your environment details
<p/>
Install keycloak via helm chart
<p/>
```
        cd awgment-package repo folder>
        awgment-package$ helm install -f kind-linux-local/local.values.yaml keycloak-tsf charts/keycloak-tsf/
```
<p/>
Above shall import a `techsophy-platform` realm.

## keycloak dns work around
As we are installing keycloak in a local environment without a dns, we need to use port forwarding feature to manage traffic to keycloak from both internal pods and external browser.
<p/>
The script `runKeycloak.sh` opens a port 8888 on your local machine that redirects traffic to keycloak service. Run the same from awgment-package folder\
```
        cd awgment-package repo folder>
        awgment-package$ ./runKeycloak.sh
```
The above shall open port 8888 on your local machine. Verify the installation by logging into keycloak at `http://<your ip>:8888` with `keycloak.adminUser` and `keycloak.adminPassword` as per your local.values.yaml file.
Please update local.values.yaml with keycloak url as depicted below\

```
keycloak:
  url: http://<your ip like 192.168.1.101>:8888
# other properties
#
#
ingress:
  urls:
   keycloak: http://<your ip like 192.168.1.101>:8888
```

<p>Add an admin user for awgment</p>

```
        awgment-package$ cd install-artifacts/
        awgment-package/install-artifacts$ ./setup-keycloak-admin.sh
```
Above shall add a default user with username as `admin`, and password as `admin` to the techsophy-platform realm.\
Please reset the password once you finish installing the awgment specifically in prod environments
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

## setting up menus
TODO:


## Post install
Check for any jobs using kubectl and delete them
```
        kubectl get jobs
        kubectl delete jobs <jobname>
```
Reset password for admin user for both 
- master realm
- techsophy-platform realm



## Troubleshooting

**Changes required for PostGress DB set up:**
1. uncomment and update the **listen_addresses** value (as shown below) which is available in **/etc/postgresql/14/main** path and save the file.
    listen_addresses = '*' 
2. update the ADDRESS under **# IPv4 local connections:** in **pg_hba.conf**  file which available in **/etc/postgresql/14/main** pat and save the file.
        0.0.0.0/0
3. restart the postgres service 
    CMD : **sudo systemctl restart postgresql** to restart the service
          **sudo systemctl status  postgresql** to check the service status
 

**Changes required for MongoDB set up:**
update the **bindIp** value(as shown below) in mongod.conf which is available in **/etc/mongod.conf**
**bindIp: 0.0.0.0**
and stop the mongodb service and start again.
commands:
**sudo service mongod status** ---- to check the status
**sudo service mongod start** ----- to start the service
**sudo service mongod stop** ---- to stop the service


Docker set up:
1. install docker(if not installed)
2. create a docker Group
        cmd: **sudo groupadd docker**
3. check your user with below command: **echo $USER** 
4. excute the command: **sudo usermod -aG docker $USER**
5. restart your system
6. open the terminal and try to execute below command without **sudo** it should give some result. it should not give **permission Denied** message.
        **docker images/ docker ps**


