# 🐄 zarc-app

**Inteligência Geográfica para o Agronegócio** — Aplicação R Shiny pronta para produção construída com o framework [Rhino](https://appsilon.github.io/rhino/) para explorar dados de produção leiteira em regiões brasileiras.

---

## ✨ Funcionalidades

- **Mapa Interativo** — Visualização coroplética Leaflet da produção leiteira por município
- **Filtros Geográficos em Cascata** — Perfuração Região → Estado → Mesorregião via API do IBGE
- **Integração SIDRA** — Busca dados oficiais de produção leiteira da PPM (Pesquisa Pecuária Municipal) do IBGE
- **Sessões Compartilháveis** — Exporta/importa configurações de filtro como JSON
- **Tema Escuro** — UI profissional estilo AgTech com tema Darkly do bslib

---

## 🏗️ Stack Tecnológica

| Camada          | Tecnologia                        |
|-----------------|-----------------------------------|
| Framework       | [Rhino](https://appsilon.github.io/rhino/) |
| UI              | Shiny + bslib + Leaflet           |
| Importações     | Sistema de módulos {box}          |
| Dependências    | {renv} lockfile                    |
| HTTP Client     | {httr2}                           |
| Espacial        | {sf}                              |
| Estilização     | Sass/SCSS                         |
| CI/CD           | GitHub Actions                    |
| Containerização | Docker (multi-stage)            |

---

## 🚀 Início Rápido

### Pré-requisitos

- R ≥ 4.4.1
- [renv](https://rstudio.github.io/renv/)

### Desenvolvimento Local

```bash
# Clone o repositório
git clone https://github.com/santosangel0/zarc-app.git
cd zarc-app

# Restaure as dependências R
Rscript -e "renv::restore()"

# Execute a aplicação
Rscript -e "shiny::runApp('.', port = 3838)"
```

Abra o navegador em **http://localhost:3838**.

### Docker

```bash
# Construa a imagem
docker build -t zarc-app .

# Execute o contêiner
docker run -p 3838:3838 zarc-app
```

---

## 📁 Estrutura do Projeto

```
zarc-app/
├── app/
│   ├── main.R                 # Ponto de entrada da aplicação
│   ├── logic/
│   │   ├── __init__.R
│   │   ├── ibge.R             # Lógica de negócio da API IBGE + SIDRA
│   │   └── state.R            # Gerenciamento de estado de sessão
│   ├── view/
│   │   ├── __init__.R
│   │   └── geo_sidebar.R      # Módulo de filtro geográfico na barra lateral
│   ├── styles/
│   │   └── main.scss          # Tema SCSS personalizado
│   ├── js/
│   │   └── index.js           # Ponto de entrada JavaScript
│   └── static/                # Recursos estáticos
├── tests/
│   └── testthat/
│       ├── setup.R
│       ├── test-ibge.R
│       └── test-state.R
├── docs/
│   └── architecture.md        # Documentação da arquitetura
├── .github/
│   └── workflows/
│       └── ci.yaml            # Pipeline CI/CD
├── Dockerfile                 # Build multi-estágio do container
├── dependencies.R             # Declaração de pacotes
├── rhino.yml                  # Configuração Rhino
├── renv.lock                  # Lockfile de dependências
└── README.md
```

Veja [docs/architecture.md](docs/architecture.md) para uma explicação detalhada do padrão de separação de módulos.

---

## 🧪 Testes & Qualidade

```bash
# Execute o linter
Rscript -e "rhino::lint_r()"

# Execute os testes unitários
Rscript -e "rhino::test_r()"
```

---

## 📝 Commits Convencionais

Este projeto segue [Conventional Commits](https://www.conventionalcommits.org/). A fase de inicialização foi estruturada como:

```
chore: initialize Rhino project scaffold with renv
feat(logic): add IBGE API integration for GeoJSON and milk production data
feat(logic): add session state management with JSON serialization
feat(view): create geographic sidebar filter module
feat(view): wire up main layout with leaflet choropleth map
chore(docker): add multi-stage Dockerfile for Shiny/Rhino
ci: add GitHub Actions workflow for lint and test
docs: add README and architecture documentation
test: add unit tests for IBGE logic and state management
```

---

## 📄 Licença

Este projeto faz parte da iniciativa de pesquisa ZARC.
