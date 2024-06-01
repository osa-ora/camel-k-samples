# Camel-k Samples

Camel K is a lightweight integration framework built from Apache Camel that runs natively on Kubernetes and is specifically designed for serverless and microservice architectures.
Quarkus serves as the runtime framework for Camel K, providing lightweight, fast, and cloud-native capabilities that enable the efficient development and deployment of Apache Camel integrations

<img width="206" alt="Screenshot 2023-05-20 at 23 44 50" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/20bf6b5c-b86d-45db-9f66-f2325300e295">

## Setup the Environment
- Make sure you have a ready OpenShift cluster
- Setup Camel-K Red Hat Operator
- Download "kamel" command line
- Make sure you have "oc" command line installed

<img width="269" alt="Screenshot 2023-06-06 at 10 02 07" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/2cebcf80-0cd6-467d-9398-f2f0b6fd5c40">


The magic of Camel-K is that you write using DSL either code or YAML file and the platform will do the remaining for you, so let's see some scenarios for our usual operations:

<img width="1066" alt="Screenshot 2023-05-20 at 23 43 47" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/1947380c-72b9-46c2-9b14-718ec47d59e5">

## Using Camel K
***
### Building the Integration
As we have mentioned before you can use DSL, for example we can use YAML file format as the following simple example:
```
 - from:
    uri: "timer:yaml"
    parameters:
      period: "1000"
    steps:
      - setBody:
          constant: "Hello Camel K from yaml"
      - to: "log:info"
```
In this example, a timer will be invkoed every second to log a hello message.
We can also use Java syntax for example to write the integration:
```
import org.apache.camel.builder.RouteBuilder;

public class MyRestRoute extends RouteBuilder {

    @Override
    public void configure() throws Exception {
        // Define the REST API endpoint
        rest("/api")
            .get("/hello/{name}")
                .to("direct:helloRoute");
        // Define the route that handles the parameter and generates the response
        from("direct:helloRoute")
            .log("Received request with name: ${header.name}")
            .setHeader("Content-Type", constant("text/plain"))
            .setBody(simple("Hello, ${header.name}!"));
    }
}
```
This example expose REST API to be called /api/hello/{name} and return Hello {Name}, in both ways writing the integration is simple.
We have a better example of invoking a REST API to retireve data from the database "MySQL"
```
// Define REST API endpoint
rest("/users")
    .get("/{id}")
    .to("direct:getUserAccount");

// Define the route to retrieve user account details from the database
from("direct:getUserAccount")
    .setHeader("Content-Type", constant("application/json"))
    .setBody(simple("select * from account where id = ${header.id} LIMIT 1"))
    .to("jdbc:camel")
    .choice()
       .when(simple("${body.size()} > 0"))
            .transform().jsonpath("$[0]")
            .setHeader("CamelHttpResponseCode", constant(200))
        .otherwise()
            .setHeader("CamelHttpResponseCode", constant(404))
            .setBody(constant("{ \"error\": \"User account not found\" }"))
    .end()
    .convertBodyTo(String.class) // Convert the response body to a string
    .log("User account details: ${body}");
```
We can also define a custom bean for any custom logic in the route to keep the route simple:
```
public class RestCustomBeanRoute extends RouteBuilder {

    @Override
    public void configure() throws Exception {

        // Define the REST API endpoint
        rest("/api")
            .get("/user/{id}")
                .to("direct:userRoute");

        // Define the route that handles the parameter and generates the response
        from("direct:userRoute")
            .log("Received request with user ID: ${header.id}")
            .setHeader("Content-Type", constant("application/json"))
            .bean(UserServiceBean.class, "getUser")
            .log("Response: ${body}");
    }
    public static class UserServiceBean {
        public String getUser(@Header("id") String id, Exchange exchange) {
            if ("1".equals(id)) {
                return "{ \"name\": \"Osa Ora\", \"age\": 30 }";
            } else if ("2".equals(id)) {
                return "{ \"name\": \"Osama Oransa\", \"age\": 35 }";
            } else {
                exchange.getMessage().setHeader("CamelHttpResponseCode", 404);
                return "{ \"error\": \"User not found\" }";
            }
        }
    }
}
```
In this example, we kpet the integration flow and removed the logic to a separate custom bean.

### Using Runtime Configurations
If our integration needs some configurations, we can use either a configmap or a secret for that.
So for example in our Database example, we are defining a secret for the MySQL datasource configurations:
```
quarkus.datasource.camel.db-kind=mysql
quarkus.datasource.camel.jdbc.url=jdbc:mysql://mysql:3306/accountdb
quarkus.datasource.camel.username={user}
quarkus.datasource.camel.password={password}
```
We grouped them in the file: datasource.properties which is then used to create the secret "my-datasource":
```
oc create secret generic my-datasource --from-file=datasource.properties
```

### Deploying the Integration for Dev Mode & Prod Mode
If you have completed the previous steps then you are ready to deploy the integration, the integration can be simply deployed using Kamel command line:
```
kamel run --dev hello.camelk.yaml
or
kamel run --dev MyRestRoute.java
or even use the Git URL (the complete or short one)
run https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/java-samples/MyRestRoute.java
or
kamel run github:osa-ora/camel-k-samples/java-samples/MyRestRoute.java 
```
To run withut the dev mode, simply remove the --dev tag:
```
kamel run hello.camelk.yaml
or
kamel run MyRestRoute.java
```
### Checking the Integrations Status
You can run the get command to list the deployed integrations and you can run the logs command to get the specific integration logs, but in Dev Mode you don't need to get the logs as it will be available in the console.  
```
kamel get // will return all the integration in the current namespace
kamel logs my-rest-route //will return the logs of this integration
```
You can use -n to specify a different target namespace/project.

### Using a runtime configurations
To use the configuration either config map or secret use the --configmap or --secret flag specifies the name of the ConfigMap or Secret, or -config configmap:{configmap-name} -config secret:{secret-name}
We will see this in the next section.

### Using Dependencies
In our MySQL example, we need to add some depedencies for the MySQL JDBC using -d or --dependency flag, so we will run the integration using:
```
kamel run AccountDataRoute.java --build-property quarkus.datasource.camel.db-kind=mysql -d mvn:io.quarkus:quarkus-jdbc-mysql  --config secret:my-datasource --dependency camel-jdbc
```
In this command, we used build property, depdendencies and secret. Later on, we will see a different way to specify dependencies within the same integration file snippet.

### Updating the Integration
To update the integration, simply modify the code, re-run the run command and the integration will be updated automatically.

### Scaling the Integration (Manual or Autoscaling)
You can easily scale the integration from the command line using:
```
oc scale it account-data-route --replicas 2
```
Or you can deploy the integration using Knative for auto-scaling feature which is very useful in that case.


### Getting the Integration Logs
Using the logs flag as we discussed before.
```
kamel logs account-data-route
```
### Monitoring the Integration
First you need to enable custom monioring of user workload on Promethus using the following steps:
```
oc -n openshift-monitoring get configmap cluster-monitoring-config  
if not exist, create one using: 
oc -n openshift-monitoring create configmap cluster-monitoring-config

Edit the file to enable user workload monitoring in the data section:

oc -n openshift-monitoring edit configmap cluster-monitoring-config

data:
  config.yaml: |
    enableUserWorkload: true
```
Now, when you run the integration, you can enable the monitoring for it using "-t prometheus.enabled=true" or globally for all the integrations:
```
kamel run AccountDataRoute.java --build-property quarkus.datasource.camel.db-kind=mysql -d mvn:io.quarkus:quarkus-jdbc-mysql  --config secret:my-datasource --dependency camel-jdbc -t prometheus.enabled=true
```
Now you can monitor the metrices for your integration:

<img width="1476" alt="Screenshot 2023-05-21 at 11 59 32" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/6951d4c9-9094-49a1-98ac-b600af77c6be">

Also you can define a custom metrics inside your integration and monitor them as well by using microprofile.metrics.    


### Deleting the Integration
By simply executing the delete flag:
```
Kamel delete account-data-route
```

### Building Quarkus Native Integration
As Quarkus is also allow for native compilation, we can deploy it as a native deployment which has the best efficient memory and CPU utilization and fast start up time, but compiling the integration for native will take a longer time, thankfully Camel K allow for building the integration quickly as Java deployment and behind the scene is doing the native compilation, once the native integration is ready it will seamlessly replace the Java version with the native pod:
```
kamel run github:osa-ora/camel-k-samples/yaml-samples/rest-sample.yaml -t quarkus.package-type=fast-jar -t quarkus.package-type=native
```
As we can see in the pod metrices, the memory and cpu utilization is much more lower in the native one.
Traditional Java Quarkus:
<img width="1489" alt="Screenshot 2023-05-24 at 12 05 20" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/0893d928-ebe5-4df8-a748-4e148d84df2a">


Native Quarkus:
<img width="1477" alt="Screenshot 2023-05-24 at 12 12 35" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/d3afb28c-d84e-471c-ad58-1d27e8aa9df5">

### Using GitOps for Integration
First make sure the OpenShift GitOps operator is already installed, then execute the following commands:
```
oc project test
oc policy add-role-to-user edit system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n test
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/yaml-samples/gitops-app.yaml > gitops-app.yaml
oc apply -f gitops-app.yaml -n openshift-gitops
```
So, once you finished the integration development and testing, you can then propagate it to other environments by using GitOps.

<img width="1016" alt="Screenshot 2023-05-24 at 15 28 52" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/8c951c52-8180-41d2-aa27-ba8e85b7f5d3">

### Configure Modeling Parameters inside the Source file
We can remove all the model parameters from teh command line into the source file to provide more efficient way to deal with them and persist them as one unit.
For MySQL Rest route, instead of all the Kamel command line parameter we can modify the source file by adding some notations to the top of the file:

```
// camel-k: language=java
// camel-k: dependency=mvn:io.quarkus:quarkus-jdbc-mysql dependency=camel-jdbc
// camel-k: build-property=quarkus.datasource.camel.db-kind=mysql
// camel-k: trait=prometheus.enabled=true
// camel-k: config=secret:my-datasource

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.rest.RestBindingMode;

public class AccountDataRoute extends RouteBuilder {
 ...
}
```
Now we can run the integration using: 
```
kamel run AccountDataRoute.java
```
But this will transfer to the following command:
```
Modeline options have been loaded from source files
Full command: kamel run AccountDataRoute.java --dependency=mvn:io.quarkus:quarkus-jdbc-mysql --dependency=camel-jdbc --build-property=quarkus.datasource.camel.db-kind=mysql --trait=prometheus.enabled=true --config=secret:my-datasource 
```

## Some Use Cases
***
### 1) Setup the MySQL-REST Example

By simply run the following commands:
```
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/mysql-example/setup-script.sh > setup-script.sh
chmod +x setup-script.sh

./setup-script.sh camel-project
```
Where camel-project is the OpenShift project name where all the deployment artifacts will happen.
The script will also do some curl commands to test the deployment artifacts.

<img width="592" alt="Screenshot 2023-06-07 at 15 40 54" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/a447b011-7a5b-42b0-92ec-8a5d88e78c86">


### 2) Setup the Red Hat AMQ JMS Example

First, you need to make sure Red Hat Camel K Operator and Red Hat AMQ Broker Operator are installed in OpenShift cluster.

<img width="568" alt="Screenshot 2023-06-04 at 15 57 15" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/e5a654ea-9c67-4001-a50c-59501440da21">

To send to the JMS we have a configurations for the JMS Broker and one line to do this:
```
.to("jms:{{jms.destinationType}}:{{jms.destinationName}}?exchangePattern=InOnly")
```
And to listen to messages from that broker, we need also another line with the same configurations:
```
from("jms:{{jms.destinationType}}:{{jms.destinationName}}")
```
The configurations will be seeded to a configMap using:
```
oc create configmap my-jms-config --from-file=jms-config.properties
```
And it contains the following details:
```
# Use AMQ Kubernetes service name or IP address and port
quarkus.qpid-jms.url=amqp://my-amq-amqp-0-svc:5672
# Use either queue or topic
jms.destinationType=queue
# Queue or Topic name
jms.destinationName=my-messages
```

To install the full demo by a single script, simply run the following commands:
```
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/amq-example/setup-script.sh > jms-setup-script.sh
chmod +x jms-setup-script.sh

./jms-setup-script.sh jms-project
```
Where jms-project is the name of OpenShift project where all the deployment artifacts will happen.
The script will also do some curl commands to test the deployment artifacts.
This install one integration that is exposing a REST interface to send messages and the other integration is listening to the message queue to consume the messages and log them.

<img width="924" alt="Screenshot 2023-06-07 at 15 29 57" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/d706eb8d-6ac6-4400-a663-3c481a266d09">

In that example, you can see 2 types of configuring the depedencies either by: explicitly using -d or --dependency flag as in our previous MySQL example or by adding the depdendency in the route snippet file itself as following:
```
// camel-k: language=java
// camel-k: dependency=mvn:org.amqphub.quarkus:quarkus-qpid-jms 
import org.apache.camel.builder.RouteBuilder;

public class JMSToLogRoute extends RouteBuilder {
 ...
}
```
This is an easier way to maintain everything inside a single code snippet file.
We can also add traits to the file:
```
// camel-k: language=java trait=prometheus.enabled=true 
```

### 3) Setup the Red Hat AMQ Streams (Kafka) Example

First, you need to make sure Red Hat Camel K Operator and Red Hat AMQ Streams (Kafka) Operator are installed in OpenShift cluster.

<img width="278" alt="Screenshot 2023-06-10 at 14 31 45" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/0ca3c2f3-72b7-490d-a348-c1bcd520618d">

We hava a single configurations for the producer and consumer, this can be changed as per your requirements, also we didn't use any authentication for sending/recieving the messages.
We configured the bootstrap URL:Port and topic name for that.
```
# Bootstrap url:port, In this example we used the non-secure port
camel.component.kafka.brokers=my-kafka-cluster-kafka-bootstrap:9092
# Consumer topic name (to listen for messages)
consumer.topic=test-topic
# Producer topic name (to send messages to)
producer.topic=test-topic
```

To send messages:
```
.to("kafka:{{producer.topic}}")
```
To consume messages:
```
from("kafka:{{consumer.topic}}")
```
To install the full demo by a single script, simply run the following commands:
```
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/kafka-sample/setup-script.sh > kafka-setup-script.sh
chmod +x kafka-setup-script.sh

./kafka-setup-script.sh kafka-project
```
<img width="663" alt="Screenshot 2023-06-10 at 14 36 04" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/04701dbd-08e9-403f-a3fe-5695f5f2d85c">

#### Using YAKS for Testing

You can use YAKS for testing the integration, first you need to install the Yaks operator, then create the test cases as following:

<img width="346" alt="Screenshot 2024-06-01 at 4 43 13 PM" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/1550a8cf-f656-49a0-8222-21a74fed1188">

```
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/kafka-sample/yaks/test.yaml > test.yaml
oc apply -f test.yaml
```
The file contains 3 test scenarios that test the REST method response and the Kafka message content
```
      Scenario: Scenario 1
        Given HTTP request body: No thing to send
        When send GET /send/Hello-from-Osa-Ora
        Then receive HTTP 200 OK

      Scenario: Scenario 2
        Given HTTP request body: No thing to send
        When send GET /send/Hello-from-Osa-Ora
        Then receive HTTP 200 OK
        
      Scenario: Scenario 3
        Given HTTP request body: No thing to send
        When send GET /send/Hello-from-Osa-Ora
        Then receive HTTP 200 OK
        And verify Kafka message with body: {"message":"Hello-from-Osa-Ora"}
```
Once executed, you can see the test scenario(s) results.


#### Using Kamelet and KameletBinding
We can also use Kamelet as a simplified way to re-use existing pre-written integration, and provide our properties for that integration. Camel-K operator will install a pre-set of Kamelet for you so you can consume directly either as Source or Sink via creating KameletBinding with the required properties.

<img width="761" alt="Screenshot 2024-05-31 at 12 14 34 PM" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/3ebb593f-1b29-476c-ae3c-805025eb2411">


To create a consumer from Kafka similar to what we did in that demo, you can execute the following:
```
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/kafka-sample/kamelet/kafka-to-log-binding.yaml --> kafka-log-binding.yaml
oc apply -f kafka-log-binding.yaml
```
Camel-K operator will take this KameletBinding and create an Integraiton for you, which then create the required flow, if we examined this Binding:
```
apiVersion: camel.apache.org/v1alpha1
kind: KameletBinding
metadata:
 name: log-kafka-messages
 namespace: kafka-project
spec:
 sink:
   ref:
     apiVersion: camel.apache.org/v1alpha1
     name: log-sink
     kind: Kamelet
 source:
   properties:
     bootstrapServers: 'my-kafka-cluster-kafka-bootstrap:9092'
     password: e
     securityProtocol: PLAINTEXT
     topic: test-topic
     user: e
   ref:
     apiVersion: camel.apache.org/v1alpha1
     name: kafka-source
     kind: Kamelet
```
You can see we have provided source and sink and then override the required parameters for our Kafka consumer.
Note: our Kafka cluster doesn't have any authentication requirement, so we have added dummy user and password in that Binding.




## Design the Integrations
***
You can use different tools or examples that are available already everywhere, you can use ChatGPT for example, or you can use KAOTO design tool to design the integration flow either as a standalone or part of Visual Studio Code by installing the plugin.

<img width="1772" alt="Screenshot 2023-06-10 at 19 14 09" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/bf142a5d-7634-4287-904d-f75296f2b95b">


There is a lot of other Camel K examples here: https://github.com/apache/camel-k-examples

