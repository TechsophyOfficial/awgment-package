# awgment-package
Package awgment

The below readme assumes some understanding of kubernetes and helm, please refer [Troubleshooting](#troubleshooting) for some helpful links to beginners.


# Deployment of awgment kubernetes cluster
Below steps can be used to deploy awgment on kubernetes cluster.

To keep the installation simple dns/tls certificate configuration is avoided, so the below steps should be used for introductory evaluation purpose. For running a dedicated environments adherence to ops best practices is required.

Any contributions to improve below is welcome.

## Prerequisite

1. Linux OS
3. [Kubectl](https://kubernetes.io/docs/tasks/tools/)
4. [Helm](https://helm.sh/docs/intro/install/)



## setup kubernetes for awgment on cloud

Create kubernetes cluster in your choice of cloud platform, below is experimented on Digital-ocean. Download the Kubeconfig.
Create local directory (.kube) and keep the required config file in the directory to access to that kubernetes cluster.

Now you will be accessed to k8’s cluster. Check the access by running the command below.
```
   Kubectl get nodes
```

We shall deploy the pods in specific namespace 'dev'. To create namespace for cluster run the following script
```
        kubectl create namespace dev
        Kubectl get namespace  
```
# clone the awgment Repository
git clone https://github.com/TechsophyOfficial/awgment-package.git

Below steps can be used to deploy postgres and mongo db as pods using provided sample configuration files in kubernetes cluster with mounted volumes.

## Deploy postgres pod
Run below script to run postgres pod, you can update the files as per your environment specific configuration

```

        awgment-package$cd kubernetes-cloud/
        awgment-package/kubernetes-cloud$ cd dependencies/
        awgment-package/kubernetes-cloud/dependencies$ kubectl apply  -f postgres-deployment.yaml -n dev
        awgment-package/kubernetes-cloud/dependencies$ kubectl apply –f postgres-config.yaml -n dev

```

Run below script to get all pods

```
 kubectl get pods -n dev
```

Run below script to connect to the postgres pod

```
         kubectl exec –it <postgres-pod name> bin/bash -n dev
         psql  -U postgresadmin postgres 
```

Run below command to create keycloakdb
```
   create database keycloakdb;
```
grant all privileges on database keycloakdb to postgresadmin

Run below command to create keycloakdb
```
   create database camundadb; 
```
grant all privileges on database camundadb to postgresadmin

## Deploy Mongodb pod:
Run below script to run mongodb pod, you can update the files for your environment specific configuration

```

        awgment-package$cd kubernetes-cloud/
        awgment-package/kubernetes-cloud$ cd dependencies/
        awgment-package/kubernetes-cloud/dependencies$ kubectl apply –f  mongo-deployment.yaml -n dev
        awgment-package/kubernetes-cloud/dependencies$ kubectl apply –f mongo-config.yaml -n dev

```
Run below script to connect to the mongodb pod

```
         kubectl exec –it <mongo-pod name> bin/bash -n dev
```
Enter 'mongo' here to connect to the shell
```
         root@mongo-0:/# mongo
```

Run below commands in primary mongo shell(rs0:PRIMARY>)

```
rs.initiate()

var cfg = rs.conf()

cfg.members[0].host="mongo-0.mongo:27017"

rs.reconfig(cfg)

rs.status()
```
Create tp_modeler user to the admin database.

Run the below script while providing your password:
```
db.createUser( 

   { 

     user: "tp_modeler", 

     pwd: "<mongo password>", 

     roles: [ { role: "dbOwner", db: "admin" } ] 

   } 

) 
```

## Install nginx ingress on  kubernetes
Next we need to install nginx, one can refer the documentation, https://kubernetes.github.io/ingress-nginx/deploy/
Below steps can be used to install specfic version-

```
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml
```

Run below command to access the loadbalancer IP, which shall be required in further configuration

```
   kubectl get  svc -n ingress-nginx
```

After excution of above command the output will look like this.
```
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.245.213.199   64.72.43.23     80:31606/TCP,443:30047/TCP   5d23h
ingress-nginx-controller-admission   ClusterIP      10.245.88.198    <none>          443/TCP                      5d23h

```

## install ssl on kubernetes
In case you want SSL to be enabled for external traffic on your domain, you need to install a certificate manager.
There are different certificate managers available some may charge you for providing a certificate.
[Here](https://someweb.github.io/devops/cert-manager-kubernetes/) is an article that explains how to setup cert-manager.

One can install a self-signed certificate manager if secure communication is the only need and a valid domain mapping is not on your high list. A sample yaml file is present under dependencies/self-signed-certificate.yaml
```

        awgment-package$cd kubernetes-cloud/
        awgment-package/kubernetes-cloud$ cd dependencies/
        awgment-package/kubernetes-cloud/dependencies$ kubectl apply –f  self-signed-certificate.yaml -n dev
```
The above shall install a certificate with name awgmnt-certificate. **This is referred to by the helm chart values, update the helm chart values if you change the name.**

To configure SSL communication update the following details in cluster.values.yaml file, instead of using loadbalancer ip with nip.io you can also specify the domains if you have them available.
```
ingress:
   hosts:
     keycloak: auth.<loadbalancerip>.nip.io
     gateway: api.<loadbalancerip>.nip.io
     tsffrontend: awgment.<loadbalancerip>.nip.io
     camunda: camunda.<loadbalancerip>.nip.io
   urls:
     scheme: https
     port: 443
   secretname:
     keycloak: awgmnt-certificate
     gateway: awgmnt-certificate
     tsffrontend: awgmnt-certificate
     camunda: awgmnt-certificate
```
If you dont want SSL to be configured update the urls.scheme/port in above file as http/80.



## Deploy keycloak
Update cluster.values.yaml with your environment details for postgres and mongo in below properties

Replace the IP with your loadbalancer ip in the cluster.values.yaml file
```
keycloak:
  adminUser: admin
  adminPassword: <MASTER_REALM_PASSWORD>
  client:
    secret: 0ef502e1-567a-48cf-ae56-7e1a5bdfe3c4  
  db:   
    host: <POSTGRES_SERVICE_HOST>:5432 
    user: <POSTGRES_USER>
    password: <POSTGRES_PASSWORD>
    name: keycloakdb
    vendor: postgres
  url: http://auth.<loadbalancerIp>.nip.io
mongo:
  url: mongodb://tp_modeler:<mongo password>@mongo-0.mongo:27017,mongo-1.mongo:27017/
   
ingress:
#
#other properties
#
  hosts:
    keycloak: auth.<loadbalancerIp>.nip.io
    gateway: api.<loadbalancerIp>.nip.io
    tsffrontend: awgment.<loadbalancerIp>.nip.io
    camunda: camunda.<loadbalancerIp>.nip.io
  urls:
    keycloak: http://auth.<loadbalancerIp>.nip.io/
    gateway: http://api.<loadbalancerIp>.nip.io
    tsffrontend: http://awgment.<loadbalancerIp>.nip.io 
    camunda:  http://awgment.<loadbalancerIp>.nip.io/camunda
  
```
<br/>

Install keycloak via helm chart

<br/>

```
        cd <awgment-package repo folder>
        awgment-package$ helm install -f kubernetes-cloud/cluster.values.yaml keycloak-tsf charts/keycloak-tsf/ -n dev
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
        awgment-package$ kubectl get pods -n dev
```

If the status for the listed keycloak pods is running as example below, then skip the next step.

        NAME                                   READY   STATUS    RESTARTS        AGE
        keycloak-94f8bd648-5lsrr               1/1     Running   0               6m47s

<br/>
Oops, you are here. If pod errors out, please check the logs to identify the issue
<br/>

```
        awgment-package$ kubectl logs <pod name> -n dev
```


## add admin user

Run below script to add an admin user for awgment
<br/>

```
        awgment-package$ cd install-artifacts/
        awgment-package/install-artifacts$ ./setup-keycloak-admin.sh -n dev
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
        awgment-package$ helm install -f kubernetes-cloud/cluster.values.yaml awgment-tsf charts/awgment-tsf/ -n dev
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
        awgment-tsf 	default  	1       	                deployed	awgment-tsf-1.0.0	   1.0.0      
        keycloak-tsf	default  	1       	                deployed	keycloak-tsf-1.0.0  	1.0.0 

After Verification, check if all pods are running.
</br>
```
        cd awgment-package repo folder>
        awgment-package$ kubectl get pods - n dev
```
Wait for sometime for all pods to manage dependencies and come to running state as below.
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
        mongo-0                                1/1     Running   0               4d23h
        mongo-1                                1/1     Running   0               4d23h
        postgres-8576996c8b-sgkbs              1/1     Running   0               7d18h
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
        awgment-package$ kubectl logs <pod name> - n dev
```

See the status and check what blocks the pod to run.


## setting up menus
Run below script to install default menus for awgment
<br/>

```
        awgment-package$ cd install-artifacts/
        awgment-package/install-artifacts$ ./setup-menu.sh -n dev
```

To do this step manually if variation are required in future, please refer the files and steps under [awgment-package/install-artifacts/menu_artifacts](awgment-package/install-artifacts/menu_artifacts) to install menu items.
Now check the awgment menus
```
 by hitting "awgment.<LoadBalancer Ip>.nip.io/model"
```

Username:admin
Password:admin

## Post install
Check for any jobs using kubectl and delete them
```
        kubectl get jobs -n dev
        kubectl delete jobs <jobname> -n dev
```
Reset password for admin user for both realms
- master realm
- techsophy-platform realm



## Troubleshooting
**Introduction to kubernetes and helm**

[Quick start for absolute beginners](https://opensource.com/article/20/2/kubectl-helm-commands) <br/>
[More detailed dive](https://www.baeldung.com/ops/kubernetes-helm)<br/>
