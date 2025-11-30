# Stage 1: Build the MCP server
FROM node:lts-alpine AS builder
WORKDIR /app

# Copy package files and install dependencies
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

# Copy TypeScript configuration and source
COPY tsconfig.json ./
COPY src ./src

# Build the TypeScript source
RUN npm run build

# Stage 2: Runtime with MCPO proxy
FROM python:3.11-alpine
WORKDIR /app

# Install Node.js runtime (needed to run the MCP server)
RUN apk add --no-cache nodejs npm

# Install MCPO
RUN pip install --no-cache-dir mcpo

# Copy built MCP server from builder
COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# Create non-root user
RUN addgroup -g 1001 nodejs && \
    adduser -D -u 1001 -G nodejs postgres-mcp && \
    chown -R postgres-mcp:nodejs /app

USER postgres-mcp

# Expose HTTP port for MCPO
EXPOSE 8080

# Start MCPO wrapping the MCP server
# MCPO will handle HTTP requests and proxy to the stdio-based MCP server
ENTRYPOINT ["mcpo"]
CMD ["--port", "8080", "--host", "0.0.0.0", "--", "node", "build/index.js"]
