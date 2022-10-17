FROM openjdk:11-jre-slim
COPY target/*.jar /usr/local/lib/petclinic.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/usr/local/lic/petclinic.jar"]