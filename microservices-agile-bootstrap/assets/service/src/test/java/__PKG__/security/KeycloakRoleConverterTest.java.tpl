package @@PACKAGE@@.security;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

class KeycloakRoleConverterTest {

    private final KeycloakRoleConverter converter = new KeycloakRoleConverter();

    private static Jwt.Builder token() {
        return Jwt.withTokenValue("token").header("alg", "none").subject("user");
    }

    @Test
    void maps_realm_roles_to_spring_authorities() {
        Jwt jwt = token().claim("realm_access", Map.of("roles", List.of("alpha", "beta"))).build();

        assertThat(converter.convert(jwt))
            .extracting(GrantedAuthority::getAuthority)
            .containsExactlyInAnyOrder("ROLE_alpha", "ROLE_beta");
    }

    @Test
    void returns_no_authority_when_the_claim_is_missing() {
        assertThat(converter.convert(token().claim("scope", "openid").build())).isEmpty();
    }
}
