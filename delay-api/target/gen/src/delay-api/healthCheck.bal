import ballerina/http;
import wso2/gateway;

@http:ServiceConfig {
    basePath:"/health",
    auth: {
        enabled: false
    } 
}
@gateway:Filters {
    skipAll: true
}
service healthCheckService on apiListener, apiSecureListener {

    @http:ResourceConfig {
        path: "/*",
        auth: {
            enabled: false
        }
    }
    resource function healthCheck(http:Caller caller, http:Request req) {
        http:Response healthResponse = new;
        json responsePayload = {status: "healthy"};
        healthResponse.setJsonPayload(responsePayload);
        var result = caller->respond(healthResponse);
        if (result is error) {
           gateway:printError(gateway:HEALTH_CHECK_SERVICE, "Error when responding during the authorize endpoint request", result);
        }
    }
}
