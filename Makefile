.PHONY: help install validate lint test clean docs

# Default target
help:
	@echo "OPENCLAW-system Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  install     Install dependencies"
	@echo "  validate    Validate all profiles"
	@echo "  lint        Run linting"
	@echo "  test        Run tests"
	@echo "  clean       Clean generated files"
	@echo "  docs        Generate documentation"
	@echo "  status      Check system status"
	@echo "  start       Start OPENCLAW services"
	@echo "  stop        Stop OPENCLAW services"

# Install dependencies
install:
	@echo "Installing dependencies..."
	pip install pyyaml jsonschema markdown
	npm install -g yaml-lint markdownlint-cli

# Validate all profiles
validate:
	@echo "Validating profiles..."
	@python -c "import yaml; [yaml.safe_load(open(f)) for f in profiles/library/specialists/*.yaml]" 2>/dev/null && echo "✅ All profiles valid" || echo "❌ Validation failed"

# Run linting
lint:
	@echo "Running linting..."
	yamllint profiles/
	markdownlint docs/

# Run tests
test:
	@echo "Running tests..."
	python -m pytest tests/ -v

# Clean generated files
clean:
	@echo "Cleaning..."
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.pyc" -delete
	find . -name ".DS_Store" -delete

# Generate documentation
docs:
	@echo "Generating documentation index..."
	python scripts/generate-docs-index.py

# Check system status
status:
	@./scripts/tools-control.sh status

# Start OPENCLAW services
start:
	@./scripts/tools-control.sh gpt-researcher start
	@./scripts/tools-control.sh maestro start

# Stop OPENCLAW services
stop:
	@./scripts/tools-control.sh gpt-researcher stop
	@./scripts/tools-control.sh maestro stop

# Watch for file changes (development)
watch:
	@echo "Watching for changes..."
	@inotifywait -m -r -e modify,create,delete profiles/ docs/ | while read path action file; do \
		echo "$$action $$path$$file"; \
		make validate; \
	done

# Format all files
format:
	@echo "Formatting files..."
	@find . -name "*.yaml" -o -name "*.yml" | xargs yamlfmt
	@find . -name "*.md" | xargs markdownlint --fix

# Security check
security:
	@echo "Running security check..."
	@! grep -r -E "(password|secret|api_key)\s*=\s*['\"][^'\"]+['\"]" profiles/ config/ 2>/dev/null && echo "✅ No secrets found" || echo "❌ Potential secrets detected"

# Export profiles to JSON
export:
	@echo "Exporting profiles to JSON..."
	@python scripts/export-profiles.py --format json --output dist/profiles.json
