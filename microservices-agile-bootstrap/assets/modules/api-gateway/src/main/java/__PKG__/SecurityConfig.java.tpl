package @@PACKAGE@@;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

/**
 * La gateway exige un jeton JWT valide (emis par Keycloak) sur toute l'API ; les droits par role
 * sont verifies par chaque service (defense en profondeur, voir ADR-0010). Le jeton est relaye
 * tel quel aux services.
 */
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        return http
            .csrf(ServerHttpSecurity.CsrfSpec::disable)
            .authorizeExchange(exchanges -> exchanges
                // Les requetes de pre-vol CORS n'ont pas de jeton ; la gateway y repond ensuite.
                .pathMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .pathMatchers("/actuator/health/**", "/actuator/info").permitAll()
                .pathMatchers("/api/**").authenticated()
                .anyExchange().denyAll())
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
            .build();
    }
}
