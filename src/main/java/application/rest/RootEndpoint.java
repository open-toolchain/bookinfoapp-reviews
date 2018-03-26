package application.rest;

import java.io.StringReader;
import java.util.List;
import javax.json.Json;
import javax.json.JsonObject;
import javax.json.JsonObjectBuilder;
import javax.json.JsonReader;
import javax.ws.rs.CookieParam;
import javax.ws.rs.GET;
import javax.ws.rs.HeaderParam;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.client.Invocation;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.Cookie;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;


@Path("/")
public class RootEndpoint {

    private final static Boolean ratings_enabled = true; // Boolean.valueOf(System.getenv("ENABLE_RATINGS"));
    // private final static String star_color = System.getenv("STAR_COLOR") == null ? "black" : System.getenv("STAR_COLOR");
    private final static String star_color = "red";
    private final static String ratings_service = "http://ratings:9080/ratings";

    private String getJsonResponse (String productId, int starsReviewer1, int starsReviewer2) {
        String result = "{";
        result += "\"id\": \"" + productId + "\",";
        result += "\"reviews\": [";

        // reviewer 1:
        result += "{";
        result += "  \"reviewer\": \"Reviewer1\",";
        result += "  \"text\": \"An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!\"";
        if (ratings_enabled) {
            if (starsReviewer1 != -1) {
                result += ", \"rating\": {\"stars\": " + starsReviewer1 + ", \"color\": \"" + star_color + "\"}";
            } else {
                result += ", \"rating\": {\"error\": \"Ratings service is currently unavailable\"}";
            }
        }
        result += "},";

        // reviewer 2:
        result += "{";
        result += "  \"reviewer\": \"Reviewer2\",";
        result += "  \"text\": \"Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.\"";
        if (ratings_enabled) {
            if (starsReviewer2 != -1) {
                result += ", \"rating\": {\"stars\": " + starsReviewer2 + ", \"color\": \"" + star_color + "\"}";
            } else {
                result += ", \"rating\": {\"error\": \"Ratings service is currently unavailable\"}";
            }
        }
        result += "}";

        result += "]";
        result += "}";

        return result;
    }

    private JsonObject getRatings(String productId, Cookie user, String xreq, String xtraceid, String xspanid,
                                  String xparentspanid, String xsampled, String xflags, String xotspan){
        ClientBuilder cb = ClientBuilder.newBuilder();
        String timeout = star_color.equals("black") ? "10000" : "2500";
        cb.property("com.ibm.ws.jaxrs.client.connection.timeout", timeout);
        cb.property("com.ibm.ws.jaxrs.client.receive.timeout", timeout);
        Client client = cb.build();
        WebTarget ratingsTarget = client.target(ratings_service + "/" + productId);
        Invocation.Builder builder = ratingsTarget.request(MediaType.APPLICATION_JSON);
        if(xreq!=null) {
            builder.header("x-request-id",xreq);
        }
        if(xtraceid!=null) {
            builder.header("x-b3-traceid",xtraceid);
        }
        if(xspanid!=null) {
            builder.header("x-b3-spanid",xspanid);
        }
        if(xparentspanid!=null) {
            builder.header("x-b3-parentspanid",xparentspanid);
        }
        if(xsampled!=null) {
            builder.header("x-b3-sampled",xsampled);
        }
        if(xflags!=null) {
            builder.header("x-b3-flags",xflags);
        }
        if(xotspan!=null) {
            builder.header("x-ot-span-context",xotspan);
        }
        if(user!=null) {
            builder.cookie(user);
        }
        Response r = builder.get();
        int statusCode = r.getStatusInfo().getStatusCode();
        if (statusCode == Response.Status.OK.getStatusCode() ) {
            StringReader stringReader = new StringReader(r.readEntity(String.class));
            try (JsonReader jsonReader = Json.createReader(stringReader)) {
                JsonObject j = jsonReader.readObject();
                return j;
            }
        }else{
            System.out.println("Error: unable to contact "+ratings_service+" got status of "+statusCode);
            return null;
        }
    }

    @GET
    @Path("/health")
    public Response health() {
        return Response.ok().type(MediaType.APPLICATION_JSON).entity("{\"status\": \"Reviews is healthy\"}").build();
    }

    @GET
    @Path("/{productId}")
    public Response bookReviewsById(@PathParam("productId") int productId,
                                    @CookieParam("user") Cookie user,
                                    @HeaderParam("x-request-id") String xreq,
                                    @HeaderParam("x-b3-traceid") String xtraceid,
                                    @HeaderParam("x-b3-spanid") String xspanid,
                                    @HeaderParam("x-b3-parentspanid") String xparentspanid,
                                    @HeaderParam("x-b3-sampled") String xsampled,
                                    @HeaderParam("x-b3-flags") String xflags,
                                    @HeaderParam("x-ot-span-context") String xotspan) {
        System.out.println("MK: reviews called with productId " + productId);

        int starsReviewer1 = -1;
        int starsReviewer2 = -1;

        if (ratings_enabled) {
                JsonObject ratingsResponse = getRatings(Integer.toString(productId), user, xreq, xtraceid, xspanid, xparentspanid, xsampled, xflags, xotspan);
            if (ratingsResponse != null) {
                if (ratingsResponse.containsKey("ratings")) {
                        JsonObject ratings = ratingsResponse.getJsonObject("ratings");
                        if (ratings.containsKey("Reviewer1")){
                                starsReviewer1 = ratings.getInt("Reviewer1");
                        }
                    if (ratings.containsKey("Reviewer2")){
                        starsReviewer2 = ratings.getInt("Reviewer2");
                    }
                }
            }
        }

        String jsonResStr = getJsonResponse(Integer.toString(productId), starsReviewer1, starsReviewer2);
        System.out.println("MK: jsonResStr is: " + jsonResStr);
        return Response.ok().type(MediaType.APPLICATION_JSON).entity(jsonResStr).build();
        //return Response.ok("reviews are cool").build();
    }
}
