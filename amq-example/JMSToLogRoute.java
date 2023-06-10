// camel-k: language=java
// camel-k: dependency=mvn:org.amqphub.quarkus:quarkus-qpid-jms 
import org.apache.camel.builder.RouteBuilder;

public class JMSToLogRoute extends RouteBuilder {
  @Override
  public void configure() throws Exception {

      from("jms:{{jms.destinationType}}:{{jms.destinationName}}")
        .to("log:info");
  }
}
