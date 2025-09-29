#!/bin/bash

# 🚀 Script de Deploy com Azure Container Apps - Sistema Mottu
# Uso: ./deploy-containerapp.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de mensagem
print_message() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Configurações fixas
ACR_NAME="challengemottuacr"
RESOURCE_GROUP="mottu-rg"
APP_NAME="app"
LOCATION="eastus"
ENVIRONMENT_NAME="mottu-environment"

# MySQL fixo
MYSQL_SERVER_NAME="mottumysqlsrv"
MYSQL_ADMIN_USER="mottuadmin"
MYSQL_ADMIN_PASSWORD="FIAP@2tdsp!"
MYSQL_DATABASE="mottu"

echo -e "${BLUE}"
echo "🏍️  ================================================"
echo "   Sistema de Rastreamento de Motos - Mottu"
echo "   Deploy com Azure Container Apps"
echo "=================================================="
echo -e "${NC}"

print_info "Configurações:"
echo "   ACR: $ACR_NAME"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Location: $LOCATION"
echo "   Environment: $ENVIRONMENT_NAME"
echo "   MySQL Server: $MYSQL_SERVER_NAME"
echo ""

# 1. Pré-requisitos
print_info "Verificando pré-requisitos..."
command -v az >/dev/null || { print_error "Azure CLI não encontrado"; exit 1; }
command -v docker >/dev/null || { print_error "Docker não encontrado"; exit 1; }

if ! az extension show --name containerapp &>/dev/null; then
    print_info "Instalando extensão containerapp..."
    az extension add --name containerapp
fi
print_message "Pré-requisitos verificados"

# 2. Login no Azure
print_info "Fazendo login no Azure..."
if ! az account show &>/dev/null; then
    az login
fi
print_message "Login no Azure realizado"

# 3. Resource Group
print_info "Criando Resource Group..."
if ! az group show --name $RESOURCE_GROUP &>/dev/null; then
    az group create --name $RESOURCE_GROUP --location $LOCATION
    print_message "Resource Group '$RESOURCE_GROUP' criado"
else
    print_warning "Resource Group '$RESOURCE_GROUP' já existe"
fi

# 4. ACR
print_info "Criando Azure Container Registry..."
if ! az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true
    print_message "ACR '$ACR_NAME' criado"
else
    print_warning "ACR '$ACR_NAME' já existe"
fi

# 5. Login no ACR
print_info "Fazendo login no ACR..."
az acr login --name $ACR_NAME
print_message "Login no ACR realizado"

# 6. Build da aplicação
print_info "Fazendo build da imagem da aplicação..."
docker build -t $ACR_NAME.azurecr.io/$APP_NAME:latest .
print_message "Build da aplicação concluído"

# 7. Push da aplicação
print_info "Fazendo push da imagem da aplicação..."
docker push $ACR_NAME.azurecr.io/$APP_NAME:latest
print_message "Push da aplicação concluído"

# 8. MySQL (Azure Database for MySQL Flexible Server)
print_info "Criando Azure Database for MySQL Flexible Server..."

if ! az mysql flexible-server show --name $MYSQL_SERVER_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    az mysql flexible-server create \
        --name $MYSQL_SERVER_NAME \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --admin-user $MYSQL_ADMIN_USER \
        --admin-password $MYSQL_ADMIN_PASSWORD \

    print_message "Servidor MySQL '$MYSQL_SERVER_NAME' criado"
else
    print_warning "Servidor MySQL '$MYSQL_SERVER_NAME' já existe"
fi

# Criar banco dentro do servidor
print_info "Criando database '$MYSQL_DATABASE'..."
az mysql flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $MYSQL_SERVER_NAME \
    --database-name $MYSQL_DATABASE
print_message "Database '$MYSQL_DATABASE' criado"

# Esperar MySQL ficar pronto
MYSQL_FQDN=$(az mysql flexible-server show --name $MYSQL_SERVER_NAME --resource-group $RESOURCE_GROUP --query "fullyQualifiedDomainName" -o tsv)
print_info "Aguardando MySQL ficar disponível..."
until mysqladmin ping -h "$MYSQL_FQDN" -u"$MYSQL_ADMIN_USER" -p"$MYSQL_ADMIN_PASSWORD" --silent; do
  print_info "MySQL ainda não está pronto, aguardando 10s..."
  sleep 10
done
print_message "MySQL pronto para conexões"

# 9. Environment
print_info "Criando Container App Environment..."
if ! az containerapp env show --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    az containerapp env create --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION
    print_message "Environment '$ENVIRONMENT_NAME' criado"
else
    print_warning "Environment '$ENVIRONMENT_NAME' já existe"
fi

# 10. Credenciais do ACR
print_info "Obtendo credenciais do ACR..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "passwords[0].value" -o tsv)

# 11. Deploy/Update do App
print_info "Fazendo deploy do App..."

if az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    print_info "Atualizando Container App existente..."
    az containerapp update \
        --name $APP_NAME \
        --resource-group $RESOURCE_GROUP \
        --image $ACR_NAME.azurecr.io/$APP_NAME:latest \
        --set-env-vars SPRING_PROFILES_ACTIVE=docker \
                       SPRING_DATASOURCE_URL="jdbc:mysql://$MYSQL_FQDN:3306/$MYSQL_DATABASE?useSSL=true&requireSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" \
                       SPRING_DATASOURCE_USERNAME="$MYSQL_ADMIN_USER" \
                       SPRING_DATASOURCE_PASSWORD="$MYSQL_ADMIN_PASSWORD" \
                       SPRING_FLYWAY_URL="jdbc:mysql://$MYSQL_FQDN:3306/$MYSQL_DATABASE?useSSL=true&requireSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" \
                       SPRING_FLYWAY_USER="$MYSQL_ADMIN_USER" \
                       SPRING_FLYWAY_PASSWORD="$MYSQL_ADMIN_PASSWORD"
    print_message "Container App atualizado"
else
    print_info "Criando novo Container App..."
    az containerapp up \
        --name $APP_NAME \
        --resource-group $RESOURCE_GROUP \
        --environment $ENVIRONMENT_NAME \
        --image $ACR_NAME.azurecr.io/$APP_NAME:latest \
        --target-port 8080 \
        --ingress external \
        --registry-server $ACR_NAME.azurecr.io \
        --registry-username $ACR_USERNAME \
        --registry-password $ACR_PASSWORD \
        --env-vars SPRING_PROFILES_ACTIVE=docker \
                   SPRING_DATASOURCE_URL="jdbc:mysql://$MYSQL_FQDN:3306/$MYSQL_DATABASE?useSSL=true&requireSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" \
                   SPRING_DATASOURCE_USERNAME="$MYSQL_ADMIN_USER" \
                   SPRING_DATASOURCE_PASSWORD="$MYSQL_ADMIN_PASSWORD" \
                   SPRING_FLYWAY_URL="jdbc:mysql://$MYSQL_FQDN:3306/$MYSQL_DATABASE?useSSL=true&requireSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" \
                   SPRING_FLYWAY_USER="$MYSQL_ADMIN_USER" \
                   SPRING_FLYWAY_PASSWORD="$MYSQL_ADMIN_PASSWORD"
    print_message "Container App criado"
fi

# 12. Aguardar containers
print_info "Aguardando containers iniciarem..."
sleep 30

# 13. Infos do deploy
print_info "Obtendo informações do deploy..."
APP_URL=$(az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)

# 14. Status
print_info "Verificando status dos containers..."
az containerapp list --resource-group $RESOURCE_GROUP --query "[].{name:name,provisioningState:properties.provisioningState,state:properties.runningStatus}" -o table

# 15. Infos finais
echo -e "${GREEN}"
echo "🎉 ================================================"
echo "   DEPLOY CONCLUÍDO COM SUCESSO!"
echo "=================================================="
echo -e "${NC}"

echo -e "${BLUE}🌐 INFORMAÇÕES DE ACESSO:${NC}"
echo "Aplicação Web: https://$APP_URL"
echo "Environment: $ENVIRONMENT_NAME"
echo ""

echo -e "${BLUE}🔐 CREDENCIAIS DO BANCO:${NC}"
echo "Servidor MySQL: $MYSQL_SERVER_NAME.mysql.database.azure.com"
echo "Port: 3306"
echo "Username: $MYSQL_ADMIN_USER"
echo "Password: $MYSQL_ADMIN_PASSWORD"
echo "Database: $MYSQL_DATABASE"
echo ""

echo -e "${BLUE}📱 ENDPOINTS DA APLICAÇÃO:${
