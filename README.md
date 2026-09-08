# shorten-url-deployment

Docker Compose deployment configuration for the Bookmark Management system, a full-stack application built with Clean Architecture. 
It provides URL shortening, bookmark management, and user authentication via a microservice architecture.

## Architecture 

![Architecture](asset/architecture/img.png)

```
                    ┌──────────────────────────────────────────────────────┐
                    │                  Internet / Client                   │
                    └──────────────────────┬───────────────────────────────┘
                                           │ :80
                    ┌──────────────────────▼───────────────────────────────┐
                    │                     nginx                            │
                    │              (Reverse Proxy / Router)                │
                    │                                                      │
                    │  /                        → portal (frontend)        │
                    │  /api/bookmark_service/*  → bookmark-service         │
                    │  /api/user_service/*      → user-service             │
                    └───┬───────────────┬───────────────┬──────────────────┘
                        │               │               │               
            ┌───────────▼──┐  ┌─────────▼──────┐   ┌────▼──────────────┐  
            │    portal    │  │  user-service  │   │ bookmark-service  │  
            │  (Frontend)  │  │    :8080       │   │    :8080          │  
            │    :3000     │  │                │   │                   │  
            │              │  │ - Register     │   │ - Shorten URL     │  
            │              │  │ - Login / JWT  │   │ - Redirect        │ 
            │              │  │ - Update Info  │   │ - CRUD bookmarks  │  
            │              │  │ - Self Info    │   │ - Import bookmarks│  
            └──────────────┘  └───────┬────────┘   └────────┬──────────┘  
                                      │                     │           
             ┌───────────────┐        │                     │
             │worker-service │        │                     │           
             │  (no port)    │        │                     │                
             │               │        │                     │                
             │ - Pop Redis   │        │                     │                
             │   queue       │        │                     │               
             │ - 4 workers   │        │                     │                
             │ - Insert DB   │        │                     │                
             │ - Invalidate  │        │                     │                
             │   cache       │        │                     │                
             └───────┬───────┘        │                     │                
                     │                │                     │           
                  ┌──▼────────────────▼─────────────────────▼──┐
                  │         shorten-url-app (network)          │
                  │                                            │
                  │  ┌───────────────┐   ┌─────────────────┐   │
                  │  │    redis      │   │    postgres     │   │
                  │  │               │   │                 │   │
                  │  │ - short code  │   │ - "user" db     │   │
                  │  │   → url cache │   │ - "bookmark" db │   │
                  │  │ - import queue│   │                 │   │
                  │  └───────────────┘   └─────────────────┘   │
                  └────────────────────────────────────────────┘
```


---

## Project Structure

```
shorten-url-deployment/
├── .github/workflows/       # CI/CD pipelines
├── bookmark-service/
│   └── .env                 # environment for bookmark-service
├── user-service/
│   └── .env                 # environment for user-service
├── worker-service/
│   └── .env                 # environment for worker-service
├── nginx/
│   └── nginx.conf           # environment for nginx
├── postgres/                # DB initialization scripts
│   ├── init-db/             
│   │   └── 01_init_dbs.sql  # Initialize user and bookmark table
│   └── .env                 # environment for postgres
├── docker-compose.yaml
├── Makefile
├── private.pem
├── public.pem
└── .gitignore
```

---

## Services

| Service            | Image                                      | Port (internal) | Description                          |
|--------------------|--------------------------------------------|-----------------|--------------------------------------|
| `nginx`            | `nginx:alpine`                             | 80 (exposed)    | Reverse proxy, single entry point    |
| `portal`           | `hemlockpham/shorten-url-portal:latest`    | 3000            | Frontend SPA                         |
| `user-service`     | `hemlockpham/user-service:latest`          | 8080            | Auth & user management               |
| `bookmark-service` | `hemlockpham/bookmark-service:latest`      | 8080            | Bookmark & URL shortener             |
| `worker-service`   | `hemlockpham/worker-service:latest`        | —               | Background import worker             |
| `postgres`         | `postgres:17`                              | 5432            | Persistent storage (2 databases)     |
| `redis`            | `redis:alpine`                             | 6379            | Short URL cache & import queue       |

---

## Routing (nginx)

| Path pattern              | Upstream           |
|---------------------------|--------------------|
| `/`                       | `portal`           |
| `/api/bookmark_service/*` | `bookmark-service` |
| `/api/user_service/*`     | `user-service`     |

Rate limiting is configured (`1000 req/min` per user) on API routes and can be enabled in [nginx/nginx.conf](nginx/nginx.conf).

---

## Getting Started

### Prerequisites

- [Docker](https://www.docker.com/) & Docker Compose
- [Make](https://www.gnu.org/software/make/)


### 1. Set up bookmark service environment variables

- [Bookmark Service Environment Setup](https://github.com/HemlockPham7/bookmark-service)

### 2. Set up user service environment variables

- [User Service Environment Setup](https://github.com/HemlockPham7/user-service)

### 3. Set up worker service environment variables

- [Worker Service Environment Setup](https://github.com/HemlockPham7/worker-service)

### 4. Set up postgres environment variables

| Variable                 | Default          | Description                                              |
|--------------------------|------------------|----------------------------------------------------------|
| `POSTGRES_USER`          | admin            | PostgreSQL username used by the database container.      |
| `POSTGRES_PASSWORD`      | admin            | PostgreSQL password used by the database container.      |
| `POSTGRES_DB`            | bookmark         | PostgreSQL database name used by the database container. |
| `TZ`                     | Asia/Ho_Chi_Minh | Application timezone.                                    |

### 5. Start infrastructure (PostgreSQL + Redis)

```bash
docker-compose up redis postgres -d
```

### 6. Start service (user-service + bookmark-service)

```bash
docker-compose up user-service bookmark-service worker-service -d
```

The API for user-service will be available at `http://localhost/api/user-service`.
Swagger user-service UI: `http://localhost/api/user-service/swagger/index.html`.

The API for bookmark-service will be available at `http://localhost/api/bookmark-service`.
Swagger bookmark-service UI: `http://localhost/api/bookmark-service/swagger/index.html#/`.

### 7. Run the frontend

```bash
docker-compose up portal -d
```

The API for user-service will be available at `http://localhost`.

### 8. Run the nginx

```bash
docker-compose up nginx -d
```

---

## Q&A

### 1. How to check the database

- Run `docker exec -it postgres psql -U admin -d bookmark`
- If we see the following prompt, it means that we have successfully connected to the database:

```
bookmark=#
```

- Then we can exit by typing `\q`.
- It will be the same for `user` database.