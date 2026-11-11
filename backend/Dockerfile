# Imagem da API do NORTE para hospedagem (Render, Fly.io, etc.).
# Os testes rodam no CI do GitHub; aqui só compilamos para o deploy ser rápido.

FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app
RUN useradd --system --create-home norte
COPY --from=build /app/target/*.jar app.jar
USER norte

# Planos gratuitos costumam ter ~512 MB de RAM: limita o heap e usa o coletor mais leve.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=70 -XX:+UseSerialGC -Xss512k"

EXPOSE 8080
# A hospedagem informa a porta pela variável PORT; localmente cai em 8080.
ENTRYPOINT ["sh", "-c", "exec java -Dserver.port=${PORT:-8080} -jar app.jar"]
