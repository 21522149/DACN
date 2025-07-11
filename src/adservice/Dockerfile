FROM eclipse-temurin:19 AS builder

WORKDIR /app
COPY . .
RUN chmod +x gradlew
RUN ls -la && ./gradlew downloadRepos
RUN ./gradlew installDist

FROM eclipse-temurin:19.0.1_10-jre-alpine

RUN apk add --no-cache ca-certificates

# Download Stackdriver Profiler Java agent
RUN mkdir -p /opt/cprof && \
    wget -q -O- https://storage.googleapis.com/cloud-profiler/java/latest/profiler_java_agent_alpine.tar.gz \
    | tar xzv -C /opt/cprof

WORKDIR /app
COPY --from=builder /app .

EXPOSE 9555
ENTRYPOINT ["/app/build/install/hipstershop/bin/AdService"]
