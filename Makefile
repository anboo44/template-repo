# =============================================================================
# MAKEFILE TEMPLATE
# Uncomment and modify the sections you need for your specific project
# =============================================================================

# Project Configuration
PROJECT_NAME := my-project

# Shared Repository Configuration
SHARED_REPO_URL := https://github.com/anboo44/shared-repo
SHARED_REPO_DIR := $(HOME)/.shared-repo

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# =============================================================================
# Help
# =============================================================================

.PHONY: help
help: ## Show this help message
	@echo "$(CYAN)$(PROJECT_NAME) - Available commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# Setup Environment
# =============================================================================

.PHONY: setup-local
setup-local: ## Setup local environment with shared repository
	@echo "$(BLUE)Setting up local environment...$(NC)"
	@$(MAKE) setup-pre-commit
	@$(MAKE) install
	# Add other cleanup commands as needed
	@echo "$(GREEN)Local environment setup completed!$(NC)"

.PHONY: setup-shared-repo
setup-shared-repo: ## Clone or update shared repository and copy resources
	@echo "$(BLUE)Setting up shared repository...$(NC)"
	@if [ -d "$(SHARED_REPO_DIR)" ]; then \
		echo "$(YELLOW)Updating existing shared repository...$(NC)"; \
		cd "$(SHARED_REPO_DIR)" && \
		DEFAULT_BRANCH=$$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main") && \
		if ! git pull origin "$$DEFAULT_BRANCH" 2>/dev/null; then \
			echo "$(YELLOW)Cannot pull from '$$DEFAULT_BRANCH', trying 'master'...$(NC)" && \
			if ! git pull origin master 2>/dev/null; then \
				echo "$(YELLOW)Cannot pull from 'master', trying 'main'...$(NC)" && \
				if ! git pull origin main 2>/dev/null; then \
					echo "$(RED)Cannot pull from remote repository$(NC)" && exit 1; \
				fi; \
			fi; \
		fi; \
	else \
		echo "$(BLUE)Cloning shared repository...$(NC)"; \
		if ! git clone "$(SHARED_REPO_URL)" "$(SHARED_REPO_DIR)"; then \
			echo "$(RED)Cannot clone repository from $(SHARED_REPO_URL)$(NC)" && exit 1; \
		fi; \
	fi
	@echo "$(GREEN)Shared repository ready at $(SHARED_REPO_DIR)$(NC)"
	@echo "$(BLUE)Copying shared resources...$(NC)"
	@mkdir -p .github
	@if [ -d ".github/shared" ]; then \
		rm -rf ".github/shared"; \
	fi
	@cp -r "$(SHARED_REPO_DIR)/shared" ".github/shared"
	@echo "$(GREEN)Shared resources copied to .github/shared$(NC)"
	
.PHONY: setup-pre-commit
setup-pre-commit: setup-shared-repo ## Setup pre-commit hooks using shared script
	@echo "$(BLUE)Setting up pre-commit hooks...$(NC)"
	@# Check if this is a git repository
	@if [ ! -d ".git" ]; then \
		echo "$(RED)This is not a git repository$(NC)" && exit 1; \
	fi
	@# Remove existing pre-commit hook if exists
	@if [ -f ".git/hooks/pre-commit" ]; then \
		echo "$(YELLOW)Removing existing pre-commit hook...$(NC)"; \
		rm -f ".git/hooks/pre-commit"; \
	fi
	@# Check if shared hooks setup script exists
	@if [ ! -f ".github/shared/hooks/setup-pre-commit.sh" ]; then \
		echo "$(RED)Pre-commit setup script not found at .github/shared/hooks/setup-pre-commit.sh$(NC)" && exit 1; \
	fi
	@# Make the setup script executable
	@chmod +x ".github/shared/hooks/setup-pre-commit.sh"
	@# Run the setup script
	@echo "$(BLUE)Running pre-commit setup script...$(NC)"
	@"./.github/shared/hooks/setup-pre-commit.sh"
	@# Remove hooks folder after setup
	@echo "$(BLUE)Cleaning up hooks folder...$(NC)"
	@rm -rf ".github/shared/hooks"
	@echo "$(GREEN)Pre-commit hooks setup completed and hooks folder cleaned up!$(NC)"

.PHONY: install
install: ## Install dependencies
	@echo "$(BLUE)Installing dependencies...$(NC)"
	# Add your dependency installation commands here
	# Example for Python: pip install -r requirements.txt
	# Example for Node.js: npm install
	@echo "$(GREEN)Dependencies installed!$(NC)"	

# =============================================================================
# Compile & Run
# =============================================================================

.PHONY: compile
compile: ## Compile the application
	@echo "$(BLUE)Compiling $(PROJECT_NAME)...$(NC)"
	# Add your compilation commands here
	# Example for Java: javac -d bin src/*.java
	# Example for Go: go build -o $(PROJECT_NAME) main.go
	# Example for C/C++: gcc -o $(PROJECT_NAME) src/*.c

.PHONY: run
run: ## Run the application in development mode
	@echo "$(BLUE)Starting $(PROJECT_NAME)...$(NC)"
	# Add your run commands here
	# Example for Python: python $(SRC_DIR)/main.py
	# Example for Node.js: npm start
	# Example for Go: go run main.go

.PHONY: run-prod
run-prod: ## Run the application in production mode
	@echo "$(BLUE)Starting $(PROJECT_NAME) in production mode...$(NC)"
	# Add your production run commands here
	# Example for Python: gunicorn -w 4 -b 0.0.0:8000 $(SRC_DIR):app
	# Example for Node.js: NODE_ENV=production npm start
	# Example for Go: ./$(PROJECT_NAME)		

# =============================================================================
# Database & Migrations
# =============================================================================

.PHONY: db-setup
db-setup: ## Setup database
	@echo "$(BLUE)Setting up database...$(NC)"
	# Add your database setup commands here
	@echo "$(GREEN)Database setup completed!$(NC)"

.PHONY: db-migrate
db-migrate: ## Run database migrations
	@echo "$(BLUE)Running database migrations...$(NC)"
	# Add your migration commands here
	@echo "$(GREEN)Migrations completed!$(NC)"

.PHONY: db-seed
db-seed: ## Seed database with sample data
	@echo "$(BLUE)Seeding database...$(NC)"
	# Add your database seeding commands here
	@echo "$(GREEN)Database seeded!$(NC)"

# =============================================================================
# Code Quality
# =============================================================================

.PHONY: lint-check
lint-check: ## Run linter
	@echo "$(BLUE)Running linter...$(NC)"
	# Add your linting commands here
	# Example for JavaScript: eslint $(SRC_DIR)/
	# Example for Go: golangci-lint run
	# Example for Python: ruff check
	@echo "$(GREEN)Linting completed!$(NC)"

.PHONY: format
format: ## Format code
	@echo "$(BLUE)Formatting code...$(NC)"
	# Add your formatting commands here
	# Example for Python: black $(SRC_DIR)/ && isort $(SRC_DIR)/
	# Example for JavaScript: prettier --write $(SRC_DIR)/
	# Example for Go: go fmt ./...
	@echo "$(GREEN)Code formatted!$(NC)"

.PHONY: format-check
format-check: ## Check code formatting
	@echo "$(BLUE)Checking code formatting...$(NC)"
	# Add your format checking commands here
	# Example for Python: black --check $(SRC_DIR)/ && isort --check-only $(SRC_DIR)/
	# Example for JavaScript: prettier --check $(SRC_DIR)/
	# Example for Go: go fmt -l ./...
	@echo "$(GREEN)Format check completed!$(NC)"

.PHONY: test
test: ## Run tests
	@echo "$(BLUE)Running tests...$(NC)"
	# Add your test commands here
	# Example for Python: pytest tests/
	# Example for JavaScript: jest
	# Example for Go: go test ./......
	@echo "$(GREEN)Tests completed!$(NC)"

.PHONY: test-coverage
test-coverage: ## Run tests with coverage report
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	# Add your test coverage commands here
	# Example for Python: pytest --cov=$(SRC_DIR) tests/ --cov-report=term-missing
	# Example for JavaScript: jest --coverage
	# Example for Go: go test -cover ./......
	@echo "$(GREEN)Test coverage completed!$(NC)"

.PHONY: check-quality-ci
check-quality-ci: ## Run all code quality checks
	@$(MAKE) lint-check
	@$(MAKE) format-check
	@$(MAKE) test-coverage
	@echo "$(GREEN)All code quality checks passed!$(NC)"

# =============================================================================
# Build Application
# =============================================================================

.PHONY: build-dev
build-dev: ## Build the application in development mode
	@echo "$(BLUE)Building $(PROJECT_NAME) in development mode...$(NC)"
	# Add your development build commands here
	@echo "$(GREEN)Development build completed!$(NC)"

.PHONY: build-stg
build-stg: ## Build the application in staging mode
	@echo "$(BLUE)Building $(PROJECT_NAME) in staging mode...$(NC)"
	# Add your staging build commands here
	@echo "$(GREEN)Staging build completed!$(NC)"

.PHONY: build-prod
build-prod: ## Build the application in production mode
	@echo "$(BLUE)Building $(PROJECT_NAME) in production mode...$(NC)"
	# Add your production build commands here
	@echo "$(GREEN)Production build completed!$(NC)"
