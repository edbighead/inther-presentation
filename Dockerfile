FROM openjdk:8-jdk-alpine

COPY target/app.war app.war

ENTRYPOINT ["java","-jar","/app.war"]