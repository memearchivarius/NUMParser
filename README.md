## NUMParser

Сервис парсит релизы, сохраняет их в BoltDB и отдаёт веб-интерфейс/JSON API. Этот репозиторий включает Docker-образ и GitHub Actions workflow для публикации образа в GHCR.

### Быстрый старт (Docker)

1) Получите TMDB API Bearer Token и сохраните как переменную окружения `TMDB_KEY` (строка вида `Bearer <token>`).

2) Запустите контейнер:

```bash
docker run -d \
  --name numparser \
  -e TMDB_KEY="Bearer <ваш-токен>" \
  -e PORT=38888 \
  -p 38888:38888 \
  -v numparser_data:/app \
  ghcr.io/<owner>/<repo>:latest
```

После запуска UI доступен на `http://localhost:38888/`, поиск на `GET /search?query=<q>`. В каталоге `/app` сохраняются база `db/numparser.db` и релизы `public/releases`.

### Параметры образа (env)

- `TMDB_KEY` (обязателен): Bearer-токен TMDB для запросов. Альтернатива — смонтировать файл `/app/tmdb.key` внутри контейнера со строкой токена.
- `PORT` (по умолчанию `38888`): порт HTTP сервера.
- `PROXY` (опционально): прокси для rutor, формат `http://user:password@ip:port` или `socks5://...`.
- `USE_PROXY` (опционально, `true/false`, по умолчанию `false`): включает автоподстановку прокси через скрипт `proxy.sh`. При `true` контейнер выполнит `/app/proxy.sh` и будет ожидать файл `/app/proxy.list`.
- `PROXY_LIST_CONTENT` (опционально): если задан, стандартный `proxy.sh` запишет содержимое в `/app/proxy.list`.

### Том(а) контейнера

- `/app` — основной рабочий каталог (содержит `numparser`, `db/`, `public/`, `tmdb.key`, а также `copy.sh` и `proxy.sh`). Рекомендуется монтировать в именованный volume для сохранения данных:

```bash
docker volume create numparser_data
docker run -d --name numparser \
  -e TMDB_KEY="Bearer <token>" \
  -p 38888:38888 \
  -v numparser_data:/app \
  ghcr.io/<owner>/<repo>:latest
```

### Сценарии и расширение поведения

- `/app/copy.sh` — вызывается приложением после сохранения выпусков. По умолчанию — no-op; замените на свой скрипт с нужной логикой копирования/синхронизации.
- `/app/proxy.sh` — вызывается при `USE_PROXY=true` для генерации файла `/app/proxy.list`. По умолчанию читает `PROXY_LIST_CONTENT`; можете заменить скрипт собственной реализацией получения списка прокси.

### Сборка локально

```bash
docker build -t numparser:local .
docker run --rm -it -e TMDB_KEY="Bearer <token>" -p 38888:38888 numparser:local
```

### CI: публикация образов

Workflow `.github/workflows/docker.yml` собирает и публикует мультиарх-образы (linux/amd64, linux/arm64) в GHCR:

- при пуше в ветку `main` и пуше тега `v*`/`V*`
- теги включают имя ветки, тег версии и SHA коммита

Чтобы тянуть образ:

```bash
docker pull ghcr.io/<owner>/<repo>:<tag>
```

### Параметры CLI бинарника (для справки)

В контейнере они маппятся из env переменных:

- `-p, --port` → `PORT`
- `--proxy` → `PROXY`
- `--useproxy` → `USE_PROXY` (true/false)

### Порты

- HTTP: 38888 (в контейнере). Публикуйте наружу при необходимости: `-p 38888:38888`.


