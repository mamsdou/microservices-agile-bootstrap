package @@PACKAGE@@.messaging;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
public class KafkaTopicConfig {

    /** Declare le topic du service ; cree au demarrage s'il n'existe pas. */
    @Bean
    NewTopic serviceEventsTopic(@Value("${app.kafka.topic}") String topic) {
        return TopicBuilder.name(topic).partitions(3).replicas(1).build();
    }
}
