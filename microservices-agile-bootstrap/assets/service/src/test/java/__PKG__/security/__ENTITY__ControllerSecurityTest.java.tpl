package @@PACKAGE@@.security;

import static org.mockito.BDDMockito.given;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import @@PACKAGE@@.domain.@@ENTITY@@;
import @@PACKAGE@@.service.@@ENTITY@@Service;
import @@PACKAGE@@.web.@@ENTITY@@Controller;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

/** Checks the access matrix: no token 401, a reader cannot write (403), a writer can. */
@WebMvcTest(@@ENTITY@@Controller.class)
@Import(SecurityConfig.class)
@TestPropertySource(properties = {
    "app.security.read-roles=reader",
    "app.security.write-roles=writer",
    "spring.cloud.config.enabled=false",
    "eureka.client.enabled=false"
})
class @@ENTITY@@ControllerSecurityTest {

    @Autowired
    private MockMvc mvc;

    @MockBean
    private @@ENTITY@@Service service;

    @MockBean
    private JwtDecoder jwtDecoder;

    private static RequestPostProcessor as(String role) {
        return jwt().authorities(new SimpleGrantedAuthority("ROLE_" + role));
    }

    @Test
    void request_without_token_is_unauthorized() throws Exception {
        mvc.perform(get("/api/@@RESOURCE@@")).andExpect(status().isUnauthorized());
    }

    @Test
    void reader_can_list() throws Exception {
        given(service.findAll()).willReturn(List.of());
        mvc.perform(get("/api/@@RESOURCE@@").with(as("reader"))).andExpect(status().isOk());
    }

    @Test
    void writer_can_also_list() throws Exception {
        given(service.findAll()).willReturn(List.of());
        mvc.perform(get("/api/@@RESOURCE@@").with(as("writer"))).andExpect(status().isOk());
    }

    @Test
    void user_with_unrelated_role_is_forbidden() throws Exception {
        mvc.perform(get("/api/@@RESOURCE@@").with(as("stranger"))).andExpect(status().isForbidden());
    }

    @Test
    void reader_cannot_create() throws Exception {
        mvc.perform(post("/api/@@RESOURCE@@").with(as("reader"))
                .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"demo\"}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void writer_can_create() throws Exception {
        given(service.create("demo")).willReturn(new @@ENTITY@@("demo"));
        mvc.perform(post("/api/@@RESOURCE@@").with(as("writer"))
                .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"demo\"}"))
            .andExpect(status().isCreated());
    }
}
