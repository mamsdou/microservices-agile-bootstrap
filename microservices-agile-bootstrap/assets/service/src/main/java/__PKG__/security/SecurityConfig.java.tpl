package @@PACKAGE@@.security;

import java.util.Arrays;
import java.util.stream.Stream;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;

/**
 * The service validates the JWT itself (it does not trust the internal network alone) and
 * applies the roles defined in centralized configuration:
 * app.security.write-roles = roles allowed to modify; app.security.read-roles = additional
 * read-only roles. Write roles can also read.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain apiSecurity(HttpSecurity http,
                                    @Value("${app.security.read-roles:}") String[] readRoles,
                                    @Value("${app.security.write-roles}") String[] writeRoles) throws Exception {
        String[] readers = Stream.concat(Arrays.stream(readRoles), Arrays.stream(writeRoles))
            .filter(role -> !role.isBlank())
            .distinct()
            .toArray(String[]::new);

        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health/**", "/actuator/info").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/**").hasAnyRole(readers)
                .requestMatchers("/api/**").hasAnyRole(writeRoles)
                .anyRequest().denyAll())
            .oauth2ResourceServer(oauth -> oauth.jwt(jwt -> jwt.jwtAuthenticationConverter(converter())));
        return http.build();
    }

    private static JwtAuthenticationConverter converter() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(new KeycloakRoleConverter());
        return converter;
    }
}
