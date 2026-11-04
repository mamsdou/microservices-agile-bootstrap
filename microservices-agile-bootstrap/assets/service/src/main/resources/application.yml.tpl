server:
  port: ${SERVER_PORT:@@PORT@@}

spring:
  application:
    name: @@SERVICE@@
  config:
    import: "optional:configserver:${CONFIG_SERVER_URL:http://localhost:8888}"
