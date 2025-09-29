# ☁️ Deploy no Azure - Sistema Mottu

> **Guia completo para fazer deploy da aplicação de rastreamento de motos no Azure**

## 🎯 **Visão Geral**

Este guia mostra como fazer deploy da aplicação Mottu no Azure usando:
- **Azure Container Apps** - Para executar os containers (solução moderna e robusta)
- **Azure Container Registry (ACR)** - Para armazenar as imagens
- **Azure Container App Environment** - Para gerenciar o ambiente

## 🚀 **Início Rápido**

### **Método 1: Script Automatizado (Recomendado)**
```bash
# Deploy completo em 1 comando
./deploy-containerapp.sh

# O script faz tudo automaticamente:
# ✅ Cria recursos no Azure
# ✅ Build e push das imagens
# ✅ Deploy com Container Apps
# ✅ Mostra informações de acesso
```

### **Método 2: Manual (Para aprendizado)**
Siga os passos detalhados abaixo.

## 📋 **Pré-requisitos**

### **Ferramentas Necessárias**
- ✅ **Azure CLI** - [Instalar](https://docs.microsoft.com/cli/azure/install-azure-cli)
- ✅ **Docker** - [Instalar](https://docs.docker.com/get-docker/)
- ✅ **Conta do Azure** - [Criar conta gratuita](https://azure.microsoft.com/free/)

### **Verificar Instalação**
```bash
# Verificar Azure CLI
az --version

# Verificar Docker
docker --version

# Fazer login no Azure
az login
```

## 🏗️ **Passo 1: Criar Recursos no Azure**

### **1.1 Criar Resource Group**
```bash
# Criar grupo de recursos
az group create --name mottu-rg --location westus2

# Verificar criação
az group show --name mottu-rg
```

### **1.2 Criar Azure Container Registry (ACR)**
```bash
# Criar ACR
az acr create --resource-group mottu-rg --name challengemottuacr --sku Basic --admin-enabled true

# Obter credenciais
az acr credential show --name challengemottuacr --resource-group mottu-rg

# Fazer login no ACR
az acr login --name challengemottuacr
```

### **1.3 Criar Azure Database for MySQL (Opcional)**
```bash
# Para produção, use banco gerenciado
az mysql flexible-server create \
  --resource-group mottu-rg \
  --name mottumysqlsrv \
        --location westus2 \
  --admin-user mottuadmin \
  --admin-password FIAP@2tdsp! \
  --sku-name Standard_B1ms \
  --tier Burstable

# Criar banco de dados
az mysql flexible-server db create \
  --resource-group mottu-rg \
  --server-name mottumysqlsrv \
  --database-name mottu
```

## 🐳 **Passo 2: Build e Push das Imagens**

### **2.1 Build da Aplicação**
```bash
# Build da imagem
docker build -t challengemottuacr.azurecr.io/app:latest .

# Push para ACR
docker push challengemottuacr.azurecr.io/app:latest
```

### **2.2 MySQL (Azure Database for MySQL Flexible Server)**
```bash
# O MySQL é gerenciado pelo Azure Database for MySQL Flexible Server
# Não é necessário build/push de imagem MySQL
# A aplicação se conecta diretamente ao servidor gerenciado
```

## 🚀 **Passo 3: Deploy no Azure**

### **3.1 Deploy usando Azure Container Apps (Recomendado)**
```bash
# Deploy usando script automatizado (método atual)
./deploy-containerapp.sh

# O script faz automaticamente:
# ✅ Cria Azure Database for MySQL Flexible Server
# ✅ Build e push da imagem
# ✅ Deploy no Azure Container Apps
# ✅ Configura variáveis de ambiente
```

### **3.2 Deploy Manual (Para aprendizado)**
```bash
# 1. Criar Container App Environment
az containerapp env create --name mottu-environment --resource-group mottu-rg --location westus2

# 2. Deploy da aplicação
az containerapp up \
    --name app \
    --resource-group mottu-rg \
    --environment mottu-environment \
    --image challengemottuacr.azurecr.io/app:latest \
    --target-port 8080 \
    --ingress external \
    --registry-server challengemottuacr.azurecr.io \
    --registry-username challengemottuacr \
    --registry-password <ACR_PASSWORD> \
    --env-vars SPRING_PROFILES_ACTIVE=docker \
               SPRING_DATASOURCE_URL="jdbc:mysql://mottumysqlsrv.mysql.database.azure.com:3306/mottu?useSSL=true&requireSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" \
               SPRING_DATASOURCE_USERNAME="mottuadmin" \
               SPRING_DATASOURCE_PASSWORD="FIAP@2tdsp!"
```

## 📊 **Passo 4: Verificar Deploy**

### **4.1 Obter Informações de Acesso**
```bash
# Obter endereço da aplicação
az containerapp show --name app --resource-group mottu-rg --query "properties.configuration.ingress.fqdn" -o tsv

# Ver status dos containers
az containerapp list --resource-group mottu-rg --query "[].{name:name,provisioningState:properties.provisioningState,state:properties.runningStatus}"
```

### **4.2 Testar Aplicação**
```bash
# Obter URL da aplicação
APP_URL=$(az containerapp show --name app --resource-group mottu-rg --query "properties.configuration.ingress.fqdn" -o tsv)

# Testar aplicação
curl https://$APP_URL/

# Testar página inicial
curl https://$APP_URL/
```

## 🔐 **Passo 5: Configurações de Segurança**

### **5.1 Azure Key Vault (Produção)**
```bash
# Criar Key Vault
az keyvault create --name mottu-keyvault --resource-group mottu-rg --location westus2

# Adicionar secrets
az keyvault secret set --vault-name mottu-keyvault --name "mysql-password" --value "FIAP@2tdsp!"
az keyvault secret set --vault-name mottu-keyvault --name "mysql-username" --value "mottu"
```

### **5.2 Managed Identity**
```bash
# Criar Managed Identity
az identity create --name mottu-identity --resource-group mottu-rg

# Atribuir permissões
az keyvault set-policy --name mottu-keyvault --object-id <MANAGED_IDENTITY_ID> --secret-permissions get list
```

## 📈 **Passo 6: Monitoramento**

### **6.1 Logs**
```bash
# Logs da aplicação
az containerapp logs show --name app --resource-group mottu-rg

# Logs do MySQL (Azure Database for MySQL Flexible Server)
az mysql flexible-server logs list --resource-group mottu-rg --server-name mottumysqlsrv
```

### **6.2 Métricas**
- Use **Azure Monitor** para métricas de performance
- Configure **alertas** para CPU, memória e disponibilidade
- Use **Application Insights** para monitoramento da aplicação

## 🔄 **Passo 7: Escalabilidade**

### **7.1 Auto-scaling**
```bash
# Configurar auto-scaling para Container Apps
az containerapp update \
  --name app \
  --resource-group mottu-rg \
  --min-replicas 1 \
  --max-replicas 5

# Ou configurar via Azure Portal para regras mais complexas
```


