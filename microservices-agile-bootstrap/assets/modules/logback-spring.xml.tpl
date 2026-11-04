<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <include resource="org/springframework/boot/logging/logback/defaults.xml"/>
  <include resource="org/springframework/boot/logging/logback/console-appender.xml"/>

  <springProperty scope="context" name="appName" source="spring.application.name" defaultValue="unknown"/>

  <!-- Profil "elk" : les logs partent aussi en JSON vers Logstash (TCP 5000). -->
  <springProfile name="elk">
    <appender name="LOGSTASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
      <destination>${LOGSTASH_HOST:-localhost}:5000</destination>
      <reconnectionDelay>5 seconds</reconnectionDelay>
      <encoder class="net.logstash.logback.encoder.LogstashEncoder">
        <customFields>{"app":"${appName}"}</customFields>
      </encoder>
    </appender>
    <root level="INFO">
      <appender-ref ref="CONSOLE"/>
      <appender-ref ref="LOGSTASH"/>
    </root>
  </springProfile>

  <springProfile name="!elk">
    <root level="INFO">
      <appender-ref ref="CONSOLE"/>
    </root>
  </springProfile>
</configuration>
