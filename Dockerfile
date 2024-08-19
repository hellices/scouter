# Base image: Use an appropriate base image with Java runtime
FROM openjdk:11-jre-slim

# Set the working directory inside the container
WORKDIR /scouter/server

# Copy the Scouter server files into the container
COPY ./scouter/server /scouter/server

# Expose the necessary ports (adjust according to Scouter's config)
EXPOSE 6100 6180

# Ensure the startup script has execute permissions
RUN chmod +x ./startup.sh

# Command to start the Scouter server
CMD ["./startup.sh"]