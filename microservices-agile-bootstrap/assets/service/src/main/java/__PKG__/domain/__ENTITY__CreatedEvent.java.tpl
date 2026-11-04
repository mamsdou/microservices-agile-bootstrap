package @@PACKAGE@@.domain;

import java.time.Instant;
import java.util.UUID;

/**
 * Evenement de domaine, publie sur Kafka (topic "@@TOPIC@@") apres validation de la transaction.
 * C'est un contrat entre services : le faire evoluer de maniere retrocompatible.
 */
public record @@ENTITY@@CreatedEvent(UUID id, String name, Instant occurredAt) {

    public static @@ENTITY@@CreatedEvent from(@@ENTITY@@ entity) {
        return new @@ENTITY@@CreatedEvent(entity.getId(), entity.getName(), entity.getCreatedAt());
    }
}
