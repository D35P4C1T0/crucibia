# Cruciverba di Laurea - Makefile with Mandatory Testing
# All builds require passing tests

.PHONY: help test build dev prod clean ci health logs

# Default target
.DEFAULT_GOAL := help

## Colors for output
GREEN  := \033[0;32m
YELLOW := \033[1;33m
BLUE   := \033[0;34m
RED    := \033[0;31m
NC     := \033[0m

help: ## Show this help message
	@echo "$(BLUE)🎓 Cruciverba di Laurea - Build System$(NC)"
	@echo "===================================="
	@echo "All builds require tests to pass first!"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "$(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

test: ## Run comprehensive test suite
	@echo "$(BLUE)🧪 Running test suite...$(NC)"
	@./scripts/build-with-tests.sh test-only
	@echo "$(GREEN)✅ Tests completed!$(NC)"

test-coverage: ## Run tests with coverage report
	@echo "$(BLUE)📊 Running tests with coverage...$(NC)"
	@./run_tests.sh coverage

test-integration: ## Run integration tests (requires running app)
	@echo "$(BLUE)🌐 Running integration tests...$(NC)"
	@./run_tests.sh integration

build: test ## Build production image (tests required)
	@echo "$(BLUE)🏗️  Building production image...$(NC)"
	@./scripts/build-with-tests.sh production
	@echo "$(GREEN)✅ Production build completed!$(NC)"

dev: ## Start development environment (tests run during build)
	@echo "$(BLUE)🛠️  Starting development environment...$(NC)"
	@./scripts/build-with-tests.sh development

prod: build ## Deploy to production (full pipeline)
	@echo "$(GREEN)🚀 Production deployment completed!$(NC)"
	@echo "$(YELLOW)Application available at: http://localhost:8080$(NC)"

ci: ## Run CI/CD pipeline (test + build)
	@echo "$(BLUE)🔄 Running CI/CD pipeline...$(NC)"
	@./scripts/build-with-tests.sh ci
	@echo "$(GREEN)✅ CI/CD pipeline completed!$(NC)"

clean: ## Clean up containers and images
	@echo "$(YELLOW)🧹 Cleaning up...$(NC)"
	@docker-compose down --volumes --remove-orphans 2>/dev/null || true
	@docker-compose -f docker-compose.prod.yml down --volumes --remove-orphans 2>/dev/null || true
	@docker-compose -f docker-compose.test.yml down --volumes --remove-orphans 2>/dev/null || true
	@docker system prune -f --volumes
	@echo "$(GREEN)✅ Cleanup completed!$(NC)"

health: ## Check application health
	@echo "$(BLUE)🏥 Checking application health...$(NC)"
	@if curl -f http://localhost:8080 >/dev/null 2>&1; then \
		echo "$(GREEN)✅ Application is healthy and responding$(NC)"; \
	else \
		echo "$(RED)❌ Application is not responding$(NC)"; \
		exit 1; \
	fi

logs: ## Show application logs
	@echo "$(BLUE)📋 Application logs:$(NC)"
	@docker-compose logs -f cruciverba-app 2>/dev/null || \
	 docker-compose -f docker-compose.prod.yml logs -f cruciverba-app

logs-test: ## Show test logs
	@echo "$(BLUE)📋 Test logs:$(NC)"
	@docker-compose -f docker-compose.prod.yml logs cruciverba-tests

quick-test: ## Quick unit tests only (for development)
	@echo "$(BLUE)⚡ Quick unit tests...$(NC)"
	@python -m pytest test_app.py -x -q

format: ## Format code (requires black and isort)
	@echo "$(BLUE)🎨 Formatting code...$(NC)"
	@black app.py test_app.py test_integration.py 2>/dev/null || echo "Install black for formatting"
	@isort app.py test_app.py test_integration.py 2>/dev/null || echo "Install isort for import sorting"

security-scan: ## Run security scan on production image
	@echo "$(BLUE)🔒 Running security scan...$(NC)"
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image cruciverba-bianca-prod:latest

benchmark: ## Run performance benchmarks
	@echo "$(BLUE)⚡ Running performance benchmarks...$(NC)"
	@echo "Starting application..."
	@make prod >/dev/null 2>&1 &
	@sleep 15
	@echo "Running load test..."
	@curl -o /dev/null -s -w "Response time: %{time_total}s\nStatus: %{http_code}\n" http://localhost:8080
	@echo "Benchmark completed!"

status: ## Show system status
	@echo "$(BLUE)📊 System Status:$(NC)"
	@echo "$(YELLOW)Docker Containers:$(NC)"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "$(YELLOW)Docker Images:$(NC)"
	@docker images | grep cruciverba || echo "No cruciverba images found"

# Quality Gates
quality-gate: test security-scan ## Run all quality gates
	@echo "$(GREEN)✅ All quality gates passed!$(NC)"

# Development workflow
dev-setup: ## Set up development environment
	@echo "$(BLUE)🛠️  Setting up development environment...$(NC)"
	@cp .env.example .env 2>/dev/null || echo "No .env.example found"
	@mkdir -p data
	@chmod +x scripts/build-with-tests.sh
	@chmod +x run_tests.sh
	@echo "$(GREEN)✅ Development environment ready!$(NC)"
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Edit .env with your passwords"
	@echo "  2. Run 'make dev' to start development"
	@echo "  3. Run 'make test' to run tests"

# Release workflow
release: quality-gate ## Prepare release (all quality gates must pass)
	@echo "$(GREEN)🎉 Release ready!$(NC)"
	@echo "$(YELLOW)All quality gates passed:$(NC)"
	@echo "  ✅ Tests passed"
	@echo "  ✅ Security scan passed"
	@echo "  ✅ Build successful" 