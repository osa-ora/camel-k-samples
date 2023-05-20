#!/bin/sh
if [ "$#" -ne 1 ];  then
  echo "Usage: $0  project_name" >&1
  exit 1
fi

echo "Please Login to OCP using oc login ..... "  
echo "Make sure Openshift Camel K  Operator is installed"
echo "Make sure oc command is available"

oc new-project $1
oc new-app mysql-persistent -p DATABASE_SERVICE_NAME=mysql -p MYSQL_USER=test -p MYSQL_PASSWORD=test123 -p MYSQL_DATABASE=accountdb

COMMAND="create table accountdb.account ( id INT AUTO_INCREMENT NOT NULL PRIMARY KEY, firstname VARCHAR( 255 ) NOT NULL, lastname VARCHAR( 255 ) NOT NULL,status INT NOT NULL);insert into accountdb.account (id, firstname, lastname, status) values (1,'Osama','Oransa',1);insert into accountdb.account (id, firstname, lastname, status) values (2,'Osa','Ora',1);"

echo "Will install: $COMMAND"
echo "Press [Enter] key to setup the DB ..." 
read

POD_NAME=$(oc get pods -l=name=mysql -o custom-columns=POD:.metadata.name --no-headers)
echo "MySQL Pod name $POD_NAME"
oc exec $POD_NAME -- mysql -u root accountdb -e "create table accountdb.account ( id INT AUTO_INCREMENT NOT NULL PRIMARY KEY, firstname VARCHAR( 255 ) NOT NULL, lastname VARCHAR( 255 ) NOT NULL,status INT NOT NULL);insert into accountdb.account (id, firstname, lastname, status) values (1,'Osama','Oransa',1);insert into accountdb.account (id, firstname, lastname, status) values (2,'Osa','Ora',1);"  

#curl database properties
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/mysql-example/datasource.properties >datasource.properties

#create secret
oc create secret generic my-datasource --from-file=datasource.properties

#curl the integration file
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/mysql-example/AccountDataRoute.java >AccountDataRoute.java

#run the integration 
# no need for --dev flag
kamel run AccountDataRoute.java --build-property quarkus.datasource.camel.db-kind=mysql -d mvn:io.quarkus:quarkus-jdbc-mysql  --config secret:my-datasource --dependency camel-jdbc

echo "Press [Enter] key to do some testing ..." 
read

#do some curl commands for testing
curl $(oc get route account-data-route -o jsonpath='{.spec.host}')/users/1
curl $(oc get route account-data-route -o jsonpath='{.spec.host}')/users/2
curl $(oc get route account-data-route -o jsonpath='{.spec.host}')/users/4

echo "We are done!"
