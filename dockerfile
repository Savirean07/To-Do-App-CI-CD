# Use Nginx to serve static files
FROM nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy your frontend build files to Nginx's web root
COPY . /usr/share/nginx/html

# Expose port 80 for HTTP
EXPOSE 80

# This is trial of changes i just want to check if it is working or not.

# Start Nginx (default CMD is fine)
