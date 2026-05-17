# ─────────────────────────────────────────────────────────────
# Personal Infra Tooling Container
# Optimized for: Terraform LLM PR Review workflow
# Base: Alpine 3.21 (active CVE support)
# ─────────────────────────────────────────────────────────────
FROM alpine:3.23.4

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

# ── Infracost (pinned, from release tarball — not GitHub Action) ──
RUN curl -fsSL \
      https://github.com/infracost/infracost/releases/download/v0.10.44/infracost-linux-amd64.tar.gz \
      -o /tmp/infracost.tar.gz \
    && tar -xzf /tmp/infracost.tar.gz -C /tmp \
    && mv /tmp/infracost-linux-amd64 /usr/local/bin/infracost \
    && chmod +x /usr/local/bin/infracost \
    && rm /tmp/infracost.tar.gz \
    && infracost --version

# ── TFLint (pinned to match workflow: tflint_version 0.55.0) ───────────────
RUN curl -fsSL \
      https://github.com/terraform-linters/tflint/releases/download/v0.55.0/tflint_linux_amd64.zip \
      -o /tmp/tflint.zip \
    && unzip /tmp/tflint.zip -d /tmp \
    && mv /tmp/tflint /usr/local/bin/tflint \
    && chmod +x /usr/local/bin/tflint \
    && rm /tmp/tflint.zip \
    && tflint --version

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