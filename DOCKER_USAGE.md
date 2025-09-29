# 🐳 Guia do Docker - Sistema Mottu

> **Tudo que você precisa saber para usar Docker com a aplicação de rastreamento de motos**

## 🎯 **O que é o Docker?**

O Docker permite executar sua aplicação em **containers isolados**, garantindo que funcione igual em qualquer ambiente (desenvolvimento, teste, produção).

## 📁 **Arquivos Docker**

| Arquivo | Descrição | Quando usar |
|---------|-----------|-------------|
| `Dockerfile` | 📦 Define como construir a imagem da aplicação | Sempre |
| `docker-compose.yml` | 🎭 Orquestra aplicação + MySQL | Desenvolvimento e produção |
| `.dockerignore` | 🚫 Ignora arquivos desnecessários no build | Sempre |

## 🚀 **Início Rápido**

### **1. Executar Localmente (Desenvolvimento)**
```bash
# Iniciar tudo
docker-compose up --build

# Executar em background
docker-compose up -d --build

# Parar tudo
docker-compose down
```

### **2. Acessar a Aplicação**
- 🌐 **Aplicação**: http://localhost:8080
- 🗄️ **MySQL**: localhost:3306

## 🛠️ **Comandos Essenciais**

### **Desenvolvimento Local**
```bash
# Ver logs em tempo real
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f app
docker-compose logs -f mysql

# Executar comando no container
docker-compose exec app bash
docker-compose exec mysql mysql -u mottu -p

# Rebuild apenas a aplicação
docker-compose up --build app

# Ver status dos containers
docker-compose ps
```

### **Limpeza e Manutenção**
```bash
# Parar e remover containers
docker-compose down

# Parar, remover containers e volumes
docker-compose down -v

# Remover imagens não utilizadas
docker system prune -a

# Ver uso de espaço
docker system df
```

## ☁️ **Deploy no Azure**

### **Método 1: Script Automatizado (Recomendado)**
```bash
# Deploy completo
./deploy-containerapp.sh

# O script faz tudo automaticamente:
# ✅ Build da imagem
# ✅ Push para ACR
# ✅ Cria Azure Database for MySQL Flexible Server
# ✅ Deploy no Azure Container Apps
# ✅ Mostra informações de acesso
```

### **Método 2: Manual**
```bash
# 1. Build e push
docker build -t challengemottuacr.azurecr.io/app:latest .
docker push challengemottuacr.azurecr.io/app:latest

# 2. Deploy
./deploy-containerapp.sh
```

## 🔧 **Configurações Avançadas**

### **Variáveis de Ambiente**
```bash
# Definir variáveis personalizadas
export MYSQL_PASSWORD="MinhaSenha123!"
export SPRING_PROFILES_ACTIVE="production"

# Executar com variáveis
docker-compose up --build
```

### **Volumes Personalizados**
```yaml
# No docker-compose.yml
volumes:
  mysql_data:
    driver: local
  app_logs:
    driver: local
```

## 📊 **Monitoramento**

### **Status dos Containers**
```bash
# Ver status detalhado
docker-compose ps

# Ver uso de recursos
docker stats

# Ver logs de erro
docker-compose logs --tail=50 app
```

### **Verificar Status**
```bash
# Verificar se a aplicação está respondendo
curl http://localhost:8080/

# Verificar MySQL (desenvolvimento local)
docker-compose exec mysql mysqladmin ping -h localhost -u root -p

# Verificar Container Apps (produção)
az containerapp list --resource-group mottu-rg
```


