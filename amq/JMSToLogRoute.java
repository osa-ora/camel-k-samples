import org.apache.camel.builder.RouteBuilder;

public class JMSToLogRoute extends RouteBuilder {
  @Override
  public void configure() throws Exception {

      from("jms:{{jms.destinationType}}:{{jms.destinationName}}")
        .to("log:info");
  }
}
