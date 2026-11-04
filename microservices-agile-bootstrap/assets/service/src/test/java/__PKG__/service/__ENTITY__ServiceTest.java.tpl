package @@PACKAGE@@.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import @@PACKAGE@@.domain.@@ENTITY@@;
import @@PACKAGE@@.domain.@@ENTITY@@CreatedEvent;
import @@PACKAGE@@.domain.@@ENTITY@@Repository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

@ExtendWith(MockitoExtension.class)
class @@ENTITY@@ServiceTest {

    @Mock
    private @@ENTITY@@Repository repository;

    @Mock
    private ApplicationEventPublisher events;

    @InjectMocks
    private @@ENTITY@@Service service;

    @Test
    void create_saves_the_entity_and_publishes_a_created_event() {
        when(repository.save(any(@@ENTITY@@.class))).thenAnswer(invocation -> invocation.getArgument(0));

        @@ENTITY@@ created = service.create("demo");

        assertThat(created.getId()).isNotNull();
        assertThat(created.getName()).isEqualTo("demo");
        verify(events).publishEvent(any(@@ENTITY@@CreatedEvent.class));
    }
}
