# ☁️ Deploy no Azure - Sistema Mottu

> **Guia completo para fazer deploy da aplicação de rastreamento de motos no Azure**

## 🎯 **Visão Geral**

Este guia mostra como fazer deploy da aplicação Mottu no Azure usando:
- **Azure Container Instances (ACI)** - Para executar os containers
- **Azure Container Registry (ACR)** - Para armazenar as imagens
- **Azure Database for MySQL** - Para banco de dados (opcional)

## 🚀 **Início Rápido**

### **Método 1: Script Automatizado (Recomendado)**
```bash
# Deploy completo em 3 comandos
./deploy-azure.sh mottuacr mottu-rg

# O script faz tudo automaticamente:
# ✅ Cria recursos no Azure
# ✅ Build e push das imagens
# ✅ Deploy da aplicação
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
az acr create --resource-group mottu-rg --name mottuacr --sku Basic --admin-enabled true

# Obter credenciais
az acr credential show --name mottuacr --resource-group mottu-rg

# Fazer login no ACR
az acr login --name mottuacr
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
docker build -t mottuacr.azurecr.io/mottu-app:latest .

# Push para ACR
docker push mottuacr.azurecr.io/mottu-app:latest
```

### **2.2 Build do MySQL**
```bash
# Usar imagem oficial
docker pull mysql:8.0
docker tag mysql:8.0 mottuacr.azurecr.io/mottu-mysql:latest
docker push mottuacr.azurecr.io/mottu-mysql:latest
```

## 🚀 **Passo 3: Deploy no Azure**

### **3.1 Deploy usando Docker Compose (Recomendado)**
```bash
# Instalar extensão ACI Compose
az extension add --name aci-compose

# Deploy completo
az aci compose create --resource-group mottu-rg --name mottu-compose --file docker-compose.yml
```

### **3.2 Deploy usando YAML (Alternativo)**
```bash
# Criar arquivo de configuração
cat > aci-deploy.yaml << EOF
apiVersion: 2021-07-01
location: eastus
name: mottu-app
properties:
  containers:
  - name: mottu-app
    properties:
      image: mottuacr.azurecr.io/mottu-app:latest
      resources:
        requests:
          cpu: 1
          memoryInGb: 2
      ports:
      - port: 8080
        protocol: TCP
      environmentVariables:
      - name: SPRING_PROFILES_ACTIVE
        value: docker
      - name: SPRING_DATASOURCE_URL
        value: jdbc:mysql://mottu-mysql:3306/mottu?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
      - name: SPRING_DATASOURCE_USERNAME
        value: mottu
      - name: SPRING_DATASOURCE_PASSWORD
        value: FIAP@2tdsp!
  - name: mottu-mysql
    properties:
      image: mottuacr.azurecr.io/mottu-mysql:latest
      resources:
        requests:
          cpu: 1
          memoryInGb: 2
      ports:
      - port: 3306
        protocol: TCP
      environmentVariables:
      - name: MYSQL_ROOT_PASSWORD
        value: rootpassword
      - name: MYSQL_DATABASE
        value: mottu
      - name: MYSQL_USER
        value: mottu
      - name: MYSQL_PASSWORD
        value: FIAP@2tdsp!
  osType: Linux
  ipAddress:
    type: Public
    ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 3306
    dnsNameLabel: mottu-app
  imageRegistryCredentials:
  - server: mottuacr.azurecr.io
    username: mottuacr
    password: <PASSWORD_DO_ACR>
EOF

# Deploy
az container create --resource-group mottu-rg --file aci-deploy.yaml
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

## 🛠️ **Comandos Úteis**

### **Gerenciamento de Containers**
```bash
# Ver status
az container show --resource-group mottu-rg --name mottu-compose

# Reiniciar
az container restart --resource-group mottu-rg --name mottu-compose

# Deletar
az container delete --resource-group mottu-rg --name mottu-compose --yes
```

### **Gerenciamento de Recursos**
```bash
# Listar recursos
az resource list --resource-group mottu-rg

# Deletar grupo de recursos
az group delete --name mottu-rg --yes --no-wait
```

## 🆘 **Solução de Problemas**

### **❌ Deploy falha**
```bash
# Ver logs de erro
az container logs --resource-group mottu-rg --name mottu-compose

# Verificar configuração
az container show --resource-group mottu-rg --name mottu-compose --query "containers[0].instanceView.events"
```

### **❌ Container não inicia**
```bash
# Ver logs detalhados
az container logs --resource-group mottu-rg --name mottu-compose --container-name mottu-app

# Verificar variáveis de ambiente
az container show --resource-group mottu-rg --name mottu-compose --query "containers[0].environmentVariables"
```

### **❌ Erro de conexão com banco**
```bash
# Verificar status do MySQL
az container logs --resource-group mottu-rg --name mottu-compose --container-name mottu-mysql

# Testar conectividade
telnet mottu-compose.eastus.azurecontainer.io 3306
```

## 💰 **Custos e Limitações**

### **Custos**
- **ACI**: Cobrado por segundo (ideal para cargas variáveis)
- **ACR**: Cobrado por armazenamento e operações
- **MySQL**: Cobrado por hora (se usar Azure Database)

### **Limitações**
- **ACI**: Máximo 4 vCPUs e 16GB RAM por container
- **ACR**: Limite de 10GB para tier Basic
- **Persistência**: Use Azure Files ou Azure Database para dados persistentes

## 🎯 **Próximos Passos**

1. ✅ **Teste o deploy** - Verifique se a aplicação está funcionando
2. ✅ **Configure monitoramento** - Use Azure Monitor e Application Insights
3. ✅ **Implemente segurança** - Use Key Vault e Managed Identity
4. ✅ **Configure backup** - Implemente estratégia de backup
5. ✅ **Otimize custos** - Monitore e otimize recursos

---

**💡 Dica**: Use o script `deploy-azure.sh` para deploy rápido e automatizado!