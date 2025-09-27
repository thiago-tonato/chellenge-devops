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
# Deploy completo em 3 comandos
./deploy-containerapp.sh challengemottuacr mottu-rg

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
az group create --name mottu-rg --location eastus

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
  --name mottu-mysql-server \
  --location eastus \
  --admin-user mottuadmin \
  --admin-password FIAP@2tdsp! \
  --sku-name Standard_B1ms \
  --tier Burstable

# Criar banco de dados
az mysql flexible-server db create \
  --resource-group mottu-rg \
  --server-name mottu-mysql-server \
  --database-name mottu
```

## 🐳 **Passo 2: Build e Push das Imagens**

### **2.1 Build da Aplicação**
```bash
# Build da imagem
docker build -t challengemottuacr.azurecr.io/mottu-app:latest .

# Push para ACR
docker push challengemottuacr.azurecr.io/mottu-app:latest
```

### **2.2 Build do MySQL**
```bash
# Usar imagem oficial
docker pull mysql:8.0
docker tag mysql:8.0 challengemottuacr.azurecr.io/mottu-mysql:latest
docker push challengemottuacr.azurecr.io/mottu-mysql:latest
```

## 🚀 **Passo 3: Deploy no Azure**

### **3.1 Deploy usando Azure Container Apps (Recomendado)**
```bash
# Deploy usando Docker Compose (método atual)
az containerapp compose create \
    --environment mottu-environment \
    --resource-group mottu-rg \
    --compose-file-path docker-compose.yml \
    --registry-server challengemottuacr.azurecr.io \
    --registry-username challengemottuacr \
    --registry-password secretref:acr-secret

# Ou usar o script automatizado
./deploy-containerapp.sh challengemottuacr mottu-rg
```

### **3.2 Deploy Manual (Para aprendizado)**
```bash
# 1. Criar Container App Environment
az containerapp env create --name mottu-environment --resource-group mottu-rg --location eastus

# 2. Criar secret para ACR
az containerapp secret set --name acr-secret --resource-group mottu-rg --environment mottu-environment --secrets registry-password=<ACR_PASSWORD>

# 3. Deploy usando compose
az containerapp compose create \
    --environment mottu-environment \
    --resource-group mottu-rg \
    --compose-file-path docker-compose.yml \
    --registry-server challengemottuacr.azurecr.io \
    --registry-username challengemottuacr \
    --registry-password secretref:acr-secret
```

## 📊 **Passo 4: Verificar Deploy**

### **4.1 Obter Informações de Acesso**
```bash
# Obter endereço da aplicação
az container show --resource-group mottu-rg --name mottu-compose --query "ipAddress.fqdn" -o tsv

# Ver status dos containers
az container show --resource-group mottu-rg --name mottu-compose --query "containers[].{name:name,state:instanceView.currentState.state}"
```

### **4.2 Testar Aplicação**
```bash
# Testar aplicação
curl http://mottu-compose.eastus.azurecontainer.io:8080/

# Testar página inicial
curl http://mottu-compose.eastus.azurecontainer.io:8080/
```

## 🔐 **Passo 5: Configurações de Segurança**

### **5.1 Azure Key Vault (Produção)**
```bash
# Criar Key Vault
az keyvault create --name mottu-keyvault --resource-group mottu-rg --location eastus

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
az container logs --resource-group mottu-rg --name mottu-compose --container-name mottu-app

# Logs do MySQL
az container logs --resource-group mottu-rg --name mottu-compose --container-name mottu-mysql
```

### **6.2 Métricas**
- Use **Azure Monitor** para métricas de performance
- Configure **alertas** para CPU, memória e disponibilidade
- Use **Application Insights** para monitoramento da aplicação

## 🔄 **Passo 7: Escalabilidade**

### **7.1 Auto-scaling**
```bash
# Configurar auto-scaling
az monitor autoscale create \
  --resource-group mottu-rg \
  --resource mottu-compose \
  --resource-type Microsoft.ContainerInstance/containerGroups \
  --name mottu-autoscale \
  --min-count 1 \
  --max-count 5 \
  --count 2
```


