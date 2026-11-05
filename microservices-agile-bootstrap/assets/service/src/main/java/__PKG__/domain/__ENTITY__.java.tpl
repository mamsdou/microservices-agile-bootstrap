package @@PACKAGE@@.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Sample aggregate: replace with the real domain model.
 * This service is the only owner of the "@@TABLE@@" table.
 */
@Entity
@Table(name = "@@TABLE@@")
public class @@ENTITY@@ {

    @Id
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected @@ENTITY@@() {
        // required by JPA
    }

    public @@ENTITY@@(String name) {
        this.id = UUID.randomUUID();
        this.name = name;
        this.createdAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
