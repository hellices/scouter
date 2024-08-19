# Base image
FROM openjdk:11-jre-slim

# Set the working directory
WORKDIR /scouter

# Copy the Scouter server files to the container
COPY target/scouter-server /scouter

# Download the zipkin-scouter-storage plugin
RUN wget https://github.com/scouter-project/zipkin-scouter-storage/releases/download/v0.0.3/zipkin-scouter-storage-0.0.3.jar -P /scouter/lib

# Expose the necessary ports
EXPOSE 6100 6180

# Command to start the Scouter server
CMD ["java", "-classpath", "lib/*", "scouter.boot.Boot"]