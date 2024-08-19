# Step 1: Build the Scouter project using UBI8 with JDK
FROM registry.access.redhat.com/ubi8/openjdk-11:latest AS build

# Set the working directory
WORKDIR /app

# Copy the pom.xml and download dependencies
COPY . .

# Copy the source code and build the project
RUN mvn -Dmaven.test.skip=true clean install
RUN mvn -Dmaven.test.skip=true -f ./scouter.agent.java/pom.xml -Pjava-legacy clean package
RUN mvn -Dmaven.test.skip=true -f ./scouter.deploy/pom.xml clean package


# Step 2: Prepare the runtime image using UBI8 with JRE
FROM registry.access.redhat.com/ubi8/openjdk-11-runtime:latest


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