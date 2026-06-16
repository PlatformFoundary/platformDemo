.PHONY: help build up down restart logs test test-backend test-frontend install clean

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------

build: ## Build all Docker images
	docker compose build

up: ## Start all services (detached)
	docker compose up -d

up-build: ## Build images and start all services (detached)
	docker compose up -d --build

down: ## Stop and remove containers
	docker compose down

down-volumes: ## Stop containers and delete volumes (wipes DB data)
	docker compose down -v

restart: ## Restart all services
	docker compose restart

logs: ## Tail logs for all services
	docker compose logs -f

logs-backend: ## Tail backend logs
	docker compose logs -f backend

logs-frontend: ## Tail frontend logs
	docker compose logs -f frontend

logs-db: ## Tail database logs
	docker compose logs -f db

ps: ## Show running containers
	docker compose ps

# ---------------------------------------------------------------------------
# Install dependencies (local development)
# ---------------------------------------------------------------------------

install: install-backend install-frontend ## Install all dependencies

install-backend: ## Install backend dependencies
	cd backend && npm install

install-frontend: ## Install frontend dependencies
	cd frontend && npm install

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test: install test-backend test-frontend ## Install deps then run all tests

test-backend: install-backend ## Run backend unit tests
	cd backend && npm test

test-frontend: install-frontend ## Run frontend unit tests
	cd frontend && npm test

# ---------------------------------------------------------------------------
# Dev servers (without Docker)
# ---------------------------------------------------------------------------

dev-backend: ## Start backend dev server
	cd backend && npm run dev

dev-frontend: ## Start frontend dev server
	cd frontend && npm run dev

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

clean: ## Remove node_modules from backend and frontend
	rm -rf backend/node_modules frontend/node_modules

clean-all: down-volumes clean ## Remove containers, volumes, and node_modules
