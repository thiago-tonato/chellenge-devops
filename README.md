# 🏍️ Sistema de Rastreamento de Motos - Mottu

> **Sistema completo para rastreamento de motos usando tecnologia UWB (Ultra-Wideband)**

## 🚀 **Início Rápido**

### **Opção 1: Executar Localmente (Desenvolvimento)**
```bash
# 1. Clone o repositório
git clone <seu-repositorio>
cd api-rest-mottu

# 2. Execute com Docker
docker-compose up --build

# 3. Acesse a aplicação
# 🌐 http://localhost:8080
# 🗄️ MySQL: localhost:3306
```

### **Opção 2: Deploy no Azure (Produção)**
```bash
# 1. Execute o script de deploy
./deploy-azure.sh challengemottuacr mottu-rg

# 2. Aguarde o deploy (2-3 minutos)
# 3. Acesse usando o endereço fornecido pelo script
```

## 📋 **O que você precisa**

### **Para Desenvolvimento Local:**
- ✅ Docker e Docker Compose
- ✅ Git

### **Para Deploy no Azure:**
- ✅ Azure CLI instalado
- ✅ Conta do Azure
- ✅ Docker e Docker Compose

## 🏗️ **Arquitetura do Sistema**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Database      │
│   (Thymeleaf)   │◄──►│   (Spring Boot) │◄──►│   (MySQL)       │
│   Port: 8080    │    │   Port: 8080    │    │   Port: 3306    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🎯 **Funcionalidades**

- 🏍️ **Gestão de Motos** - Cadastro e controle de motocicletas
- 📍 **Rastreamento UWB** - Localização em tempo real via sensores
- 🔧 **Manutenção** - Controle de manutenções e serviços
- 📊 **Alocações** - Gestão de alocações de motos
- 👥 **Usuários** - Sistema de autenticação e autorização
- 📱 **Interface Web** - Dashboard intuitivo

## 🛠️ **Tecnologias Utilizadas**

| Tecnologia | Versão | Descrição |
|------------|--------|-----------|
| **Java** | 17 | Linguagem principal |
| **Spring Boot** | 3.4.5 | Framework web |
| **MySQL** | 8.0 | Banco de dados |
| **Docker** | Latest | Containerização |
| **Azure ACI** | - | Orquestração na nuvem |
| **Flyway** | 10.22.0 | Migração de banco |

## 📁 **Estrutura do Projeto**

```
api-rest-mottu/
├── 🐳 Dockerfile              # Imagem da aplicação
├── 🐳 docker-compose.yml      # Orquestração local
├── 🚀 deploy-azure.sh         # Deploy no Azure
├── 📚 README.md               # Este arquivo
├── 📖 DOCKER_USAGE.md         # Guia do Docker
├── 🌐 ACESSO_EXTERNO.md       # Acesso remoto
├── ☁️ AZURE_DEPLOY.md         # Deploy no Azure
└── src/
    └── main/
        ├── java/              # Código Java
        ├── resources/         # Configurações
        └── templates/         # Páginas HTML
```

## 🎮 **Como Usar**

### **1. Desenvolvimento Local**
```bash
# Iniciar aplicação
docker-compose up --build

# Ver logs
docker-compose logs -f

# Parar aplicação
docker-compose down
```

### **2. Deploy no Azure**
```bash
# Deploy automático
./deploy-azure.sh challengemottuacr mottu-rg

# Ver status
az container show --resource-group mottu-rg --name mottu-compose
```

## 🔐 **Credenciais Padrão**

### **Banco de Dados:**
- **Host**: `localhost` (local) ou `<FQDN>` (Azure)
- **Porta**: `3306`
- **Usuário**: `mottu`
- **Senha**: `FIAP@2tdsp!`
- **Database**: `mottu`

### **Aplicação:**
- **URL**: `http://localhost:8080` (local) ou `http://<FQDN>:8080` (Azure)
- **Login**: Configure no sistema

## 📱 **Endpoints da API**

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/` | GET | Página inicial |
| `/api/motos` | GET | Listar motos |
| `/api/sensores` | GET | Listar sensores |
| `/api/alocacoes` | GET | Listar alocações |
| `/api/manutencoes` | GET | Listar manutenções |

## 🆘 **Problemas Comuns**

### **❌ Container não inicia**
```bash
# Ver logs
docker-compose logs app

# Verificar portas
netstat -tulpn | grep :8080
```

### **❌ Erro de conexão com banco**
```bash
# Verificar MySQL
docker-compose logs mysql

# Testar conexão
mysql -h localhost -P 3306 -u mottu -p
```

### **❌ Deploy falha no Azure**
```bash
# Ver logs do Azure
az container logs --resource-group mottu-rg --name mottu-compose

# Verificar recursos
az group list
```