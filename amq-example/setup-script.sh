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
# Create a new project
oc new-project $1
# Provision AMQ using object details
oc apply -f https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/amq-example/my-amq-broker.yaml

# Download jms properties
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/amq-example/jms-config.properties >jms-config.properties

# Create configMap
oc create configmap my-jms-config --from-file=jms-config.properties

# Download the integration file
# Dependency already added to the source file and no need for any flag for kamel command
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/amq-example/RestToJMSRoute.java >RestToJMSRoute.java
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/amq-example/JMSToLogRoute.java >JMSToLogRoute.java

# Run the integration 
#kamel run --config configmap:my-jms-config -d mvn:org.amqphub.quarkus:quarkus-qpid-jms RestToJMSRoute.java
#kamel run --config configmap:my-jms-config -d mvn:org.amqphub.quarkus:quarkus-qpid-jms JMSToLogRoute.java

kamel run --config configmap:my-jms-config RestToJMSRoute.java
kamel run --config configmap:my-jms-config JMSToLogRoute.java

echo "Press [Enter] key to do some testing once the integration deployed successfully ..." 
read

# Group all resourcs
oc label deployment/jms-to-log-route app.kubernetes.io/part-of=my-amq-demo
oc label deployment/rest-to-jms-route app.kubernetes.io/part-of=my-amq-demo
oc label statefulsets/my-amq-ss app.kubernetes.io/part-of=my-amq-demo

#do some curl commands for testing
curl $(oc get route rest-to-jms-route -o jsonpath='{.spec.host}')/send/Hello-from-osa-ora
curl $(oc get route rest-to-jms-route -o jsonpath='{.spec.host}')/send/Hello-from-osa-ora2
curl $(oc get route rest-to-jms-route -o jsonpath='{.spec.host}')/send/Hello-from-osa-ora3

kamel logs jms-to-log-route
echo "Congratulations, we are done!"
