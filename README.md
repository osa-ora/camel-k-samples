# Camel-k Samples

Camel K is a lightweight integration framework built from Apache Camel that runs natively on Kubernetes and is specifically designed for serverless and microservice architectures.
Quarkus serves as the runtime framework for Camel K, providing lightweight, fast, and cloud-native capabilities that enable the efficient development and deployment of Apache Camel integrations

<img width="206" alt="Screenshot 2023-05-20 at 23 44 50" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/20bf6b5c-b86d-45db-9f66-f2325300e295">

## Setup the Environment
- Make sure you have a ready OpenShift cluster
- Setup Camel-K Red Hat Operator
- Download Kamel command line
- Make sure you have oc command line installed

The magic of Camel-K is that you write using DSL either code or YAML file and the platform will do the remaining for you, so let's see some scenarios for our usual operations:

<img width="1066" alt="Screenshot 2023-05-20 at 23 43 47" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/1947380c-72b9-46c2-9b14-718ec47d59e5">


### Build the Integration
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
This example expose REST API to be called /api/hello/{name} and return Hello {Name}, in both ways writing the integration is simple and to the purpose of our integratin requirements.
We have a better example of invoking REST API to retireve data from the database "MySQL"
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
### Use Runtime Configurations
If our integration needs some configurations, we can use either configmap or secret for that.
So for example in our Database example, we are defining a secret for the MySQL datasource:
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

### Deploy the Integration for Dev Mode & Prod Mode
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
To run withut the dev mode, simply remove it:
```
kamel run hello.camelk.yaml
or
kamel run MyRestRoute.java
```
### Check the Integrations Status
You can run the get command to list the deployed integrations and you can run the logs command to get the specific integration logs, but in Dev Mode you don't need to get the logs as it will be in the console.  
```
kamel get // will return all the integration in the current namespace
kamel logs my-rest-route //will return the logs of this integration
```
You can use -n to specify different namespace.
### Use the runtime configurations
To use the configuration either config map or secret use the --configmap or --secret flag specifies the name of the ConfigMap or Secret, or -config configmap:{configmap-name} -config secret:{secret-name}
We will see this in the next section.

### Use Dependencies
In our MySQL example, we need to add some depedencies for the MySQL JDBC using -d or --dependency flag, so we will run the integration using:
```
kamel run AccountDataRoute.java --build-property quarkus.datasource.camel.db-kind=mysql -d mvn:io.quarkus:quarkus-jdbc-mysql  --config secret:my-datasource --dependency camel-jdbc
```
In this command, we used build property, depdendencies and secret.

### Update the Integration
To update the integration, simply modify the code, re-run the run command and the integration will be updated automatically.

### Scale the Integration (Manual or Autoscaling)
You can easily scale the integration from the command line using:
```
oc scale it account-data-route --replicas 2
```
Or you can deploy the integration using Knative for auto-scaling feature which is very useful in that case.


### Get The Integration Logs
Using the logs flag as we discussed before.
```
kamel logs account-data-route
```
### Monitor the Integration
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
Now, when you run the integration you can enable the monitoring for it using "-t prometheus.enabled=true" or globally for all the integrations:
```
kamel run AccountDataRoute.java --build-property quarkus.datasource.camel.db-kind=mysql -d mvn:io.quarkus:quarkus-jdbc-mysql  --config secret:my-datasource --dependency camel-jdbc -t prometheus.enabled=true
```
Now you can monittor the metrics for your integration:

<img width="1476" alt="Screenshot 2023-05-21 at 11 59 32" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/6951d4c9-9094-49a1-98ac-b600af77c6be">

Also you can define custom metrics inside your integration and monitor them as well using microprofile.metrics.    


### Delete the Integration
By simply executing the delete flag:
```
Kamel delete account-data-route
```

### Building Native Integration
As Quarkus is also allow for native compilation, we can deploy it as a native deployment which has the best efficient memory and CPU utilization and fast start up time, but compiling the integration for native will take time, thankfully Camel K allow for building the integration quickly as Java deployment and behind the scene is doing the native compilation, once the native integration is ready it will seamlessly replace the Java with the native pod:
```
kamel run github:osa-ora/camel-k-samples/yaml-samples/rest-sample.yaml -t quarkus.package-type=fast-jar -t quarkus.package-type=native
```
As we can see in the pod metrics, the memory and cpu utilization is much more lower in the native one.
Traditional Java Quarkus:
<img width="1489" alt="Screenshot 2023-05-24 at 12 05 20" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/0893d928-ebe5-4df8-a748-4e148d84df2a">


Native Quarkus:
<img width="1477" alt="Screenshot 2023-05-24 at 12 12 35" src="https://github.com/osa-ora/camel-k-samples/assets/18471537/d3afb28c-d84e-471c-ad58-1d27e8aa9df5">


### Setup the MySQL-REST Example
By simply run the following commands:
```
curl https://raw.githubusercontent.com/osa-ora/camel-k-samples/main/mysql-example/setup-script.sh > setup-script.sh
chmod +x setup-script.sh
./setup-script.sh camel-project
```
Where camel-project is the OpenShift project name where all the deployment artifacts will happen.
The script will also do some curl commands to test the deployment artifacts.


There is a lot of other Camel K examples here: https://github.com/apache/camel-k-examples

