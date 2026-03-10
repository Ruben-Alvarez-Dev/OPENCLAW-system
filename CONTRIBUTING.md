# Contributing to OPENCLAW-system

Thank you for your interest in contributing to OPENCLAW-system! This document provides guidelines and instructions for contributing.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Contribution Process](#contribution-process)
5. [Coding Standards](#coding-standards)
6. [Documentation Guidelines](#documentation-guidelines)
7. [Testing Requirements](#testing-requirements)
8. [Pull Request Process](#pull-request-process)

---

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome diverse viewpoints
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Public or private harassment
- Publishing others' private information
- Other unprofessional conduct

---

## Getting Started

### Prerequisites

- Git
- Node.js 18+ or Python 3.10+
- Docker (for sandbox execution)
- Access to an LLM provider (Ollama, OpenAI, etc.)

### Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/OPENCLAW-system.git
cd OPENCLAW-system

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL/OPENCLAW-system.git
```

---

## Development Setup

### Environment Configuration

```bash
# Copy example configuration
cp config/openclaw.json.example config/openclaw.json

# Edit configuration
vim config/openclaw.json
```

### Directory Structure

```
OPENCLAW-system/
├── config/              # Configuration files
├── docs/                # Documentation
├── profiles/            # Specialist profiles
│   └── library/         # Profile library
│       ├── specialists/ # YAML profiles
│       ├── protocols/   # Operational protocols
│       ├── templates/   # Base templates
│       └── registries/  # Skills/tools registries
├── knowledge_sources/   # Personal knowledge
├── scripts/             # Utility scripts
└── CLAUDE.md           # Project instructions
```

---

## Contribution Process

### 1. Create a Branch

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name
```

### Branch Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/` | `feature/add-crypto-unit` |
| Fix | `fix/` | `fix/validation-error` |
| Docs | `docs/` | `docs/update-api-reference` |
| Refactor | `refactor/` | `refactor/manager-prompt` |

### 2. Make Changes

- Follow coding standards
- Write tests for new functionality
- Update documentation
- Keep changes focused

### 3. Commit Changes

```bash
# Stage changes
git add .

# Commit with conventional message
git commit -m "feat: add new specialist unit for marketing domain"
```

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code refactoring |
| `test` | Adding tests |
| `chore` | Maintenance tasks |

#### Examples

```
feat(specialists): add MARKETING-001 unit

- Add YAML profile for marketing domain
- Define tri-agent configuration
- Add marketing-specific skills

Closes #123
```

### 4. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create Pull Request on GitHub
```

---

## Coding Standards

### YAML Files

```yaml
# Use 2-space indentation
# Include comments for clarity
# Follow existing structure

id: EXAMPLE-001
name: Example Unit
namespace: /example

manager:
  model: openclaw-llama32
  temperature: 0.7
  system_prompt: |
    Clear, well-structured prompt here.

worker:
  # ...

archivist:
  # ...
```

### Markdown Files

- Use ATX-style headings (`#`, `##`, `###`)
- Include table of contents for long documents
- Use code blocks with language specification
- Keep lines under 100 characters

### JSON Configuration

- Use 2-space indentation
- Include comments via `$schema` references
- Sort keys alphabetically where appropriate

---

## Documentation Guidelines

### Document Structure

```markdown
# Document Title

**Version:** 1.0
**Last Updated:** YYYY-MM-DD
**Status:** Active

---

## Overview

Brief description of the document.

---

## Table of Contents

1. [Section 1](#section-1)
2. [Section 2](#section-2)

---

## Section 1

Content here...

---

**Document:** Document Name
**Location:** `/path/to/document.md`
```

### Specialist Profiles

Each specialist profile must include:

1. **Header**: id, name, namespace, version, status
2. **Tri-Agent Configuration**: manager, worker, archivist
3. **Skills**: Relevant skills for the domain
4. **Configuration**: Memory, policies, consensus
5. **Metrics Template**: Base metrics structure
6. **Examples**: Usage examples

---

## Testing Requirements

### Profile Validation

Before submitting a new or modified profile:

```bash
# Validate YAML syntax
python -c "import yaml; yaml.safe_load(open('profiles/library/specialists/NEW-001-UNIT.yaml'))"

# Check required fields
python scripts/validate-profile.py profiles/library/specialists/NEW-001-UNIT.yaml
```

### Integration Testing

For significant changes:

1. Deploy to test environment
2. Execute sample requests
3. Verify response quality
4. Check memory updates
5. Validate metrics collection

---

## Pull Request Process

### PR Checklist

- [ ] Branch follows naming convention
- [ ] Commits follow conventional format
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] No sensitive information included

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Unit tests added
- [ ] Integration tests passed
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] No sensitive information
```

### Review Process

1. Automated checks run
2. At least one maintainer review
3. Address review comments
4. Approval required for merge
5. Squash and merge to main

### Review Criteria

| Criteria | Requirement |
|----------|-------------|
| Code Quality | Follows standards |
| Documentation | Complete and accurate |
| Tests | Adequate coverage |
| Security | No vulnerabilities |
| Performance | No regressions |

---

## Getting Help

- Open an issue for bugs or feature requests
- Join discussions in existing issues
- Email: contribute@openclaw.ai

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

**Document:** Contributing Guidelines
**Location:** `/CONTRIBUTING.md`
