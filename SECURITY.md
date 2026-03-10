# Security Policy

**Version:** 1.0
**Last Updated:** 2026-03-09
**Status:** Active

---

## Overview

This document outlines the security policies, procedures, and best practices for the OPENCLAW-system project. Security is a foundational concern given the system's ability to execute commands and access resources.

---

## Table of Contents

1. [Security Architecture](#security-architecture)
2. [Sandbox Execution](#sandbox-execution)
3. [Authentication & Authorization](#authentication--authorization)
4. [Secrets Management](#secrets-management)
5. [Command Execution Policy](#command-execution-policy)
6. [Audit Logging](#audit-logging)
7. [Vulnerability Reporting](#vulnerability-reporting)
8. [Incident Response](#incident-response)

---

## Security Architecture

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────┐
│                    USER REQUEST                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: Authentication                                    │
│  • Token validation                                         │
│  • Rate limiting                                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 2: Authorization                                     │
│  • Domain access control                                    │
│  • Tool permissions                                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: Input Validation                                  │
│  • Sanitization                                             │
│  • Injection prevention                                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 4: Execution Sandbox                                 │
│  • Isolated environment                                     │
│  • Resource limits                                          │
│  • Network isolation                                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 5: Output Validation                                 │
│  • Secret detection                                         │
│  • Security scanning                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Sandbox Execution

### Configuration

```json
{
  "sandbox": {
    "enabled": true,
    "backend": "docker",
    "config": {
      "networkMode": "none",
      "memory": "512m",
      "cpus": 1,
      "user": "nobody",
      "readOnlyRootFilesystem": true,
      "capDrop": ["ALL"],
      "securityOpt": ["no-new-privileges"]
    }
  }
}
```

### Sandbox Rules

| Rule | Description |
|------|-------------|
| Network isolation | No outbound network by default |
| User namespace | Run as non-root (nobody) |
| Read-only filesystem | Cannot modify system files |
| Dropped capabilities | All Linux capabilities dropped |
| Memory limit | 512MB max per execution |
| CPU limit | 1 CPU max per execution |

### Bypass Policy

Sandbox bypass requires:
1. Explicit user approval per operation
2. Logging of all bypass events
3. Manager-level authorization
4. Time-limited session

---

## Authentication & Authorization

### Authentication Methods

| Method | Use Case | Security Level |
|--------|----------|----------------|
| Static Token | Development | Low |
| API Key | Service-to-service | Medium |
| OAuth 2.0 | Production | High |
| mTLS | Enterprise | Highest |

### Authorization Model

```yaml
rbac:
  roles:
    admin:
      permissions: [all]
    operator:
      permissions: [read, execute, approve]
    user:
      permissions: [read, request]
    viewer:
      permissions: [read]

  domain_access:
    dev: [admin, operator, user]
    infra: [admin, operator]
    crypto: [admin, operator, user]
    # ...
```

---

## Secrets Management

### Prohibited Practices

| Practice | Reason | Alternative |
|----------|--------|-------------|
| Hardcoded secrets | Exposure risk | Use vault/secrets manager |
| Secrets in logs | Leak risk | Mask in output |
| Secrets in config files | Access risk | Environment variables |
| Secrets in memory | Dump risk | Secure memory handling |

### Secret Detection

```python
SECRET_PATTERNS = [
    r'(?i)password\s*=\s*["\']?[^\s"\']+',
    r'(?i)api[_-]?key\s*=\s*["\']?[^\s"\']+',
    r'(?i)secret\s*=\s*["\']?[^\s"\']+',
    r'(?i)token\s*=\s*["\']?[^\s"\']+',
    r'-----BEGIN (?:RSA |EC |DSA )?PRIVATE KEY-----',
    r'(?i)aws_access_key_id\s*=\s*[A-Z0-9]{20}',
    r'(?i)aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}',
]
```

### Secrets Storage

```
Recommended: HashiCorp Vault
Alternative: AWS Secrets Manager / Azure Key Vault
Fallback: Encrypted environment variables
```

---

## Command Execution Policy

### Forbidden Commands

```yaml
forbidden_commands:
  - pattern: "rm -rf /"
    severity: critical
  - pattern: "mkfs.*"
    severity: critical
  - pattern: "dd if=.*of=/dev/"
    severity: critical
  - pattern: ":(){ :|:& };:"
    severity: critical
  - pattern: "chmod -R 777 /"
    severity: high
  - pattern: "chown -R .* /"
    severity: high
  - pattern: "iptables -F"
    severity: high
  - pattern: "systemctl (stop|disable) .*"
    severity: medium
```

### Approval Required Commands

```yaml
requires_approval:
  - pattern: "git push"
    context: "any"
  - pattern: "kubectl delete"
    context: "any"
  - pattern: "terraform (apply|destroy)"
    context: "any"
  - pattern: "docker rm"
    context: "production"
  - pattern: "npm publish"
    context: "any"
```

### Safe Bin Policy

```yaml
safe_bins:
  - ls
  - cat
  - head
  - tail
  - grep
  - find
  - wc
  - sort
  - uniq
  - git
  - npm
  - node
  - python
```

---

## Audit Logging

### Events Logged

| Event Type | Fields |
|------------|--------|
| Authentication | timestamp, user, method, success |
| Authorization | timestamp, user, resource, action, granted |
| Command Execution | timestamp, user, command, sandbox, result |
| Approval Request | timestamp, requester, command, approver, decision |
| Configuration Change | timestamp, user, change, previous, new |
| Security Event | timestamp, type, severity, details |

### Log Format

```json
{
  "timestamp": "2026-03-09T12:00:00Z",
  "event_type": "command_execution",
  "user": "user@example.com",
  "session_id": "abc123",
  "domain": "/dev",
  "command": "npm install express",
  "sandbox": true,
  "result": "success",
  "duration_ms": 5432,
  "approval_required": false
}
```

### Log Retention

| Log Type | Retention | Storage |
|----------|-----------|---------|
| Security events | 1 year | Encrypted, immutable |
| Command execution | 90 days | Encrypted |
| Authentication | 90 days | Encrypted |
| Debug | 7 days | Standard |

---

## Vulnerability Reporting

### Reporting Process

1. **DO NOT** open a public issue
2. Email security@openclaw.ai with:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)
3. Expect acknowledgment within 48 hours
4. Allow 90 days for fix before disclosure

### Severity Classification

| Severity | CVSS | Response Time |
|----------|------|---------------|
| Critical | 9.0-10.0 | 24 hours |
| High | 7.0-8.9 | 72 hours |
| Medium | 4.0-6.9 | 7 days |
| Low | 0.1-3.9 | 30 days |

### Disclosure Policy

- Coordinated disclosure with reporter
- 90-day maximum disclosure window
- Credit to reporter (if desired)
- CVE assignment when applicable

---

## Incident Response

### Incident Classification

| Level | Description | Response |
|-------|-------------|----------|
| P1 | Active breach, data exfiltration | Immediate: isolate, investigate |
| P2 | Vulnerability exploited, no breach | Same day: patch, audit |
| P3 | Vulnerability discovered, not exploited | 7 days: patch, test |
| P4 | Security concern, no immediate risk | 30 days: review, prioritize |

### Response Procedure

```
1. IDENTIFY
   - Detect incident
   - Classify severity
   - Alert stakeholders

2. CONTAIN
   - Isolate affected systems
   - Preserve evidence
   - Prevent spread

3. ERADICATE
   - Remove threat
   - Patch vulnerabilities
   - Update configurations

4. RECOVER
   - Restore services
   - Verify integrity
   - Monitor closely

5. REVIEW
   - Post-mortem analysis
   - Update procedures
   - Document lessons learned
```

### Contact Information

| Role | Contact |
|------|---------|
| Security Team | security@openclaw.ai |
| On-call Security | +1-XXX-XXX-XXXX |
| CISO | ciso@openclaw.ai |

---

## Security Checklist

### Pre-Deployment

- [ ] All secrets in vault
- [ ] Sandbox enabled
- [ ] Audit logging active
- [ ] Rate limiting configured
- [ ] Input validation enabled
- [ ] Security scan passed

### Regular Reviews

- [ ] Weekly: Audit log review
- [ ] Monthly: Permission audit
- [ ] Quarterly: Penetration test
- [ ] Annual: Security policy review

---

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE/SANS Top 25](https://cwe.mitre.org/top25/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

**Document:** Security Policy
**Location:** `/SECURITY.md`
**Owner:** Security Team
