// camel-k: language=java
// camel-k: dependency=mvn:org.amqphub.quarkus:quarkus-qpid-jms

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.rest.RestBindingMode;

public class RestToMQTTRoute extends RouteBuilder {

   @Override
   public void configure() throws Exception {
   
    onException(Exception.class)
    .log("Error occurred: ${exception.message}")
    .handled(true);

// Define REST API endpoint
rest("/send")
    .get("/{message}")
    .to("direct:sendMQTT");

// Route to send message to JMS
from("direct:sendJMS")
    .setBody(simple("{'message':'${header.message} - JMS Message'}"))
    .log("Sending message to JMS: ${body}")
    .to("jms:{{jms.destinationType}}:{{jms.destinationName}}?exchangePattern=InOnly")
    .to("direct:sendMQTT");

// Route to send message to MQTT
from("direct:sendMQTT")
    .setBody(simple("{'message':'${header.message} - MQTT Message'}"))
    .log("Sending message to MQTT: ${body}")
    .to("paho-mqtt5:{{mqtt.destinationName}}?brokerUrl={{mqtt.brokerUrl}}&qos=1&username=admin&password=adminPass")
    .log("Message successfully sent to MQTT")
    .setHeader("Content-Type", constant("application/json"))
    .log("Message details: ${body}");
   }
}
