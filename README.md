# signoz-stand

Стенд для развёртывания [SigNoz](https://signoz.io/) — платформы observability (трейсы, метрики, логи) с хранилищем на ClickHouse.

## Архитектура

```
┌─────────────────────────────────────────────────┐
│                  ClickHouse                     │
│  ┌───────────┐  ┌────────────┐  ┌───────────┐  │
│  │ ZooKeeper │→ │ ClickHouse │← │ Migrator  │  │
│  └───────────┘  └─────┬──────┘  └───────────┘  │
│                       │ :9000                   │
└───────────────────────┼─────────────────────────┘
                        │
┌───────────────────────┼─────────────────────────┐
│                  SigNoz                         │
│  ┌────────────────┐   │   ┌──────────────────┐  │
│  │ OTel Collector │───┘   │   SigNoz (UI +   │  │
│  │  :4317 / :4318 │       │   API) :8080     │  │
│  └────────────────┘       └──────────────────┘  │
└─────────────────────────────────────────────────┘
```

## Требования

- [Docker](https://docs.docker.com/get-docker/) ≥ 20.10
- [Docker Compose](https://docs.docker.com/compose/) v2+
- GNU Make

## Быстрый старт

```bash
# Клонировать репозиторий
git clone <repo-url> && cd signoz-stand

# Запустить весь стенд
make up
```

При первом запуске автоматически создастся файл `signoz/.env` из `signoz/.env.example`.

## Переменные окружения

Файл `signoz/.env`:

| Переменная             | Описание                           | Значение по умолчанию         |
|------------------------|------------------------------------|-------------------------------|
| `CLICKHOUSE_URL`       | Адрес ClickHouse для SigNoz        | `host.docker.internal:9000`   |
| `SIGNOZ_TOKEN_SECRET`  | Секрет для JWT-токенов             | `orient-holiday-lazy`         |

Версии образов задаются в `docker-compose.yml`:

| Переменная     | Описание                  | По умолчанию  |
|----------------|---------------------------|---------------|
| `VERSION`      | Версия SigNoz             | `v0.113.0`    |
| `OTELCOL_TAG`  | Версия OTel Collector     | `v0.144.1`    |

## Команды Make

```bash
make help                # Показать все доступные команды
```

### Управление стендом

| Команда                  | Описание                              |
|--------------------------|---------------------------------------|
| `make up`                | Запустить весь стенд                  |
| `make down`              | Остановить весь стенд                 |
| `make restart`           | Перезапустить весь стенд              |

### ClickHouse

| Команда                  | Описание                              |
|--------------------------|---------------------------------------|
| `make up-clickhouse`     | Запустить ClickHouse                  |
| `make down-clickhouse`   | Остановить ClickHouse                 |
| `make restart-clickhouse`| Перезапустить ClickHouse              |
| `make logs-clickhouse`   | Логи ClickHouse (follow)              |

### SigNoz

| Команда                  | Описание                              |
|--------------------------|---------------------------------------|
| `make up-signoz`         | Запустить SigNoz                      |
| `make down-signoz`       | Остановить SigNoz                     |
| `make restart-signoz`    | Перезапустить SigNoz                  |
| `make logs-signoz`       | Логи SigNoz (follow)                  |

### Утилиты

| Команда                  | Описание                              |
|--------------------------|---------------------------------------|
| `make ps`                | Статус всех контейнеров               |
| `make logs`              | Логи всех сервисов (follow)           |
| `make env`               | Создать `.env` из `.env.example`      |

## Порты

| Сервис           | Порт   | Описание                 |
|------------------|--------|--------------------------|
| SigNoz UI / API  | `8080` | Веб-интерфейс и API      |
| OTel gRPC        | `4317` | OTLP gRPC приёмник       |
| OTel HTTP        | `4318` | OTLP HTTP приёмник       |
| ClickHouse HTTP  | `8123` | HTTP-интерфейс           |
| ClickHouse TCP   | `9000` | Нативный TCP-протокол    |

## Структура проекта

```
signoz-stand/
├── Makefile                          # Команды управления стендом
├── README.md
├── clickhouse/
│   ├── docker-compose.yml            # ClickHouse + ZooKeeper + Migrator
│   ├── config/
│   │   ├── cluster.xml               # Конфигурация кластера
│   │   ├── config.xml                # Основная конфигурация ClickHouse
│   │   ├── custom-function.xml       # Пользовательские функции
│   │   └── users.xml                 # Пользователи ClickHouse
│   └── data/
│       └── user_scripts/             # Пользовательские скрипты (histogramQuantile)
└── signoz/
    ├── docker-compose.yml            # SigNoz + OTel Collector
    ├── .env.example                  # Пример переменных окружения
    └── config/
        ├── otel-collector-config.yaml      # Конфигурация OTel Collector
        └── otel-collector-opamp-config.yaml # OpAMP конфигурация
```

## Отправка данных

Для отправки трейсов, метрик и логов в SigNoz используйте OTLP-эндпоинты:

- **gRPC:** `localhost:4317`
- **HTTP:** `localhost:4318`

Пример конфигурации вашего приложения (env):

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
```

