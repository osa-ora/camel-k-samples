import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.rest.RestBindingMode;

public class RestToJMSRoute extends RouteBuilder {

   @Override
   public void configure() throws Exception {
   
        // Define REST API endpoint
        rest("/send")
            .get("/{message}")
            .to("direct:sendMessage");

        // Define the route to retrieve user account details from the database
        from("direct:sendMessage")
            .setHeader("Content-Type", constant("application/json"))
            .setBody(simple("{'message':'${header.message}'}"))
            .to("jms:{{jms.destinationType}}:{{jms.destinationName}}?exchangePattern=InOnly")
            .log("Message details: ${body}");
   }
}
