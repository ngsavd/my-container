# ─────────────────────────────────────────────────────────────
# Personal Infra Tooling Container
# Optimized for: Terraform LLM PR Review workflow
# Base: Alpine 3.21 (active CVE support)
# ─────────────────────────────────────────────────────────────
FROM alpine:3.21

# ── Pinned versions ──────────────────────────────────────────
ARG TERRAFORM_VERSION=1.7.0
ARG TARGETARCH=amd64

LABEL maintainer="Calix" \
      description="Infra tooling image for Terraform LLM PR Review workflow"

# ── System deps ──────────────────────────────────────────────
RUN apk add --no-cache \
      bash \
      curl \
      wget \
      git \
      unzip \
      ca-certificates \
      openssl \
      jq \
      # Python 3.12 and build deps for pip packages
      python3 \
      py3-pip \
      gcc \
      musl-dev \
      libffi-dev \
      openssl-dev \
      python3-dev

# ── Terraform (pinned to match workflow: terraform_version 1.7.0) ─
RUN wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" \
      -O /tmp/terraform.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/terraform \
    && rm /tmp/terraform.zip \
    && terraform version

# ── Python packages (matches: pip install in workflow) ───────
RUN pip3 install --no-cache-dir --break-system-packages \
      openai \
      requests \
      checkov \
      boto3 \
      pytest

# ── Verify everything is on PATH ─────────────────────────────
RUN terraform version && \
    python3 --version && \
    pip3 show checkov | grep Version && \
    pytest --version

# ── Non-root user for security ───────────────────────────────
RUN addgroup -S runner && adduser -S runner -G runner
USER runner

WORKDIR /workspace
CMD ["/bin/bash"]