#!/usr/bin/env bash
set -euo pipefail

ROOT="moveeasy-core"
ZIPNAME="moveeasy-core.zip"

echo "Creating repo structure at ./${ROOT} ..."

# Remove any existing folder
rm -rf "${ROOT}" "${ZIPNAME}"
mkdir -p "${ROOT}"

# Create directories
mkdir -p "${ROOT}/.github/workflows"
mkdir -p "${ROOT}/infra/k8s"
mkdir -p "${ROOT}/infra/terraform"
mkdir -p "${ROOT}/services/accounts/openapi"
mkdir -p "${ROOT}/services/accounts/src"
mkdir -p "${ROOT}/services/accounts/tests"
mkdir -p "${ROOT}/services/payments/openapi"
mkdir -p "${ROOT}/services/payments/src"
mkdir -p "${ROOT}/services/payments/tests"
mkdir -p "${ROOT}/services/merchant/openapi"
mkdir -p "${ROOT}/services/merchant/src"
mkdir -p "${ROOT}/services/merchant/tests"
mkdir -p "${ROOT}/services/kyc/openapi"
mkdir -p "${ROOT}/services/kyc/src"
mkdir -p "${ROOT}/services/kyc/tests"
mkdir -p "${ROOT}/services/lending/openapi"
mkdir -p "${ROOT}/services/lending/src"
mkdir -p "${ROOT}/services/lending/tests"
mkdir -p "${ROOT}/shared/libs"
mkdir -p "${ROOT}/shared/contracts"
mkdir -p "${ROOT}/ci-scripts"

# README
cat > "${ROOT}/README.md" <<'EOF'
# MoveEasy Core

This repository contains the MoveEasy core platform skeleton:
- OpenAPI specs for Accounts, Payments, Merchant, KYC, Lending
- CI/CD pipeline (GitHub Actions)
- Example Dockerfiles, docker-compose for local sandbox
- CI scripts for SCA, contract tests, and build/push

Use this as the starting point for Reblit or any cloud deployment.
EOF

# GitHub Actions CI
cat > "${ROOT}/.github/workflows/ci-cd.yml" <<'EOF'
name: CI-CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test-and-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Run SCA (npm audit / snyk)
        run: |
          ./ci-scripts/run-sca.sh

      - name: Run unit tests
        run: |
          for d in services/*; do
            if [ -d "$d/tests" ]; then
              (cd $d && if [ -f "./gradlew" ]; then ./gradlew test; elif [ -f "package.json" ]; then npm test; elif [ -d "tests" ]; then pytest -q; fi) || exit 1
            fi
          done

      - name: Run contract tests
        run: ./ci-scripts/run-contract-tests.sh

  build-and-push:
    needs: test-and-scan
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Login to Container Registry
        run: echo "${{ secrets.REGISTRY_PASSWORD }}" | docker login ${{ secrets.REGISTRY_URL }} -u ${{ secrets.REGISTRY_USER }} --password-stdin

      - name: Build and push images
        run: ./ci-scripts/build-and-push.sh
EOF

# infra secrets example
cat > "${ROOT}/infra/secrets.example.env" <<'EOF'
# Example secrets (do NOT commit real secrets)
REGISTRY_URL=registry.example
REGISTRY_USER=ci-user
REGISTRY_PASSWORD=REPLACE_ME
OAUTH_CLIENT_SECRET=REPLACE_ME
POSTGRES_PASSWORD=REPLACE_ME
EOF

# .env.example
cat > "${ROOT}/.env.example" <<'EOF'
# Global
ENV=development
REGION=za-1
LOG_LEVEL=info

# Auth
AUTH_URL=https://auth.moveeasy.example
OAUTH_CLIENT_ID=moveeasy-client
OAUTH_CLIENT_SECRET=REPLACE_ME

# Registry
REGISTRY_URL=registry.example
REGISTRY_USER=ci-user

# KMS
KMS_ENDPOINT=https://kms.example
KMS_KEY_ID=projects/...

# Event store
KAFKA_BROKERS=kafka:9092

# DB
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=moveeasy
POSTGRES_PASSWORD=REPLACE_ME
EOF

# ci-scripts
cat > "${ROOT}/ci-scripts/run-sca.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "Running simple SCA checks..."
# Example: npm audit for Node services
for svc in services/*; do
  if [ -f "$svc/package.json" ]; then
    (cd $svc && npm ci && npm audit --audit-level=high) || true
  fi
done
echo "SCA checks completed."
EOF
chmod +x "${ROOT}/ci-scripts/run-sca.sh"

cat > "${ROOT}/ci-scripts/run-contract-tests.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "Running contract tests (placeholder)..."
# Implement consumer-driven contract tests (Pact or similar)
echo "Contract tests completed."
EOF
chmod +x "${ROOT}/ci-scripts/run-contract-tests.sh"

cat > "${ROOT}/ci-scripts/build-and-push.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

REGISTRY=${REGISTRY_URL:-registry.example}
TAG=${GITHUB_SHA:-local}-$(date +%s)

for svc in services/*; do
  if [ -f "$svc/Dockerfile" ]; then
    name=$(basename $svc)
    docker build -t ${REGISTRY}/moveeasy-${name}:${TAG} $svc
    docker push ${REGISTRY}/moveeasy-${name}:${TAG}
  fi
done
EOF
chmod +x "${ROOT}/ci-scripts/build-and-push.sh"

# Dockerfile template for services
for svc in accounts payments merchant kyc lending; do
  cat > "${ROOT}/services/${svc}/Dockerfile" <<'EOF'
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY package*.json ./
RUN npm ci --production
ENV NODE_ENV=production
EXPOSE 8080
CMD ["node", "dist/index.js"]
EOF
done

# docker-compose
cat > "${ROOT}/docker-compose.yml" <<'EOF'
version: '3.8'
services:
  accounts:
    build: ./services/accounts
    ports:
      - "8081:8080"
    environment:
      - NODE_ENV=development
      - PORT=8080
      - AUTH_URL=http://auth.local
    volumes:
      - ./services/accounts:/app
  payments:
    build: ./services/payments
    ports:
      - "8082:8080"
    environment:
      - NODE_ENV=development
      - LEDGER_URL=http://ledger:9092
  kafka:
    image: confluentinc/cp-kafka:7.4.0
    environment:
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: example
EOF

# Create placeholder tests files
for svc in accounts payments merchant kyc lending; do
  cat > "${ROOT}/services/${svc}/tests/README.md" <<EOF
# Tests for ${svc}
Place unit and integration tests here.
EOF
done

# Shared contracts placeholder
cat > "${ROOT}/shared/contracts/README.md" <<'EOF'
# Consumer-driven contracts
Place Pact or contract definitions here.
EOF

# Now write the OpenAPI YAMLs (accounts)
cat > "${ROOT}/services/accounts/openapi/accounts.yaml" <<'EOF'
openapi: 3.0.3
info:
  title: MoveEasy Accounts API
  version: 1.0.0
  description: Accounts service for MoveEasy. Use OAuth2 Authorization Code with PKCE.
servers:
  - url: https://api.moveeasy.example/v1
components:
  securitySchemes:
    OAuth2:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://auth.moveeasy.example/authorize
          tokenUrl: https://auth.moveeasy.example/token
          scopes:
            accounts.read: Read accounts
            accounts.write: Manage accounts
  schemas:
    Account:
      type: object
      required: [id, tenant_id, owner_id, currency, status]
      properties:
        id:
          type: string
          example: acct_01FZ...
        tenant_id:
          type: string
          example: tenant_123
        owner_id:
          type: string
          example: user_987
        currency:
          type: string
          example: ZAR
        balance:
          type: string
          example: "1250.50"
        available_balance:
          type: string
          example: "1200.50"
        status:
          type: string
          example: ACTIVE
        created_at:
          type: string
          format: date-time
          example: "2026-03-17T08:30:00Z"
    Transaction:
      type: object
      required: [id, account_id, amount, currency, type, created_at]
      properties:
        id:
          type: string
          example: txn_01FZ...
        account_id:
          type: string
          example: acct_01FZ...
        amount:
          type: string
          example: "250.00"
        currency:
          type: string
          example: ZAR
        type:
          type: string
          example: DEBIT
        description:
          type: string
          example: "Payment to merchant"
        idempotency_key:
          type: string
          example: "d4c3b2a1-0001"
        created_at:
          type: string
          format: date-time
          example: "2026-03-17T08:31:00Z"
security:
  - OAuth2: [accounts.read]
paths:
  /accounts:
    get:
      summary: List accounts for tenant or owner
      security:
        - OAuth2: [accounts.read]
      parameters:
        - name: tenant_id
          in: query
          schema:
            type: string
        - name: owner_id
          in: query
          schema:
            type: string
      responses:
        '200':
          description: Accounts list
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Account'
  /accounts:
    post:
      summary: Create account
      security:
        - OAuth2: [accounts.write]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [tenant_id, owner_id, currency]
              properties:
                tenant_id:
                  type: string
                owner_id:
                  type: string
                currency:
                  type: string
      responses:
        '201':
          description: Account created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Account'
  /accounts/{accountId}:
    get:
      summary: Get account
      security:
        - OAuth2: [accounts.read]
      parameters:
        - name: accountId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Account
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Account'
  /accounts/{accountId}/transactions:
    get:
      summary: List transactions
      security:
        - OAuth2: [accounts.read]
      parameters:
        - name: accountId
          in: path
          required: true
          schema:
            type: string
        - name: from
          in: query
          schema:
            type: string
            format: date-time
        - name: to
          in: query
          schema:
            type: string
            format: date-time
      responses:
        '200':
          description: Transaction list
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Transaction'
EOF

echo "Repository structure created at ./${ROOT}"