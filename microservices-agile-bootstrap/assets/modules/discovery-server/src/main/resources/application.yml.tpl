server:
  port: ${SERVER_PORT:8761}

spring:
  application:
    name: discovery-server

eureka:
  instance:
    hostname: ${EUREKA_HOSTNAME:localhost}
  client:
    register-with-eureka: false
    fetch-registry: false
  server:
    # Avoids noisy self-preservation messages in development.
    enable-self-preservation: false

management:
  endpoint:
    health:
      probes:
        enabled: true
  endpoints:
    web:
      exposure:
        include: health,info
