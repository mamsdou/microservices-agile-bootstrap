package @@PACKAGE@@.service;

import @@PACKAGE@@.domain.@@ENTITY@@;
import @@PACKAGE@@.domain.@@ENTITY@@CreatedEvent;
import @@PACKAGE@@.domain.@@ENTITY@@Repository;
import java.util.List;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class @@ENTITY@@Service {

    private final @@ENTITY@@Repository repository;
    private final ApplicationEventPublisher events;

    public @@ENTITY@@Service(@@ENTITY@@Repository repository, ApplicationEventPublisher events) {
        this.repository = repository;
        this.events = events;
    }

    @Transactional
    public @@ENTITY@@ create(String name) {
        @@ENTITY@@ saved = repository.save(new @@ENTITY@@(name));
        // Publie en interne ; l'envoi Kafka n'a lieu qu'apres le commit (voir ...EventPublisher).
        events.publishEvent(@@ENTITY@@CreatedEvent.from(saved));
        return saved;
    }

    @Transactional(readOnly = true)
    public List<@@ENTITY@@> findAll() {
        return repository.findAll();
    }
}
