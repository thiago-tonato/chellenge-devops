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
./deploy-azure.sh mottuacr mottu-rg

# O script faz tudo automaticamente:
# ✅ Build da imagem
# ✅ Push para ACR
# ✅ Deploy no Azure
# ✅ Mostra informações de acesso
```

### **Método 2: Manual**
```bash
# 1. Build e push
docker build -t mottuacr.azurecr.io/mottu-app:latest .
docker push mottuacr.azurecr.io/mottu-app:latest

# 2. Deploy
az aci compose create --resource-group mottu-rg --name mottu-compose --file docker-compose.yml
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

# Verificar MySQL
docker-compose exec mysql mysqladmin ping -h localhost -u root -p
```

## 🆘 **Solução de Problemas**

### **❌ Container não inicia**
```bash
# 1. Ver logs detalhados
docker-compose logs app

# 2. Verificar configurações
docker-compose config

# 3. Rebuild completo
docker-compose down
docker-compose up --build --force-recreate
```

### **❌ Erro de conexão com banco**
```bash
# 1. Verificar se MySQL está rodando
docker-compose ps mysql

# 2. Testar conexão
docker-compose exec mysql mysql -u mottu -p

# 3. Ver logs do MySQL
docker-compose logs mysql
```

### **❌ Porta já em uso**
```bash
# 1. Parar containers existentes
docker-compose down

# 2. Verificar portas em uso
netstat -tulpn | grep :8080
netstat -tulpn | grep :3306

# 3. Matar processo na porta
sudo kill -9 $(lsof -t -i:8080)
```

### **❌ Problemas de permissão**
```bash
# 1. Verificar permissões do Docker
sudo usermod -aG docker $USER

# 2. Reiniciar Docker
sudo systemctl restart docker

# 3. Fazer logout e login novamente
```

## 🎯 **Dicas de Performance**

### **Build Mais Rápido**
```bash
# Usar cache do Docker
docker-compose build --parallel

# Build apenas serviços alterados
docker-compose up --build app
```

### **Otimizar Imagens**
```bash
# Ver tamanho das imagens
docker images

# Limpar cache
docker builder prune
```

## 🔐 **Segurança**

### **Credenciais Seguras**
```bash
# Usar arquivo .env
echo "MYSQL_PASSWORD=MinhaSenhaSegura123!" > .env

# Não commitar senhas
echo ".env" >> .gitignore
```

### **Network Isolation**
```yaml
# No docker-compose.yml
networks:
  mottu-network:
    driver: bridge
    internal: false  # Para acesso externo
```

## 📚 **Recursos Adicionais**

- 📖 **Docker Docs**: https://docs.docker.com/
- 🐳 **Docker Compose**: https://docs.docker.com/compose/
- ☁️ **Azure Container Instances**: https://docs.microsoft.com/azure/container-instances/

---

**💡 Dica**: Use `docker-compose up --build` sempre que fizer alterações no código!
