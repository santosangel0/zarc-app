# 🐄 zarc-app

**Geographic Intelligence for AgTech** — A production-ready R Shiny application built with the [Rhino](https://appsilon.github.io/rhino/) framework for exploring milk production data across Brazilian regions.

---

## ✨ Features

- **Interactive Map** — Leaflet choropleth visualization of milk production by municipality
- **Cascading Geographic Filters** — Region → State → Mesoregion drill-down powered by the IBGE API
- **SIDRA Integration** — Fetches official IBGE PPM (Pesquisa Pecuária Municipal) milk production data
- **Shareable Sessions** — Export/import researcher filter configurations as JSON
- **Dark Theme** — Professional AgTech-styled UI with bslib Darkly theme

---

## 🏗️ Tech Stack

| Layer          | Technology                        |
|----------------|-----------------------------------|
| Framework      | [Rhino](https://appsilon.github.io/rhino/) |
| UI             | Shiny + bslib + Leaflet           |
| Imports        | {box} module system               |
| Dependencies   | {renv} lockfile                    |
| HTTP Client    | {httr2}                           |
| Spatial        | {sf}                              |
| Styling        | Sass/SCSS                         |
| CI/CD          | GitHub Actions                    |
| Containerization | Docker (multi-stage)            |

---

## 🚀 Quick Start

### Prerequisites

- R ≥ 4.4.1
- [renv](https://rstudio.github.io/renv/)

### Local Development

```bash
# Clone the repository
git clone https://github.com/santosangel0/zarc-app.git
cd zarc-app

# Restore R dependencies
Rscript -e "renv::restore()"

# Run the application
Rscript -e "shiny::runApp('.', port = 3838)"
```

Open your browser at **http://localhost:3838**.

### Docker

```bash
# Build the image
docker build -t zarc-app .

# Run the container
docker run -p 3838:3838 zarc-app
```

---

## 📁 Project Structure

```
zarc-app/
├── app/
│   ├── main.R                 # Application entry point
│   ├── logic/
│   │   ├── __init__.R
│   │   ├── ibge.R             # IBGE API + SIDRA business logic
│   │   └── state.R            # Session state management
│   ├── view/
│   │   ├── __init__.R
│   │   └── geo_sidebar.R      # Geographic filter sidebar module
│   ├── styles/
│   │   └── main.scss          # Custom SCSS theme
│   ├── js/
│   │   └── index.js           # JavaScript entry point
│   └── static/                # Static assets
├── tests/
│   └── testthat/
│       ├── setup.R
│       ├── test-ibge.R
│       └── test-state.R
├── docs/
│   └── architecture.md        # Architecture documentation
├── .github/
│   └── workflows/
│       └── ci.yaml            # CI/CD pipeline
├── Dockerfile                 # Multi-stage container build
├── dependencies.R             # Package declarations
├── rhino.yml                  # Rhino configuration
├── renv.lock                  # Dependency lockfile
└── README.md
```

See [docs/architecture.md](docs/architecture.md) for a detailed explanation of the module separation pattern.

---

## 🧪 Testing & Quality

```bash
# Run linter
Rscript -e "rhino::lint_r()"

# Run unit tests
Rscript -e "rhino::test_r()"
```

---

## 📝 Conventional Commits

This project follows [Conventional Commits](https://www.conventionalcommits.org/). The initialization phase was structured as:

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

## 📄 License

This project is part of the ZARC research initiative.
