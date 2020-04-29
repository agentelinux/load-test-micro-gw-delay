# Auto Generated Dockerfile
FROM openjdk:8-jre-alpine

LABEL maintainer="dev@ballerina.io"

RUN addgroup troupe \
    && adduser -S -s /bin/bash -g 'ballerina' -G troupe -D ballerina \
    && apk add --update --no-cache bash \
    && chown -R ballerina:troupe /usr/bin/java \
    && rm -rf /var/cache/apk/*

WORKDIR /home/ballerina

COPY delay.jar /home/ballerina

EXPOSE  9090
USER ballerina

CMD java -jar delay.jar
