# Step 1: Build the Scouter project
FROM maven:3.8.5-openjdk-11-slim AS build

# Set the working directory
WORKDIR /app

# Copy the pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy the source code and build the project
RUN mvn -Dmaven.test.skip=true clean install
RUN mvn -Dmaven.test.skip=true -f ./scouter.agent.java/pom.xml -Pjava-legacy clean package
RUN mvn -Dmaven.test.skip=true -f ./scouter.deploy/pom.xml clean package

# Step 2: Prepare the runtime image
FROM openjdk:11-jre-slim

# Set the working directory
WORKDIR /scouter

# Copy the built Scouter server files from the build stage
COPY --from=build /app/scouter-deploy/target /scouter

# Download the zipkin-scouter-storage plugin
RUN wget https://github.com/scouter-project/zipkin-scouter-storage/releases/download/v0.0.3/zipkin-scouter-storage-0.0.3.jar -P /scouter/lib

# Expose the necessary ports
EXPOSE 6100 6180

# Command to start the Scouter server
CMD ["java", "-classpath", "lib/*", "scouter.boot.Boot"]