import wso2/gateway;
import ballerina/http;
import ballerina/config;

import ballerina/docker;



//Throttle tier data initiation
// todo: can remove this since this is not used

    json ClientCerts=null;


http:ListenerConfiguration secureServiceEndpointConfiguration = { 
   httpVersion: gateway:getHttpVersion(),
                                                                   http1Settings : {
    keepAlive: gateway:getKeepAliveValue(),
    maxPipelinedRequests: gateway:getConfigIntValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:MAX_PIPELINED_REQUESTS, gateway:DEFAULT_MAX_PIPELINED_REQUESTS),
    maxUriLength: gateway:getConfigIntValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:MAX_URI_LENGTH, gateway:DEFAULT_MAX_URI_LENGTH),
    maxHeaderSize: gateway:getConfigIntValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:MAX_HEADER_SIZE, gateway:DEFAULT_MAX_HEADER_SIZE),
    maxEntityBodySize: gateway:getConfigIntValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:MAX_ENTITY_BODY_SIZE, gateway:DEFAULT_MAX_ENTITY_BODY_SIZE)
},

                                                                           // todo: This template can be removed, since this is not being used.
secureSocket: {
keyStore: {
path:  config:getAsString("listenerConfig.keyStore.path"),
password: config:getAsString("listenerConfig.keyStore.password")
},
trustStore: {
path:  config:getAsString("listenerConfig.trustStore.path"),
password: config:getAsString("listenerConfig.trustStore.password")
},
protocol: {
name: config:getAsString("mutualSSLConfig.ProtocolName"),
versions: ["TLSv1.2", "TLSv1.1"]
},


sslVerifyClient: config:getAsString("mutualSSLConfig.sslVerifyClient")
},

                                                                           filters:getFilters()
                                                                       };


@docker:Config {
    name:"delay-api",
    tag:"1.0.0",
    baseImage:"wso2/wso2micro-gw:3.1.0",
    cmd: "CMD gateway ${APP}"
}





listener gateway:APIGatewaySecureListener apiSecureListener = new(9095, secureServiceEndpointConfiguration);

http:ListenerConfiguration serviceEndpointConfiguration = { 
   httpVersion: gateway:getHttpVersion(),
                                                            http1Settings : {
    keepAlive: gateway:getKeepAliveValue(),
    maxPipelinedRequests: gateway:getConfigIntValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:MAX_PIPELINED_REQUESTS, gateway:DEFAULT_MAX_PIPELINED_REQUESTS),
    maxUriLength: gateway:getConfigIntValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:MAX_URI_LENGTH, gateway:DEFAULT_MAX_URI_LENGTH),
    maxHeaderSize: gateway:getConfigIntValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:MAX_HEADER_SIZE, gateway:DEFAULT_MAX_HEADER_SIZE),
    maxEntityBodySize: gateway:getConfigIntValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:MAX_ENTITY_BODY_SIZE, gateway:DEFAULT_MAX_ENTITY_BODY_SIZE)
},

                                                                     filters:getFilters()
                                                                 };



listener gateway:APIGatewayListener apiListener = new(9090, serviceEndpointConfiguration);




listener http:Listener tokenListenerEndpoint = new (
    
        gateway:getConfigIntValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:TOKEN_LISTENER_PORT, gateway:DEFAULT_TOKEN_LISTENER_PORT), config = {
        host: gateway:getConfigValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:LISTENER_CONF_HOST, gateway:DEFAULT_CONF_HOST),
        secureSocket: {
            keyStore: {
                path: gateway:getConfigValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:KEY_STORE_PATH,
                    gateway:DEFAULT_KEY_STORE_PATH),
                password: gateway:getConfigValue(gateway:LISTENER_CONF_INSTANCE_ID, gateway:KEY_STORE_PASSWORD,
                    gateway:DEFAULT_KEY_STORE_PASSWORD)
            }
        }
    
    }
);

public function getFilters() returns (http:RequestFilter|http:ResponseFilter) [] {
    map<json> deployedPolicies = getDeployedPolicies();

    // Grpc Filter
    gateway:GrpcFilter grpcFilter = new gateway:GrpcFilter();
    // Authentication filter
    gateway:PreAuthnFilter | gateway:PreAuthnFilterWrapper preAuthnFilter;
    // Throttling filter
    gateway:ThrottleFilter | gateway:ThrottleFilterWrapper throttleFilter;
    // Analytic filter
    gateway:AnalyticsRequestFilter analyticsFilter;
    //Validation Request filter
    gateway:ValidationRequestFilter | gateway:ValidationRequestFilterWrapper validationRequestFilter;
    //Validation filter
    gateway:ValidationResponseFilter | gateway:ValidationResponseFilterWrapper validationResponseFilter;
    // Authorization filter
    gateway:OAuthzFilter | gateway:OAuthzFilterWrapper  authorizationFilter;

    boolean isObservable = gateway:getConfigBooleanValue(gateway:MICRO_GATEWAY_METRICS, gateway:ENABLED, false)
        || gateway:getConfigBooleanValue(gateway:MICRO_GATEWAY_TRACING, gateway:ENABLED, false);
    
    if (isObservable) {
        preAuthnFilter = new gateway:PreAuthnFilterWrapper();
        throttleFilter = new gateway:ThrottleFilterWrapper(deployedPolicies);
        analyticsFilter =  new gateway:AnalyticsRequestFilterWrapper();
        validationRequestFilter = new gateway:ValidationRequestFilterWrapper();
        validationResponseFilter = new gateway:ValidationResponseFilterWrapper();
    } else {
        preAuthnFilter = new gateway:PreAuthnFilter();
        throttleFilter = new gateway:ThrottleFilter(deployedPolicies);
        analyticsFilter =  new gateway:AnalyticsRequestFilter();
        validationRequestFilter = new gateway:ValidationRequestFilter();
        validationResponseFilter = new gateway:ValidationResponseFilter();
    }

    authorizationFilter = gateway:getDefaultAuthorizationFilter();

    // Extension filter
    ExtensionFilter extensionFilter = new;

    return [grpcFilter, preAuthnFilter, authorizationFilter, validationRequestFilter, throttleFilter,
            analyticsFilter, validationResponseFilter, extensionFilter];
}

