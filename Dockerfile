# OPENCLAW-system Dockerfile
# Multi-stage build for production deployment

# ============================================
# Stage 1: Builder
# ============================================
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ============================================
# Stage 2: Runtime
# ============================================
FROM python:3.11-slim as runtime

WORKDIR /app

# Create non-root user
RUN useradd --create-home --shell /bin/bash openclaw

# Copy Python packages from builder
COPY --from=builder /root/.local /home/openclaw/.local
ENV PATH=/home/openclaw/.local/bin:$PATH

# Copy application files
COPY --chown=openclaw:openclaw . .

# Set permissions
RUN chmod +x scripts/*.sh 2>/dev/null || true

# Switch to non-root user
USER openclaw

# Environment variables
ENV OPENCLAW_ENV=production
ENV OPENCLAW_LOG_LEVEL=info

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

# Expose port
EXPOSE 18789

# Default command
CMD ["python", "-m", "openclaw.server"]
