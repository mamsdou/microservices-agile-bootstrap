package @@PACKAGE@@.messaging;

import @@PACKAGE@@.domain.@@ENTITY@@CreatedEvent;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Envoie l'evenement sur Kafka uniquement apres le commit de la transaction : on ne publie jamais
 * un evenement pour une donnee qui n'a finalement pas ete enregistree.
 * Limite connue : si Kafka est indisponible a cet instant, l'evenement est perdu (voir ADR-0005,
 * le pattern Outbox est la solution cible).
 */
@Component
public class @@ENTITY@@EventPublisher {

    private static final Logger log = LoggerFactory.getLogger(@@ENTITY@@EventPublisher.class);

    private final KafkaTemplate<String, String> kafka;
    private final ObjectMapper mapper;
    private final String topic;

    public @@ENTITY@@EventPublisher(KafkaTemplate<String, String> kafka,
                                    ObjectMapper mapper,
                                    @Value("${app.kafka.topic}") String topic) {
        this.kafka = kafka;
        this.mapper = mapper;
        this.topic = topic;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void on(@@ENTITY@@CreatedEvent event) throws JsonProcessingException {
        String payload = mapper.writeValueAsString(event);
        kafka.send(topic, event.id().toString(), payload)
             .whenComplete((result, error) -> {
                 if (error != null) {
                     log.error("Echec de publication sur {} (id={})", topic, event.id(), error);
                 } else {
                     log.info("Evenement publie sur {} (id={})", topic, event.id());
                 }
             });
    }
}
