#!/bin/sh
if [ "$#" -ne 1 ];  then
  echo "Usage: $0  project_name" >&1
  exit 1
fi

echo "Please Login to OCP using oc login ..... "  
echo "Make sure Openshift Camel K  Operator is installed"
echo "Make sure Red Hat AMQ Broker Operator is installed"
echo "Make sure oc command is available"
read

oc new-project $1
oc apply -f https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/amq/my-amq-broker.yaml

#curl jms properties
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/amq/jms-config.properties >jms-config.properties

#create secret
oc create secret generic jms-config --from-file=jms-config.properties

#curl the integration file
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/amq/RestToJMSRoute.java >RestToJMSRoute.java
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/amq/JMSToLogRoute.java >JMSToLogRoute.java

#run the integration 
# no need for --dev flag
kamel run --config configmap:my-jms-config -d mvn:org.amqphub.quarkus:quarkus-qpid-jms RestToJMSRoute.java
kamel run --config configmap:my-jms-config -d mvn:org.amqphub.quarkus:quarkus-qpid-jms JMSToLogRoute.java

echo "Press [Enter] key to do some testing once the integration deployed successfully ..." 
read

#do some curl commands for testing
curl $(oc get route rest-to-jms-route -o jsonpath='{.spec.host}')/send/Hello-from-osa-ora
curl $(oc get route rest-to-jms-route -o jsonpath='{.spec.host}')/send/Hello-from-osa-ora2
curl $(oc get route rest-to-jms-route -o jsonpath='{.spec.host}')/send/Hello-from-osa-ora3

kamel logs jms-to-log-route
echo "Congratulations, we are done!"
