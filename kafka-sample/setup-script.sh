#!/bin/sh
if [ "$#" -ne 1 ];  then
  echo "Usage: $0  project_name" >&1
  exit 1
fi

echo "Please Login to OCP using oc login ..... "  
echo "Make sure Openshift Camel K  Operator is installed"
echo "Make sure Red Hat AMQ Streams (Kafka) Operator is installed"
echo "Make sure oc command is available"
read
# Create a new project
oc new-project $1
# Provision Kafka using object details
oc apply -f https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/kafka-sample/kafka-topic.yaml

# Download kafka properties
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/kafka-sample/kafka.properties >kafka-config.properties

# Create secret
oc create secret generic kafka-props --from-file=kafka-config.properties

# Download the integration file

# Dependency already added to the source file and no need for any flag for kamel command
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/kafka-sample/KafkaProducer.java > KafkaProducer.java
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/kafka-sample/KafkaConsumer.java > KafkaConsumer.java

echo "Press [Enter] Once the Kafka cluster is ready .."
read

# Run the integration 
kamel run --config secret:kafka-props KafkaProducer.java
kamel run --config secret:kafka-props KafkaConsumer.java

echo "Press [Enter] key to do some testing once the integration deployed successfully ..." 
read

# Group all resourcs
oc label deployment/kafka-consumer app.kubernetes.io/part-of=my-kafka-demo
oc label deployment/kafka-producer  app.kubernetes.io/part-of=my-kafka-demo
#oc label statefulsets/my-kafka-cluster  app.kubernetes.io/part-of=my-kafka-demo

#do some curl commands for testing
curl $(oc get route kafka-producer -o jsonpath='{.spec.host}')/send/Hello-from-osa-ora
curl $(oc get route kafka-producer -o jsonpath='{.spec.host}')/send/Hello-from-osa-ora2
curl $(oc get route kafka-producer -o jsonpath='{.spec.host}')/send/Hello-from-osa-ora3
time curl -s $(oc get route kafka-producer -o jsonpath='{.spec.host}')/send/Hello-from-Osama-Oransa{1-3}?[1-50]

kamel logs kafka-consumer
echo "Congratulations, we are done!"
