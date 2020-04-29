import ballerina/http;
import ballerina/log;
import ballerina/docker;
import ballerina/runtime;
import ballerina/lang.'int as ints;
import ballerina/io;


@docker:Expose {}
listener http:Listener delayEP = new(9090);
@docker:Config {
    name: "delay",
    tag: "1.0.0"
}
@http:ServiceConfig {
    basePath: "/"
}
service livetraining on delayEP {
    resource function versao(http:Caller outboundEP, http:Request request) {
        http:Response response = new;

        int delay = 5000;
        string sdelay = "5000";

        if ( request.hasHeader("x-delay") ) {
            sdelay = request.getHeader("x-delay");
            io:println("milissegundos: ", sdelay );

            int|error res1 = 'ints:fromString( request.getHeader("x-delay") );
            if( res1 is int ) {
                delay = res1;
            }
        }

        runtime:sleep(delay);
        response.setTextPayload("Delay v1.0.0" );

        var responseResult = outboundEP->respond(response);
        if (responseResult is error) {
            error err = responseResult;
            log:printError("Error sending response", err);
        }
    }
}
