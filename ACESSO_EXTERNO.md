# 🌐 Acesso Externo - Sistema Mottu

> **Como acessar sua aplicação e banco de dados de qualquer lugar do mundo**

## 🎯 **Visão Geral**

Após fazer o deploy no Azure, sua aplicação fica disponível publicamente na internet. Você pode acessá-la de qualquer lugar usando o endereço fornecido pelo Azure.

## 🚀 **Obter Informações de Acesso**

### **Método 1: Script Automatizado (Mais Fácil)**
```bash
# Execute o deploy
./deploy-containerapp.sh challengemottuacr mottu-rg

# O script mostra automaticamente:
# ✅ Endereço da aplicação
# ✅ Credenciais do banco
# ✅ Todos os endpoints
```

### **Método 2: Comando Manual**
```bash
# Obter endereço da aplicação
az containerapp show --name app --resource-group mottu-rg --query "properties.configuration.ingress.fqdn" -o tsv

# Exemplo de saída: app.xxxxx.eastus.azurecontainerapps.io
```

## 🌐 **Acesso à Aplicação Web**

### **Endereço da Aplicação**
```
https://app.calmbay-db261553.eastus.azurecontainerapps.io
```

### **Endpoints Disponíveis**
| Endpoint | Descrição | Exemplo |
|----------|-----------|---------|
| **Home** | Página inicial | `https://<FQDN>/` |
| **API** | Endpoints da API | `https://<FQDN>/api/` |
| **Login** | Página de login | `https://<FQDN>/login` |

### **Testar Acesso**
```bash
# Teste básico
curl https://app.calmbay-db261553.eastus.azurecontainerapps.io/

# Teste de página inicial
curl https://app.calmbay-db261553.eastus.azurecontainerapps.io/

# Teste de API
curl https://app.calmbay-db261553.eastus.azurecontainerapps.io/api/motos
```

## 🗄️ **Acesso ao Banco de Dados MySQL**

### **Configurações de Conexão**
```
🌐 Host: mysql.internal (interno)
🔌 Porta: 3306
👤 Usuário: mottu
🔑 Senha: FIAP@2tdsp!
🗃️ Database: mottu
```

### **Conectar via Linha de Comando**
```bash
# Conectar ao MySQL (apenas de dentro do Container App)
az containerapp exec --name mysql --resource-group mottu-rg --command "mysql -u mottu -p"

# Digite a senha quando solicitado: FIAP@2tdsp!

# Comandos úteis após conectar
SHOW DATABASES;
USE mottu;
SHOW TABLES;
```

### **Conectar via Ferramentas Gráficas**

#### **🔧 MySQL Workbench**
> **Nota**: O banco MySQL não é acessível externamente no Container Apps por segurança. Use o comando `az containerapp exec` para acessar.

#### **🔧 Azure Data Studio**
1. Abra o Azure Data Studio
2. Use a extensão MySQL
3. Configure via comando `az containerapp exec` para acessar o banco

## 📊 **Monitoramento e Verificação**

### **Status dos Containers**
```bash
# Ver status no Azure
az containerapp list --resource-group mottu-rg --query "[].{name:name,provisioningState:properties.provisioningState,state:properties.runningStatus}"

# Ver logs da aplicação
az containerapp logs show --name app --resource-group mottu-rg

# Ver logs do MySQL
az containerapp logs show --name mysql --resource-group mottu-rg
```

### **Testar Conectividade**
```bash
# Testar aplicação
curl -I https://app.calmbay-db261553.eastus.azurecontainerapps.io/

# Testar MySQL (apenas interno)
az containerapp exec --name mysql --resource-group mottu-rg --command "mysqladmin ping"
```

