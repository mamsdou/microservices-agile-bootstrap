package @@PACKAGE@@.web;

import @@PACKAGE@@.domain.@@ENTITY@@;
import java.time.Instant;
import java.util.UUID;

public record @@ENTITY@@Response(UUID id, String name, Instant createdAt) {

    public static @@ENTITY@@Response from(@@ENTITY@@ entity) {
        return new @@ENTITY@@Response(entity.getId(), entity.getName(), entity.getCreatedAt());
    }
}
