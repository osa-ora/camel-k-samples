import org.apache.camel.Exchange;
import org.apache.camel.Header;
import org.apache.camel.builder.RouteBuilder;

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
