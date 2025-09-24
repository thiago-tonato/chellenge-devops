#!/bin/bash

# 🚀 Script de Deploy Automatizado - Sistema Mottu
# Uso: ./deploy-azure.sh <ACR_NAME> <RESOURCE_GROUP>

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
APP_NAME="mottu-app"
MYSQL_NAME="mottu-mysql"
LOCATION="eastus"

echo -e "${BLUE}"
echo "🏍️  ================================================"
echo "   Sistema de Rastreamento de Motos - Mottu"
echo "   Deploy Automatizado no Azure"
echo "=================================================="
echo -e "${NC}"

print_info "Configurações:"
echo "   ACR: $ACR_NAME"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Location: $LOCATION"
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

# 9. Instalar extensão ACI Compose
print_info "Instalando extensão ACI Compose..."
az extension add --name aci-compose --yes
print_message "Extensão ACI Compose instalada"

# 10. Deploy no Azure Container Instances
print_info "Fazendo deploy no Azure Container Instances..."
if az container show --resource-group $RESOURCE_GROUP --name mottu-compose &> /dev/null; then
    print_warning "Container group 'mottu-compose' já existe. Removendo..."
    az container delete --resource-group $RESOURCE_GROUP --name mottu-compose --yes
fi

az aci compose create --resource-group $RESOURCE_GROUP --name mottu-compose --file docker-compose.yml
print_message "Deploy no Azure concluído"

# 11. Aguardar containers iniciarem
print_info "Aguardando containers iniciarem..."
sleep 30

# 12. Obter informações do deploy
print_info "Obtendo informações do deploy..."
FQDN=$(az container show --resource-group $RESOURCE_GROUP --name mottu-compose --query "ipAddress.fqdn" -o tsv)
IP_ADDRESS=$(az container show --resource-group $RESOURCE_GROUP --name mottu-compose --query "ipAddress.ip" -o tsv)

# 13. Verificar status dos containers
print_info "Verificando status dos containers..."
STATUS=$(az container show --resource-group $RESOURCE_GROUP --name mottu-compose --query "containers[].{name:name,state:instanceView.currentState.state}" -o table)
echo "$STATUS"

# 14. Mostrar informações de acesso
echo -e "${GREEN}"
echo "🎉 ================================================"
echo "   DEPLOY CONCLUÍDO COM SUCESSO!"
echo "=================================================="
echo -e "${NC}"

echo -e "${BLUE}🌐 INFORMAÇÕES DE ACESSO:${NC}"
echo "================================"
echo "Aplicação Web: http://$FQDN:8080"
echo "MySQL Database: $FQDN:3306"
echo "IP Público: $IP_ADDRESS"
echo ""

echo -e "${BLUE}🔐 CREDENCIAIS DO BANCO:${NC}"
echo "================================"
echo "Host: $FQDN"
echo "Port: 3306"
echo "Username: mottu"
echo "Password: FIAP@2tdsp!"
echo "Database: mottu"
echo ""

echo -e "${BLUE}📱 ENDPOINTS DA APLICAÇÃO:${NC}"
echo "================================"
echo "Home: http://$FQDN:8080/"
echo "API: http://$FQDN:8080/api/"
echo "Login: http://$FQDN:8080/login"
echo ""

# 15. Testar aplicação
print_info "Testando aplicação..."
if curl -s -f http://$FQDN:8080/ > /dev/null; then
    print_message "Aplicação está funcionando!"
else
    print_warning "Aplicação ainda não está respondendo. Aguarde alguns minutos."
fi

# 16. Mostrar comandos úteis
echo -e "${BLUE}📋 COMANDOS ÚTEIS:${NC}"
echo "================================"
echo "Ver logs da aplicação:"
echo "  az container logs --resource-group $RESOURCE_GROUP --name mottu-compose --container-name $APP_NAME"
echo ""
echo "Ver logs do MySQL:"
echo "  az container logs --resource-group $RESOURCE_GROUP --name mottu-compose --container-name $MYSQL_NAME"
echo ""
echo "Reiniciar containers:"
echo "  az container restart --resource-group $RESOURCE_GROUP --name mottu-compose"
echo ""
echo "Deletar recursos:"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""

echo -e "${GREEN}✨ Deploy concluído! Sua aplicação está disponível em: http://$FQDN:8080${NC}"
