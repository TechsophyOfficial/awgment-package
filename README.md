# awgment-package
Package awgment

The below readme assumes some understanding of kubernetes and helm, please refer [Troubleshooting](#troubleshooting) for some helpful links to beginners.


# Deployment - local linux machine using Kind
## Prerequisite

1. Linux OS
2. [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
3. [Kubectl](https://kubernetes.io/docs/tasks/tools/)
4. [Helm](https://helm.sh/docs/intro/install/)
5. Postgres db
6. [Mongodb](https://www.mongodb.com/atlas/database) with transactions support

Git clone this repository on your local.

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
Please refer to [Troubleshooting](#troubleshooting) for solution to common issues.


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

Please refer to [Troubleshooting](#troubleshooting) for solution to common issues.
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

You will see keycloak-tsf name with status as Deployed as below example.
<br/>

        NAME        	NAMESPACE	REVISION	UPDATED        	STATUS  	CHART             	APP VERSION
        keycloak-tsf	default  	1       	                deployed	keycloak-tsf-1.0.0	1.0.0 


Above shall import a `techsophy-platform` realm.


After Verification, Wait for few minutes and check if keycloak pods are running.
</br>
``` 
        awgment-package$ kubectl get pods
```

If the status for the listed keycloak pods is running as example below, then skip the next step.

        NAME                                   READY   STATUS    RESTARTS        AGE
        keycloak-94f8bd648-5lsrr               1/1     Running   0               6m47s

<br/>
Oops, you are here. If pod errors out, please check the logs to identify the issue
<br/>

```
        awgment-package$ kubectl logs <pod name>
```



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

## install awgment deployment
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


You will see awgment-tsf name with status as Deployed as below example. If not, please refer to [Troubleshooting](#troubleshooting)
<br/>

        NAME        	NAMESPACE	REVISION	UPDATED         STATUS  	CHART               	APP VERSION
        awgment-tsf 	default  	1       	                deployed	tsf-playground-1.0.0	1.0.0      
        keycloak-tsf	default  	1       	                deployed	keycloak-tsf-1.0.0  	1.0.0 

After Verification, check if all pods are running.
</br>
```
        cd awgment-package repo folder>
        awgment-package$ kubectl get pods
```

If the status for all listed pods is running as example below, then skip the next step.

        NAME                                   READY   STATUS    RESTARTS        AGE
        account-app-b56bf9d69-m8pn6            1/1     Running   0               5m11s
        account-ui-5d8f8bf76b-v9687            1/1     Running   0               5m11s
        case-ui-78745f966c-6pl4w               1/1     Running   0               5m11s
        cloud-config-server-57bb4bc6c8-kxncj   1/1     Running   0               5m11s
        core-ui-7c75f8cddd-29kl9               1/1     Running   0               5m11s
        form-app-7c79cc86-l95vn                1/1     Running   0               5m11s
        form-modeler-5448cdf575-mqb6d          1/1     Running   0               5m11s
        gateway-85df6ffb9c-jwvln               1/1     Running   0               5m11s
        keycloak-94f8bd648-5lsrr               1/1     Running   0               6m47s
        rule-app-5f748cc976-gpcbn              1/1     Running   1 (3m46s ago)   5m11s
        rule-modeler-c689cbb79-7n6vv           1/1     Running   0               5m11s
        rules-857b8d5859-kj2vp                 1/1     Running   1 (4m40s ago)   5m11s
        runtime-form-app-5c89f8d5-x9cjp        1/1     Running   0               5m11s
        util-app-754b94566b-z5bp8              1/1     Running   1 (3m26s ago)   5m11s
        uxapp-controller-86b5d4cc66-v5jxr      1/1     Running   1 (3m ago)      5m11s
        workflow-app-54cfd979fc-nttbd          1/1     Running   0               5m10s
        workflow-engine-b7bf8bbb6-fjcwg        1/1     Running   0               5m10s
        workflow-modeler-6f7488b66-rw28r       1/1     Running   0               5m11s


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
Reset password for admin user for both realms, specifically if you are using this in a non-local environment
- master realm
- techsophy-platform realm



## Troubleshooting
**Introduction to kubernetes and helm**

[Quick start for absolute beginners](https://opensource.com/article/20/2/kubectl-helm-commands) <br/>
[More detailed dive](https://www.baeldung.com/ops/kubernetes-helm)<br/>

If you experience higher CPU usage on your system please uninstall the chart via helm
```        
        helm uninstall awgment-tsf
        helm uninstall keycloak-tsf
```

**Setting up PostGress DB on local:**
It should be possible to connect with postgres db via IP address, some link below explain how to allow connection for any/specific ip, please follow as per your version<br/>
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

