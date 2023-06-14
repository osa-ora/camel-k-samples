// camel-k: language=java
// camel-k: dependency=mvn:io.quarkus:quarkus-jdbc-mysql dependency=camel-jdbc
// camel-k: build-property=quarkus.datasource.camel.db-kind=mysql
// camel-k: trait=prometheus.enabled=true
// camel-k: config=secret:my-datasource

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.rest.RestBindingMode;

public class AccountDataRoute extends RouteBuilder {

   @Override
   public void configure() throws Exception {

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
   }
}
