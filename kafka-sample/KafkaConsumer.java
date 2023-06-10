// camel-k: language=java dependency=mvn:org.apache.camel.quarkus:camel-quarkus-kafka dependency=mvn:io.strimzi:kafka-oauth-client:0.7.1.redhat-00003

import org.apache.camel.builder.RouteBuilder;

public class KafkaConsumer extends RouteBuilder {
    @Override
    public void configure() throws Exception {
        log.info("Starting Kafka Consumer");

        from("kafka:{{consumer.topic}}")
            .log("${body}");
    }
}
