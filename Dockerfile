# ============================================================
# STAGE 1 – Build
# ============================================================
FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /app

COPY gradlew .
COPY gradle ./gradle
COPY build.gradle .
COPY settings.gradle .
RUN chmod +x gradlew

# Resolve dependencies (layer cache)
RUN ./gradlew dependencies --no-daemon -q

COPY src ./src
RUN ./gradlew bootJar -x test --no-daemon -q

# ============================================================
# STAGE 2 – Runtime (slim JRE)
# ============================================================
FROM eclipse-temurin:21-jre-jammy AS runtime
WORKDIR /app

RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

COPY --from=build /app/build/libs/*.jar app.jar
RUN chown appuser:appgroup app.jar
USER appuser

EXPOSE 9099

ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
