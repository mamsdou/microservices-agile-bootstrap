server {
  listen 80;
  server_name _;
  root /usr/share/nginx/html;
  index index.html;

  # /api calls are forwarded to the gateway (same service name in Compose and Kubernetes).
  location /api/ {
    proxy_pass http://api-gateway:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }

  location / {
    try_files $uri $uri/ /index.html;
  }
}
