package @@PACKAGE@@.messaging;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Consomme les evenements du service "@@SOURCE_SERVICE@@" (topic "@@SOURCE_TOPIC@@").
 * Exemple minimal : on journalise. A remplacer par la reaction metier (et rendre le traitement
 * idempotent : Kafka garantit une livraison au moins une fois).
 */
@Component
public class @@SOURCE_ENTITY@@EventListener {

    private static final Logger log = LoggerFactory.getLogger(@@SOURCE_ENTITY@@EventListener.class);

    @KafkaListener(topics = "${app.kafka.source-topic}", groupId = "${spring.kafka.consumer.group-id}")
    public void onMessage(String payload) {
        log.info("Evenement recu de @@SOURCE_SERVICE@@ : {}", payload);
    }
}
