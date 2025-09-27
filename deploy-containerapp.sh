#!/bin/bash

# 🚀 Script de Deploy com Azure Container Apps - Sistema Mottu
# Uso: ./deploy-containerapp.sh <ACR_NAME> <RESOURCE_GROUP>

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_message() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Verificar parâmetros
if [ $# -ne 2 ]; then
    print_error "Uso: $0 <ACR_NAME> <RESOURCE_GROUP>"
    echo "Exemplo: $0 challengemottuacr mottu-rg"
    exit 1
fi

ACR_NAME=$1
RESOURCE_GROUP=$2
APP_NAME="app"
MYSQL_NAME="mysql"
LOCATION="eastus"
ENVIRONMENT_NAME="mottu-environment"

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
echo ""

# 1. Verificar pré-requisitos
print_info "Verificando pré-requisitos..."

# Verificar Azure CLI
if ! command -v az &> /dev/null; then
    print_error "Azure CLI não encontrado. Instale: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Verificar Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker não encontrado. Instale: https://docs.docker.com/get-docker/"
    exit 1
fi

# Verificar extensão containerapp
if ! az extension show --name containerapp &> /dev/null; then
    print_info "Instalando extensão containerapp..."
    az extension add --name containerapp
fi

print_message "Pré-requisitos verificados"

# 2. Fazer login no Azure
print_info "Fazendo login no Azure..."
if ! az account show &> /dev/null; then
    az login
fi
print_message "Login no Azure realizado"

# 3. Criar Resource Group
print_info "Criando Resource Group..."
if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
    az group create --name $RESOURCE_GROUP --location $LOCATION
    print_message "Resource Group '$RESOURCE_GROUP' criado"
else
    print_warning "Resource Group '$RESOURCE_GROUP' já existe"
fi

# 4. Criar Azure Container Registry
print_info "Criando Azure Container Registry..."
if ! az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true
    print_message "ACR '$ACR_NAME' criado"
else
    print_warning "ACR '$ACR_NAME' já existe"
fi

# 5. Fazer login no ACR
print_info "Fazendo login no ACR..."
az acr login --name $ACR_NAME
print_message "Login no ACR realizado"

# 6. Build da imagem da aplicação
print_info "Fazendo build da imagem da aplicação..."
docker build -t $ACR_NAME.azurecr.io/$APP_NAME:latest .
print_message "Build da aplicação concluído"

# 7. Push da imagem da aplicação
print_info "Fazendo push da imagem da aplicação..."
docker push $ACR_NAME.azurecr.io/$APP_NAME:latest
print_message "Push da aplicação concluído"

# 8. Build e push da imagem do MySQL
print_info "Fazendo build da imagem do MySQL..."
docker pull mysql:8.0
docker tag mysql:8.0 $ACR_NAME.azurecr.io/$MYSQL_NAME:latest
docker push $ACR_NAME.azurecr.io/$MYSQL_NAME:latest
print_message "Build e push do MySQL concluído"

# 9. Criar Container App Environment
print_info "Criando Container App Environment..."
if ! az containerapp env show --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    az containerapp env create --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION
    print_message "Container App Environment '$ENVIRONMENT_NAME' criado"
else
    print_warning "Container App Environment '$ENVIRONMENT_NAME' já existe"
fi

# 10. Obter credenciais do ACR
print_info "Obtendo credenciais do ACR..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "passwords[0].value" -o tsv)

# 11. Deploy usando Container Apps Compose
print_info "Fazendo deploy com Azure Container Apps..."
if az containerapp show --name app --resource-group $RESOURCE_GROUP &> /dev/null; then
    print_warning "Container App 'app' já existe. Removendo..."
    az containerapp delete --name app --resource-group $RESOURCE_GROUP --yes
fi

# Deploy usando docker-compose.yml
az containerapp compose create \
    --environment $ENVIRONMENT_NAME \
    --resource-group $RESOURCE_GROUP \
    --compose-file-path docker-compose.yml \
    --registry-server $ACR_NAME.azurecr.io \
    --registry-username $ACR_USERNAME \
    --registry-password $ACR_PASSWORD

print_message "Deploy com Container Apps concluído"

# 12. Aguardar containers iniciarem
print_info "Aguardando containers iniciarem..."
sleep 30

# 13. Obter informações do deploy
print_info "Obtendo informações do deploy..."
APP_URL=$(az containerapp show --name app --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)

# 14. Verificar status dos containers
print_info "Verificando status dos containers..."
STATUS=$(az containerapp list --resource-group $RESOURCE_GROUP --query "[].{name:name,provisioningState:properties.provisioningState,state:properties.runningStatus}" -o table)
echo "$STATUS"

# 15. Mostrar informações de acesso
echo -e "${GREEN}"
echo "🎉 ================================================"
echo "   DEPLOY CONCLUÍDO COM SUCESSO!"
echo "=================================================="
echo -e "${NC}"

echo -e "${BLUE}🌐 INFORMAÇÕES DE ACESSO:${NC}"
echo "================================"
echo "Aplicação Web: https://$APP_URL"
echo "Environment: $ENVIRONMENT_NAME"
echo ""

echo -e "${BLUE}🔐 CREDENCIAIS DO BANCO:${NC}"
echo "================================"
echo "Host: mysql.internal"
echo "Port: 3306"
echo "Username: mottu"
echo "Password: FIAP@2tdsp!"
echo "Database: mottu"
echo ""

echo -e "${BLUE}📱 ENDPOINTS DA APLICAÇÃO:${NC}"
echo "================================"
echo "Home: https://$APP_URL/"
echo "API: https://$APP_URL/api/"
echo "Login: https://$APP_URL/login"
echo ""

# 16. Testar aplicação
print_info "Testando aplicação..."
if curl -s -f https://$APP_URL/ > /dev/null; then
    print_message "Aplicação está funcionando!"
else
    print_warning "Aplicação ainda não está respondendo. Aguarde alguns minutos."
fi


echo -e "${GREEN}✨ Deploy concluído! Sua aplicação está disponível em: https://$APP_URL${NC}"
