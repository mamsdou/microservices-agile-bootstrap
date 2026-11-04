# Image generique pour tous les modules Spring Boot.
# Construction depuis la racine du depot :
#   docker build -f infra/docker/Dockerfile.java --build-arg MODULE_PATH=services/<x>-service -t <image> .
FROM maven:3.9-eclipse-temurin-21 AS build
ARG MODULE_PATH
WORKDIR /workspace
COPY . .
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -q -pl ${MODULE_PATH} -am package -DskipTests

FROM eclipse-temurin:21-jre
ARG MODULE_PATH
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --system --uid 1001 app
WORKDIR /app
COPY --from=build /workspace/${MODULE_PATH}/target/*.jar app.jar
USER app
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/app.jar"]
