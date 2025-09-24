# Multi-stage build para otimizar o tamanho da imagem
FROM maven:3.9.4-eclipse-temurin AS build

# Definir diretório de trabalho
WORKDIR /app

# Copiar arquivos de configuração do Maven
COPY pom.xml .
COPY mvnw .
COPY mvnw.cmd .
COPY .mvn .mvn

# Copiar código fonte
COPY src ./src

# Build da aplicação
RUN mvn clean package -DskipTests

# Imagem final
FROM eclipse-temurin:17-jre

# Instalar dependências necessárias
RUN apt-get update && \
    apt-get install -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Criar usuário não-root para segurança
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Definir diretório de trabalho
WORKDIR /app

# Copiar o JAR da aplicação
COPY --from=build /app/target/rastreamento-*.jar app.jar

# Alterar propriedade dos arquivos
RUN chown -R appuser:appuser /app

# Mudar para usuário não-root
USER appuser

# Expor porta
EXPOSE 8080


# Comando para executar a aplicação
ENTRYPOINT ["java", "-jar", "app.jar"]
