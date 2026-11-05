package @@PACKAGE@@.domain;

import java.time.Instant;
import java.util.UUID;

/**
 * Domain event, published to Kafka (topic "@@TOPIC@@") after the transaction commits.
 * This is a contract between services: evolve it in a backward-compatible way.
 */
public record @@ENTITY@@CreatedEvent(UUID id, String name, Instant occurredAt) {

    public static @@ENTITY@@CreatedEvent from(@@ENTITY@@ entity) {
        return new @@ENTITY@@CreatedEvent(entity.getId(), entity.getName(), entity.getCreatedAt());
    }
}
