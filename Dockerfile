# syntax=docker/dockerfile:1

FROM node:lts-alpine as base
RUN npm install -g pnpm@9.5.0

FROM base as deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package*.json pnpm-lock.yaml ./
RUN pnpm install

FROM base as builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm build

FROM base as runtime
ENV NODE_ENV=production
ENV PAYLOAD_CONFIG_PATH=dist/payload.config.js
WORKDIR /app
COPY package.json ./
RUN pnpm install --prod
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/build ./build
EXPOSE 8000

# Add image to GitHub repository
LABEL org.opencontainers.image.source="https://github.com/ab7z/cms"

CMD node dist/server.js
