# awgment-package
Package awgment




# Deployment - local linux machine using Kind
## Prerequisite

1. Linux OS
2. [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
3. [Kubectl](https://kubernetes.io/docs/tasks/tools/)
4. [Helm](https://helm.sh/docs/intro/install/)
5. Postgres db
6. [Mongodb](https://www.mongodb.com/atlas/database) with transactions support 


Create two databases in postgres and a user with appropriate priviledges
- For keycloak - keycloakdb
- For Camunda - camundadb

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
Please refer to [Troubleshooting](##troubleshooting) for solution to common issues.


## setup kind for awgment on linux

Goto the kind-linux-local folder under package repo
<p/>

```
                awgment-package$ cd kind-linux-local/
```

Edit file localEnv.sh to manage your environment ports, below defaults are used, if they are already bound please change them.

```
        export reg_name='kind-registry'
        export reg_port='5001'
        export http_port=8080

```
<p>
Please ensure that the database (mongo and postgres) are allowed in your firewall and you are able to connect using default clients with IP details.<br/>
Please refer to [Troubleshooting](##Troubleshooting) for solution to common issues.
</p>
Execute the following commands to create kind cluster and set it up with basic installations including nginx controller.
<p>

```        
        awgment-package/kind-linux-local$ ./setupLocalKind.sh
```
</p>

## install keycloak
Update local.values.yaml with your environment details for postgres and mongo in below properties
```
keycloak:
  adminUser: admin
  adminPassword: <MASTER_REALM_PASSWORD>
  client:
    secret: 0ef502e1-567a-48cf-ae56-7e1a5bdfe3c4  
  db:   
    host: <POSTGRES_HOST>:5432 
    user: <POSTGRES_USER>
    password: <POSTGRES_PASSWORD>
    name: keycloakdb
    vendor: postgres
  url: http://<you ip like 192.168.1.16>:8888
  
mongo:
   url: mongodb+srv://<username>:<password>@<mongo.cluster.com>:27017/?retryWrites=true
postgres:
     camunda:
         dburl: jdbc:postgresql://<POSTGRES_HOST>:5432/camundadb
         user: <POSTGRES_USER>
         password: <POSTGRES_PASSWORD>
         database: camundadb
ingress:
# other properties
#
#
  urls:
   keycloak: http://<your ip like 192.168.1.101>:8888


```
<br/>
Install keycloak via helm chart
<br/>

```
        cd awgment-package repo folder>
        awgment-package$ helm install -f kind-linux-local/local.values.yaml keycloak-tsf charts/keycloak-tsf/
```


<br/>
Verify the  installation by
<br/>

```
        cd awgment-package repo folder>
        awgment-package$ helm list
```


You will see keycloak-tsf name with status as Deployed. If not, please refer to [Troubleshooting](https://github.com/TechsophyOfficial/awgment-package/tree/readme_issues#troubleshooting)
<br/>


Above shall import a `techsophy-platform` realm.

## keycloak dns work around
As we are installing keycloak in a local environment without a dns, we need to use port forwarding feature to manage traffic to keycloak from both internal pods and external browser.
<br/>
The script `runKeycloak.sh` opens a port 8888 on your local machine that redirects traffic to keycloak service. Run the same from awgment-package folder
<br/>

```
        cd awgment-package repo folder>
        awgment-package$ ./runKeycloak.sh
```

The above shall open port 8888 on your local machine.<br/>
Verify the installation by logging into keycloak at `http://<your ip>:8888` with `keycloak.adminUser` and `keycloak.adminPassword` as per your local.values.yaml file.<br/>
Please ensure to update local.values.yaml with keycloak url before proceeding to further steps as depicted below
<br/>
You can regenerate the  client secret for camunda-identity-service and update the same values in your local.values.yaml file under `keycloak.client.secret` before proceeding to the next steps to enhance security. 
<br/>
This is highly recommended for production deployments.
```
keycloak:
  client:
    secret: 0ef502e1-567a-48cf-ae56-7e1a5bdfe3c4  
  url: http://<your ip like 192.168.1.101>:8888
# other properties
#
#
ingress:
  urls:
   keycloak: http://<your ip like 192.168.1.101>:8888
```

## add admin user

Run below script to add an admin user for awgment
<br/>

```
        awgment-package$ cd install-artifacts/
        awgment-package/install-artifacts$ ./setup-keycloak-admin.sh
```
Above shall add a default user to the techsophy-platform realm.<br/>
```
username: admin
password: admin
```
Further steps currently use above details, please reset the password AFTER  finishing the awgment installation.

## install augment deployment
Install awgment chart 
```
        cd <awgment-package repo folder>
        awgment-package$ helm install -f kind-linux-local/local.values.yaml awgment-tsf charts/awgment-tsf/
```

<br/>
Verify the  installation by
<br/>

```
        cd awgment-package repo folder>
        awgment-package$ helm list
```


You will see awgment-tsf name with status as Deployed. If not, please refer to [Troubleshooting](https://github.com/TechsophyOfficial/awgment-package/tree/readme_issues#troubleshooting)
<br/>

After Verification, check if all pods are running.
</br>
```
        cd awgment-package repo folder>
        awgment-package$ kubectl get pods
```

If the status for all listed pods is running or active then go to next step.

<br/>
Oops, you are here. It seems all pods are not in running status.
<br/>

```
        cd awgment-package repo folder>
        awgment-package$ kubectl logs <pod name>
```

See the status and check what blocks the pod to run.


## setting up menus
Run below script to install default menus for awgment
<br/>

```
        awgment-package$ cd install-artifacts/
        awgment-package/install-artifacts$ ./setup-menu.sh
```

To do this step manually if variation are required in future, please refer the files and steps under [install-artifacts/menu_artifacts](install-artifacts/menu_artifacts) to install menu items.


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


**Changes required for PostGress DB set up on local:**
<br/>
[Postgres Configuration](https://www.vultr.com/docs/install-pgadmin-4-for-postgresql-database-server-on-ubuntu-linux/#2__Change_PostgreSQL_Configurations)
 

**MongoDB set up:**
Using mongo on local machine -
update the **bindIp** value(as shown below) in mongod.conf which is available in **/etc/mongod.conf**
**bindIp: 0.0.0.0**
and stop the mongodb service and start again.
commands:
**sudo service mongod status** ---- to check the status
**sudo service mongod start** ----- to start the service
**sudo service mongod stop** ---- to stop the service

[Running Standalone Mongo as a replication cluster](https://hevodata.com/learn/mongodb-transactions-on-single-node/#41)

**Docker set up:**

[Manage docker as a non root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)

1. install docker(if not installed)
2. create a docker Group
        cmd: **sudo groupadd docker**
3. check your user with below command: **echo $USER** 
4. excute the command: **sudo usermod -aG docker $USER**
5. restart your system
6. open the terminal and try to execute below command without **sudo** it should give some result. it should not give **permission Denied** message.
        **docker images/ docker ps**
