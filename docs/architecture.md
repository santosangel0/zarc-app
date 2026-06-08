# Arquitetura — zarc-app

## Visão Geral

O **zarc-app** segue a arquitetura [Rhino](https://appsilon.github.io/rhino/), que impõe uma separação estrita entre **lógica de negócio** e código de **UI/visualização**. Este padrão melhora a testabilidade, manutenibilidade e permite reuso futuro de módulos em diferentes interfaces.

---

## Separação de Módulos

```mermaid
graph LR
    subgraph "app/logic/ (Pure R)"
        IBGE["ibge.R<br/>API IBGE & SIDRA"]
        STATE["state.R<br/>Estado da Sessão"]
    end

    subgraph "app/view/ (Shiny Modules)"
        GEO["geo_sidebar.R<br/>Controles de Filtro"]
    end

    subgraph "app/"
        MAIN["main.R<br/>Ponto de Entrada + Mapa Leaflet"]
    end

    GEO -->|"box::use()"| IBGE
    MAIN -->|"box::use()"| GEO
    MAIN -->|"box::use()"| IBGE
    MAIN -->|"box::use()"| STATE
    GEO -->|reads/writes| STATE
```

---

## Camadas

### `app/logic/` — Lógica de Negócio

Arquivos neste diretório contêm **funções R puras** sem reatividade Shiny. Elas podem ser:

- Testadas independentemente (sem sessão Shiny na maioria dos testes)
- Reutilizadas em scripts, APIs ou outras aplicações
- Mockadas facilmente em testes de integração

| Arquivo     | Responsabilidade                                                  |
|-------------|------------------------------------------------------------------|
| `ibge.R`    | Chamadas HTTP para API Localidades do IBGE (regiões, estados, mesorregiões) e API SIDRA (Tabela 74 — produção leiteira) |
| `state.R`   | Gerencia objeto de estado `reactiveValues` da sessão; serialização JSON para "pesquisa compartilhável" |

### `app/view/` — Módulos Shiny

Arquivos aqui definem **módulos Shiny** (pares UI + Server) que lidam com interação do usuário e reatividade.

| Arquivo           | Responsabilidade                                |
|-------------------|------------------------------------------------|
| `geo_sidebar.R`   | Dropdowns de filtro em cascata (Região → Estado → Mesorregião → Ano) com botão "Aplicar" e exportação de sessão |

### `app/main.R` — Ponto de Entrada

Módulo de nível superior que:

1. Define o layout da página (sidebar + mapa)
2. Inicializa o estado da sessão (`state$create_state()`)
3. Conecta módulos filhos
4. Renderiza o mapa coroplético Leaflet reativamente com base nas mudanças de estado

---

## Sistema de Importação

Todas as importações usam o sistema de módulos `{box}`:

```r
# Importa funções de lógica
box::use(app/logic/ibge[get_regions, get_states])

# Importa um módulo de visualização
box::use(app/view/geo_sidebar)
```

Isso garante:
- **Dependências explícitas** — sem chamadas `library()` ocultas
- **Namespacing** — evita colisões de nomes de funções
- **Rastreabilidade** — cada importação é auditável

---

## Gerenciamento de Estado

O estado da sessão (`app/logic/state.R`) atua como **fonte única da verdade**:

```
Interação do Usuário → geo_sidebar (atualiza estado) → main.R (observa estado → renderiza mapa)
```

O estado é serializável para JSON, permitindo:
- **Pesquisa reproduzível** — compartilhe configurações exatas de filtro
- **Persistência de sessão** — restaure sessões de análise anteriores
- **Trilha de auditoria** — registre caminhos de exploração do pesquisador

---

## Fluxo de Dados

```mermaid
sequenceDiagram
    participant U as User
    participant S as geo_sidebar
    participant ST as Session State
    participant M as main.R
    participant API as IBGE/SIDRA API

    U->>S: Selects Region / State / Year
    S->>API: get_states(region)
    API-->>S: State list
    S->>U: Updates State dropdown
    U->>S: Clicks "Apply Filters"
    S->>ST: Updates state values
    ST-->>M: Reactive observation
    M->>API: fetch_subdivisions(code)
    API-->>M: GeoJSON polygons
    M->>API: fetch_milk_production(code, year)
    API-->>M: Production data
    M->>M: Merge + Choropleth render
    M->>U: Updated Leaflet map
```
