server:
  port: ${SERVER_PORT:8888}

spring:
  application:
    name: config-server
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:native}
  cloud:
    config:
      server:
        native:
          # En production : remplacer par un depot Git (voir ADR-0002).
          search-locations: classpath:/config-repo/

management:
  endpoint:
    health:
      probes:
        enabled: true
  endpoints:
    web:
      exposure:
        include: health,info
