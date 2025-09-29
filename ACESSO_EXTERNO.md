# 🌐 Acesso Externo - Sistema Mottu

> **Como acessar sua aplicação e banco de dados de qualquer lugar do mundo**

## 🎯 **Visão Geral**

Após fazer o deploy no Azure, sua aplicação fica disponível publicamente na internet. Você pode acessá-la de qualquer lugar usando o endereço fornecido pelo Azure.

## 🚀 **Obter Informações de Acesso**

### **Método 1: Script Automatizado (Mais Fácil)**
```bash
# Execute o deploy
./deploy-containerapp.sh

# O script mostra automaticamente:
# ✅ Endereço da aplicação
# ✅ Credenciais do banco
# ✅ Todos os endpoints
```

### **Método 2: Comando Manual**
```bash
# Obter endereço da aplicação
az containerapp show --name app --resource-group mottu-rg --query "properties.configuration.ingress.fqdn" -o tsv

# Exemplo de saída: app.xxxxx.westus2.azurecontainerapps.io
```

## 🌐 **Acesso à Aplicação Web**

### **Endereço da Aplicação**
```
https://app.xxxxx.westus2.azurecontainerapps.io
```

### **Endpoints Disponíveis**
| Endpoint | Descrição | Exemplo |
|----------|-----------|---------|
| **Home** | Página inicial | `https://<FQDN>/` |
| **API** | Endpoints da API | `https://<FQDN>/api/` |
| **Login** | Página de login | `https://<FQDN>/login` |

### **Testar Acesso**
```bash
# Obter URL da aplicação
APP_URL=$(az containerapp show --name app --resource-group mottu-rg --query "properties.configuration.ingress.fqdn" -o tsv)

# Teste básico
curl https://$APP_URL/

# Teste de página inicial
curl https://$APP_URL/

# Teste de API
curl https://$APP_URL/api/motos
```

## 🗄️ **Acesso ao Banco de Dados MySQL**

### **Configurações de Conexão**
```
🌐 Host: mottumysqlsrv.mysql.database.azure.com
🔌 Porta: 3306
👤 Usuário: mottuadmin
🔑 Senha: FIAP@2tdsp!
🗃️ Database: mottu
```

### **Conectar via Linha de Comando**
```bash
# Conectar ao Azure Database for MySQL Flexible Server
mysql -h mottumysqlsrv.mysql.database.azure.com -u mottuadmin -p

# Digite a senha quando solicitado: FIAP@2tdsp!

# Comandos úteis após conectar
SHOW DATABASES;
USE mottu;
SHOW TABLES;
```

### **Conectar via Ferramentas Gráficas**

#### **🔧 MySQL Workbench**
1. Abra o MySQL Workbench
2. Configure nova conexão:
   - Host: `mottumysqlsrv.mysql.database.azure.com`
   - Port: `3306`
   - Username: `mottuadmin`
   - Password: `FIAP@2tdsp!`
   - Database: `mottu`

#### **🔧 Azure Data Studio**
1. Abra o Azure Data Studio
2. Use a extensão MySQL
3. Configure a conexão com as credenciais acima

## 📊 **Monitoramento e Verificação**

### **Status dos Containers**
```bash
# Ver status no Azure
az containerapp list --resource-group mottu-rg --query "[].{name:name,provisioningState:properties.provisioningState,state:properties.runningStatus}"

# Ver logs da aplicação
az containerapp logs show --name app --resource-group mottu-rg

# Ver logs do MySQL (Azure Database for MySQL Flexible Server)
az mysql flexible-server logs list --resource-group mottu-rg --server-name mottumysqlsrv
```

### **Testar Conectividade**
```bash
# Obter URL da aplicação
APP_URL=$(az containerapp show --name app --resource-group mottu-rg --query "properties.configuration.ingress.fqdn" -o tsv)

# Testar aplicação
curl -I https://$APP_URL/

# Testar MySQL (Azure Database for MySQL Flexible Server)
mysqladmin ping -h mottumysqlsrv.mysql.database.azure.com -u mottuadmin -p
```

