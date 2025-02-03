FROM nginx:latest

# Copy frontend files (HTML, JS, CSS) to Nginx default directory
COPY . /usr/share/nginx/html/

# Expose port 80 for Nginx
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
