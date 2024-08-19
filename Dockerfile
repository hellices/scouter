# Base image: Use an appropriate base image with Java runtime
FROM openjdk:11-jre-slim

# Set the working directory inside the container
WORKDIR /server

# Copy the Scouter server files into the container
COPY ./server /server
COPY ./webapp /webapp

# Expose the necessary ports (adjust according to Scouter's config)
EXPOSE 6100 6180

# Command to start the Scouter server
ENTRYPOINT ["java", "-classpath", "./scouter-server-boot.jar", "scouter.boot.Boot", "./lib"]