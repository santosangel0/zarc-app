# 🐄 zarc-app

**Inteligência Geográfica para o Agronegócio** — Aplicação R Shiny pronta para produção construída com o framework [Rhino](https://appsilon.github.io/rhino/) para explorar produção leiteira e dados climáticos em regiões brasileiras.

---

## ✨ Funcionalidades

A aplicação é um **assistente (wizard) de dois passos**:

### Passo 1 — Escopo & Produção Leiteira

- **Filtros Geográficos em Cascata** — Perfuração Região → Estado → Mesorregião/Microrregião → Ano via API de Localidades do IBGE
- **Mapa Interativo** — Visualização coroplética Leaflet da produção leiteira por subdivisão
- **Integração SIDRA** — Produção leiteira oficial da PPM (Pesquisa Pecuária Municipal, Tabela 74) da API Agregados do IBGE
- **Gráficos** — Barras animadas e séries temporais (Plotly)
- **Análise Estatística** — Histograma, estatísticas descritivas e teste de normalidade de Shapiro-Wilk
- **Inspeção de Dados** — Tabela bruta/processada (DT)

### Passo 2 — Dados Climáticos (INMET)

- **Estações Meteorológicas** — Carrega estações automáticas do INMET e filtra espacialmente pela Região de Interesse (com buffer configurável em km)
- **Séries Diárias** — Temperatura, umidade e **ITU** (Índice de Temperatura e Umidade, Buffington 1977) por estação, com Controle de Qualidade aplicado
- **Inspeção de Dados Climáticos** — Tabela com amostrador de linhas (DT)

### Transversal

- **Sessões Compartilháveis** — Exporta/importa configurações de filtro como JSON
- **Tema Escuro** — UI profissional estilo AgTech com tema Darkly do bslib

---

## 🔗 Relação com `zarc-etl`

A lógica de coleta de dados históricos foi extraída para um repositório irmão,
[`zarc-etl`](https://github.com/santosangel0/zarc-etl) — um pipeline batch em
**Python + Polars** que coleta INMET, IBGE e NASA POWER e materializa parquets
estáveis em `data/final/`.

**Estado atual:** o `zarc-app` ainda faz **ingestão ao vivo** das APIs (INMET
`apitempo`, IBGE Localidades/Malhas/Agregados) a cada sessão. A migração para
consumir os parquets do `zarc-etl` é uma **entrega futura** — ver
[contratos de dados](https://github.com/santosangel0/zarc-etl/blob/dev/docs/06-contratos-de-dados.md)
e o [plano de integração](https://github.com/santosangel0/zarc-etl/blob/dev/docs/08-integracao-zarc-app.md)
no repositório do ETL, e a seção "Migração planejada para o zarc-etl" em
[docs/architecture.md](docs/architecture.md).

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
| Gráficos        | {plotly} + {ggplot2} + {DT}       |
| Estilização     | Sass/SCSS                         |
| CI/CD           | GitHub Actions                    |
| Containerização | Docker (multi-stage)            |

---

## 🚀 Início Rápido

### Pré-requisitos

- R ≥ 4.4.1
- [renv](https://rstudio.github.io/renv/)
- `INMET_TOKEN` no ambiente (necessário para as séries diárias do Passo 2 — ver `config.yml`)

### Desenvolvimento Local

```bash
# Clone o repositório
git clone https://github.com/santosangel0/zarc-app.git
cd zarc-app

# Restaure as dependências R
Rscript -e "renv::restore()"

# Defina o token do INMET (Passo 2)
export INMET_TOKEN="seu_token_aqui"

# Execute a aplicação
Rscript -e "shiny::runApp('.', port = 3838)"
```

Abra o navegador em **http://localhost:3838**.

### Docker

```bash
# Construa a imagem
docker build -t zarc-app .

# Execute o contêiner
docker run -p 3838:3838 -e INMET_TOKEN="seu_token_aqui" zarc-app
```

---

## 📁 Estrutura do Projeto

```
zarc-app/
├── app/
│   ├── main.R                    # Orquestrador do wizard (navegação Passo 1 ↔ Passo 2)
│   ├── logic/                    # Lógica de negócio pura (R, sem reatividade)
│   │   ├── ibge.R                # API IBGE (Localidades, Malhas) + SIDRA/Agregados
│   │   ├── inmet.R               # API INMET: estações, filtro espacial, QC, ITU, buffer
│   │   ├── state.R               # Estado de sessão + serialização JSON
│   │   └── stats.R               # Estatística (sumário, Shapiro-Wilk)
│   ├── view/                     # Módulos Shiny (UI + Server)
│   │   ├── step1_scope.R         # Passo 1: escopo geográfico + produção leiteira
│   │   ├── step2_climate.R       # Passo 2: estações INMET + dados climáticos
│   │   ├── geo_sidebar.R         # Filtro geográfico em cascata (4 níveis)
│   │   ├── charts.R              # Gráficos de barras animado e de linhas (Plotly)
│   │   ├── analysis.R            # Histograma + descritivas + teste de normalidade
│   │   ├── data_view.R           # Tabela de dados leiteiros (bruto/processado)
│   │   └── climate_data_view.R   # Tabela de dados climáticos do INMET
│   ├── styles/
│   │   └── main.scss             # Tema SCSS personalizado
│   ├── js/
│   │   └── index.js              # Ponto de entrada JavaScript
│   └── static/                   # Recursos estáticos (logo Embrapa)
├── tests/
│   └── testthat/                 # Testes unitários (ibge, inmet, state, stats)
├── docs/
│   └── architecture.md           # Documentação da arquitetura
├── .github/
│   └── workflows/
│       └── ci.yaml               # Pipeline CI/CD
├── Dockerfile                    # Build multi-estágio do container
├── config.yml                    # Config Rhino + inmet_token
├── dependencies.R                # Declaração de pacotes
├── rhino.yml                     # Configuração Rhino
├── renv.lock                     # Lockfile de dependências
└── README.md
```

Veja [docs/architecture.md](docs/architecture.md) para uma explicação detalhada do padrão de separação de módulos e da relação com o `zarc-etl`.

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

Este projeto segue [Conventional Commits](https://www.conventionalcommits.org/).

---

## 📄 Licença

Este projeto faz parte da iniciativa de pesquisa ZARC.
