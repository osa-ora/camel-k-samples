// camel-k: language=java dependency=mvn:org.apache.camel.quarkus:camel-quarkus-kafka dependency=mvn:io.strimzi:kafka-oauth-client:0.7.1.redhat-00003

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.rest.RestBindingMode;

public class KafkaProducer extends RouteBuilder {
    @Override
    public void configure() throws Exception {
        log.info("Kafak Producer is ready!");
        // Define REST API endpoint
        rest("/send")
            .get("/{message}")
            .to("direct:sendToKafka");

        // Define the route to retrieve user account details from the database
        from("direct:sendToKafka")
            .setHeader("Content-Type", constant("application/json"))
            .setBody(simple("{\"message\":\"${header.message}\"}"))
            .to("kafka:{{producer.topic}}")
            .log("Message correctly sent to the topic: ${body}");
    }
}
