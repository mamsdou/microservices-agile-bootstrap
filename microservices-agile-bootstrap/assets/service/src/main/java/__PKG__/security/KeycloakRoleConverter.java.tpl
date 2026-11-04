package @@PACKAGE@@.security;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

/**
 * Transforme les roles de realm Keycloak (claim "realm_access.roles") en autorites Spring
 * "ROLE_<nom>", utilisables avec hasRole / hasAnyRole.
 */
public class KeycloakRoleConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

    @Override
    public Collection<GrantedAuthority> convert(Jwt jwt) {
        Map<String, Object> realmAccess = jwt.getClaimAsMap("realm_access");
        if (realmAccess == null) {
            return List.of();
        }
        Object roles = realmAccess.get("roles");
        if (!(roles instanceof Collection<?> values)) {
            return List.of();
        }
        return values.stream()
            .<GrantedAuthority>map(role -> new SimpleGrantedAuthority("ROLE_" + role))
            .toList();
    }
}
