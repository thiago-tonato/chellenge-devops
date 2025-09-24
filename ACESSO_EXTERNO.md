# 🌐 Acesso Externo - Sistema Mottu

> **Como acessar sua aplicação e banco de dados de qualquer lugar do mundo**

## 🎯 **Visão Geral**

Após fazer o deploy no Azure, sua aplicação fica disponível publicamente na internet. Você pode acessá-la de qualquer lugar usando o endereço fornecido pelo Azure.

## 🚀 **Obter Informações de Acesso**

### **Método 1: Script Automatizado (Mais Fácil)**
```bash
# Execute o deploy
./deploy-azure.sh challengemottuacr mottu-rg

# O script mostra automaticamente:
# ✅ Endereço da aplicação
# ✅ Credenciais do banco
# ✅ Todos os endpoints
```

### **Método 2: Comando Manual**
```bash
# Obter endereço da aplicação
az container show --resource-group mottu-rg --name mottu-compose --query "ipAddress.fqdn" -o tsv

# Exemplo de saída: mottu-compose.eastus.azurecontainer.io
```

## 🌐 **Acesso à Aplicação Web**

### **Endereço da Aplicação**
```
http://mottu-compose.eastus.azurecontainer.io:8080
```

### **Endpoints Disponíveis**
| Endpoint | Descrição | Exemplo |
|----------|-----------|---------|
| **Home** | Página inicial | `http://<FQDN>:8080/` |
| **API** | Endpoints da API | `http://<FQDN>:8080/api/` |
| **Login** | Página de login | `http://<FQDN>:8080/login` |

### **Testar Acesso**
```bash
# Teste básico
curl http://mottu-compose.eastus.azurecontainer.io:8080/

# Teste de página inicial
curl http://mottu-compose.eastus.azurecontainer.io:8080/

# Teste de API
curl http://mottu-compose.eastus.azurecontainer.io:8080/api/motos
```

## 🗄️ **Acesso ao Banco de Dados MySQL**

### **Configurações de Conexão**
```
🌐 Host: mottu-compose.eastus.azurecontainer.io
🔌 Porta: 3306
👤 Usuário: mottu
🔑 Senha: FIAP@2tdsp!
🗃️ Database: mottu
```

### **Conectar via Linha de Comando**
```bash
# Conectar ao MySQL
mysql -h mottu-compose.eastus.azurecontainer.io -P 3306 -u mottu -p

# Digite a senha quando solicitado: FIAP@2tdsp!

# Comandos úteis após conectar
SHOW DATABASES;
USE mottu;
SHOW TABLES;
```

### **Conectar via Ferramentas Gráficas**

#### **🔧 MySQL Workbench**
1. Abra o MySQL Workbench
2. Clique em **"New Connection"**
3. Configure:
   - **Connection Name**: `Mottu Azure`
   - **Hostname**: `mottu-compose.eastus.azurecontainer.io`
   - **Port**: `3306`
   - **Username**: `mottu`
   - **Password**: `FIAP@2tdsp!`
   - **Default Schema**: `mottu`
4. Clique em **"Test Connection"** e depois **"OK"**

## 📊 **Monitoramento e Verificação**

### **Status dos Containers**
```bash
# Ver status no Azure
az container show --resource-group mottu-rg --name mottu-compose --query "containers[].{name:name,state:instanceView.currentState.state}"

# Ver logs da aplicação
az container logs --resource-group mottu-rg --name mottu-compose --container-name mottu-app

# Ver logs do MySQL
az container logs --resource-group mottu-rg --name mottu-compose --container-name mottu-mysql
```

### **Testar Conectividade**
```bash
# Testar aplicação
curl -I http://mottu-compose.eastus.azurecontainer.io:8080/

# Testar MySQL
telnet mottu-compose.eastus.azurecontainer.io 3306

# Verificar portas abertas
nmap -p 8080,3306 mottu-compose.eastus.azurecontainer.io
```

## 🔐 **Segurança**

### **⚠️ Considerações Importantes**
- 🔓 **Portas abertas**: 8080 e 3306 estão acessíveis publicamente
- 🌐 **Sem HTTPS**: Use HTTP apenas para desenvolvimento
- 🔑 **Senhas**: Configure senhas seguras para produção

### **🛡️ Para Produção**
```bash
# 1. Usar Azure Database for MySQL (recomendado)
az mysql flexible-server create \
  --resource-group mottu-rg \
  --name mottu-mysql-server \
  --location eastus \
  --admin-user mottuadmin \
  --admin-password FIAP@2tdsp! \
  --sku-name Standard_B1ms \
  --tier Burstable

# 2. Configurar Network Security Groups
# 3. Usar Azure Key Vault para senhas
# 4. Configurar HTTPS com Application Gateway
```

## 🆘 **Solução de Problemas**

### **❌ Não consegue acessar a aplicação**
```bash
# 1. Verificar se está rodando
az container show --resource-group mottu-rg --name mottu-compose

# 2. Ver logs de erro
az container logs --resource-group mottu-rg --name mottu-compose --container-name mottu-app

# 3. Verificar portas
nmap -p 8080 mottu-compose.eastus.azurecontainer.io
```

### **❌ Não consegue conectar no MySQL**
```bash
# 1. Verificar status do MySQL
az container logs --resource-group mottu-rg --name mottu-compose --container-name mottu-mysql

# 2. Testar conectividade
telnet mottu-compose.eastus.azurecontainer.io 3306

# 3. Verificar credenciais
mysql -h mottu-compose.eastus.azurecontainer.io -P 3306 -u mottu -p
```

### **❌ Aplicação não inicia**
```bash
# 1. Ver logs completos
az container logs --resource-group mottu-rg --name mottu-compose --container-name mottu-app

# 2. Verificar variáveis de ambiente
az container show --resource-group mottu-rg --name mottu-compose --query "containers[0].environmentVariables"

# 3. Reiniciar container
az container restart --resource-group mottu-rg --name mottu-compose
```

## 📱 **Exemplos Práticos**

### **Acessar via Navegador**
1. Abra seu navegador
2. Digite: `http://mottu-compose.eastus.azurecontainer.io:8080`
3. Você deve ver a página inicial da aplicação

### **Conectar via MySQL Client**
```bash
# Windows (PowerShell)
mysql -h mottu-compose.eastus.azurecontainer.io -P 3306 -u mottu -p

# Linux/Mac
mysql -h mottu-compose.eastus.azurecontainer.io -P 3306 -u mottu -p

# Digite a senha: FIAP@2tdsp!
```

### **Testar API via cURL**
```bash
# Listar motos
curl http://mottu-compose.eastus.azurecontainer.io:8080/api/motos

# Teste básico
curl http://mottu-compose.eastus.azurecontainer.io:8080/
```
