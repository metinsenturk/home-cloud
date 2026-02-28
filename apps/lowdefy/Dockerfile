# Multi-stage Dockerfile for Lowdefy v4
# Stage 1: Build the Lowdefy application from YAML config

FROM node:18-buster AS builder

WORKDIR /lowdefy

# Copy configuration files
COPY config/lowdefy.yaml ./lowdefy.yaml

# Configure Next.js standalone build (reduces image size)
ENV LOWDEFY_BUILD_OUTPUT_STANDALONE=1

# Install pnpm globally (required by Lowdefy)
RUN npm install -g pnpm

# Build the Lowdefy application (converts YAML to Next.js app)
RUN npx --yes lowdefy@4 build --log-level=debug

# Stage 2: Production runtime
FROM node:18-alpine AS runner

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

WORKDIR /lowdefy

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 lowdefy

# Copy built application from builder stage
COPY --from=builder /lowdefy/.lowdefy/server/public ./public
COPY --from=builder --chown=lowdefy:nodejs /lowdefy/.lowdefy/server/.next/standalone ./

# Install wget for healthcheck
RUN apk add --no-cache wget

# Switch to non-root user
USER lowdefy

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
