# Postman

Postman is an API platform for building and using APIs.

## Installation

For installation and setting agents refer [Postman Docs](https://learning.postman.com/docs/getting-started/installation-and-updates/)

## Importing Collections

1. Select Import in the left navigation menu.
2. Select menu_atifacts folder. It will automatically recognize the "AutomatedMenuRoleAssign" as Postman Collection and "MenuEnv" as Postman Environment.
3. Click Import to bring data into Postman.


## Environment Variables

1. keycloak_url : Keycloak URL
2. realm : Realm to which the user belongs to
3. username : The User
4. client_id :  Client unique name
5. client_secret : Secret constant for a specific client_id
6. api_url : The API to hit


## Using the Collection Runner

 A Collection Runner in Postman is used for triggering more than one request simultaneously. For the configuration and usages, refer [Collection Runner](https://learning.postman.com/docs/running-collections/intro-to-collection-runs/)

Before you start a collection run, you can choose optional configuration parameters such as number of iteration, delay between iterations and data file.

- Select "data.csv" as data file from the menu_artifacts directory and click Start Run button. 

