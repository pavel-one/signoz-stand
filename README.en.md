**🇬🇧 English** | [🇷🇺 Русский](README.md)

# signoz-stand

A stand for deploying [SigNoz](https://signoz.io/) — an observability platform (traces, metrics, logs) with ClickHouse as a storage backend.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   ClickHouse                        │
│  ┌───────────┐  ┌────────────┐  ┌─────────────────┐ │
│  │ ZooKeeper │→ │ ClickHouse │← │ TelemetryStore  │ │
│  │    :9141  │  │ :9000 :8123│  │    Migrator     │ │
│  └─────┬─────┘  └─────┬──┬───┘  └─────────────────┘ │
│        │metrics       │  │metrics :9363             │
└────────┼──────────────┼──┼──────────────────────────┘
         │              │  │
┌────────┼──────────────┼──┼──────────────────────────┐
│        │         SigNoz  │                          │
│  ┌─────┴──────────────┴──┴───┐  ┌────────────────┐  │
│  │      OTel Collector       │  │  SigNoz (UI +  │  │
│  │  OTLP :4317 / :4318       │  │  API) :8080    │  │
│  │  Prometheus scrape        │  │                │  │
│  │  Health :13133            │  │                │  │
│  └───────────────────────────┘  └────────────────┘  │
└─────────────────────────────────────────────────────┘
```

OTel Collector scrapes Prometheus metrics from ClickHouse (`:9363`) and ZooKeeper (`:9141`).

## Requirements

- [Docker](https://docs.docker.com/get-docker/) ≥ 20.10
- [Docker Compose](https://docs.docker.com/compose/) v2+
- GNU Make

## Quick Start

```bash
# Clone the repository
git clone <repo-url> && cd signoz-stand

# Start the entire stand
make up
```

On the first run, `signoz/.env` will be automatically created from `signoz/.env.example`.

## Environment Variables

File `signoz/.env` (created from `signoz/.env.example`):

| Variable               | Description                                | Default                       |
|------------------------|--------------------------------------------|-------------------------------|
| `CLICKHOUSE_URL`       | ClickHouse address (`host:port`)           | `host.docker.internal:9000`   |
| `SIGNOZ_TOKEN_SECRET`  | JWT token secret                           | `orient-holiday-lazy`         |

Image versions are set via environment variables (or directly in `docker-compose.yml`):

| Variable       | Description               | Default       |
|----------------|---------------------------|---------------|
| `VERSION`      | SigNoz version            | `v0.113.0`    |
| `OTELCOL_TAG`  | OTel Collector version    | `v0.144.1`    |

## Make Commands

```bash
make help                # Show all available commands
```

### Stand Management

| Command                  | Description                           |
|--------------------------|---------------------------------------|
| `make up`                | Start the entire stand                |
| `make down`              | Stop the entire stand                 |
| `make restart`           | Restart the entire stand              |

### ClickHouse

| Command                  | Description                           |
|--------------------------|---------------------------------------|
| `make up-clickhouse`     | Start ClickHouse                      |
| `make down-clickhouse`   | Stop ClickHouse                       |
| `make restart-clickhouse`| Restart ClickHouse                    |
| `make logs-clickhouse`   | ClickHouse logs (follow)              |

### SigNoz

| Command                  | Description                           |
|--------------------------|---------------------------------------|
| `make up-signoz`         | Start SigNoz                          |
| `make down-signoz`       | Stop SigNoz                           |
| `make restart-signoz`    | Restart SigNoz                        |
| `make logs-signoz`       | SigNoz logs (follow)                  |

### Utilities

| Command                  | Description                           |
|--------------------------|---------------------------------------|
| `make ps`                | Status of all containers              |
| `make logs`              | Logs of all services (follow)         |
| `make env`               | Create `.env` from `.env.example`     |

## Ports

| Service             | Port    | Description                       |
|---------------------|---------|-----------------------------------|
| SigNoz UI / API     | `8080`  | Web interface and API             |
| OTel gRPC           | `4317`  | OTLP gRPC receiver               |
| OTel HTTP           | `4318`  | OTLP HTTP receiver                |
| OTel Health Check   | `13133` | OTel Collector health check       |
| ClickHouse HTTP     | `8123`  | HTTP interface                    |
| ClickHouse TCP      | `9000`  | Native TCP protocol               |
| ClickHouse Metrics  | `9363`  | ClickHouse Prometheus metrics     |

## Project Structure

```
signoz-stand/
├── Makefile                          # Stand management commands
├── README.md                         # Documentation (Russian)
├── README.en.md                      # Documentation (English)
├── dashboards/
│   ├── ClickHouse Metrics.json       # ClickHouse metrics dashboard
│   └── ZooKeeper Metrics.json        # ZooKeeper metrics dashboard
├── clickhouse/
│   ├── docker-compose.yml            # ClickHouse + ZooKeeper + TelemetryStore Migrator
│   ├── config/
│   │   ├── cluster.xml               # Cluster configuration
│   │   ├── config.xml                # Main ClickHouse configuration
│   │   ├── custom-function.xml       # Custom functions
│   │   └── users.xml                 # ClickHouse users
│   └── data/
│       └── user_scripts/             # User scripts (histogramQuantile)
└── signoz/
    ├── docker-compose.yml            # SigNoz + OTel Collector
    ├── .env.example                  # Environment variables example
    └── config/
        ├── otel-collector-config.yaml      # OTel Collector configuration
        └── otel-collector-opamp-config.yaml # OpAMP configuration
```

## Infrastructure Metrics Collection

OTel Collector automatically scrapes Prometheus metrics from the following components:

| Job              | Endpoint                       | Description                    |
|------------------|--------------------------------|--------------------------------|
| `otel-collector` | `localhost:8888`               | Collector's own metrics        |
| `clickhouse`     | `host.docker.internal:9363`    | ClickHouse metrics             |
| `zookeeper`      | `host.docker.internal:9141`    | ZooKeeper metrics              |

Scrape interval: **60 seconds**.

## Dashboards

The `dashboards/` folder contains ready-to-import dashboards for SigNoz:

| File                         | Description              |
|------------------------------|--------------------------|
| `ClickHouse Metrics.json`    | ClickHouse metrics       |
| `ZooKeeper Metrics.json`     | ZooKeeper metrics        |

### Import

1. Open SigNoz UI: [http://localhost:8080](http://localhost:8080)
2. Go to **Dashboards** → **+ New Dashboard** → **Import JSON**
3. Upload the desired file from the `dashboards/` folder

## Sending Data

To send traces, metrics, and logs to SigNoz, use the OTLP endpoints:

- **gRPC:** `localhost:4317`
- **HTTP:** `localhost:4318`

Example application configuration (env):

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
```

