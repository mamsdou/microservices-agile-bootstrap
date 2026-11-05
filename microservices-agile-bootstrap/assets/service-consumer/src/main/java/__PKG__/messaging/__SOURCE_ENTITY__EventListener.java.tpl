package @@PACKAGE@@.messaging;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Consumes the events of the "@@SOURCE_SERVICE@@" service (topic "@@SOURCE_TOPIC@@").
 * Minimal example: it only logs. Replace with the business reaction (and make the processing
 * idempotent: Kafka guarantees at-least-once delivery).
 */
@Component
public class @@SOURCE_ENTITY@@EventListener {

    private static final Logger log = LoggerFactory.getLogger(@@SOURCE_ENTITY@@EventListener.class);

    @KafkaListener(topics = "${app.kafka.source-topic}", groupId = "${spring.kafka.consumer.group-id}")
    public void onMessage(String payload) {
        log.info("Event received from @@SOURCE_SERVICE@@ : {}", payload);
    }
}
