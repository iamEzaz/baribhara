# Multi-stage build for production
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
COPY tsconfig*.json ./
RUN npm ci --only=production && npm cache clean --force

COPY src/ ./src/
RUN npm run build

FROM node:18-alpine AS production
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

COPY --from=builder /app/dist ./dist
RUN chown -R nestjs:nodejs /app
USER nestjs

EXPOSE 3004 50054

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3004/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

CMD ["node", "dist/main.js"]
