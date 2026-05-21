FROM node:20-alpine AS build
WORKDIR /app
COPY package.json ./
COPY src ./src
RUN npm pkg delete scripts.dev 2>/dev/null || true

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
COPY --from=build /app/package.json ./
COPY --from=build /app/src ./src
EXPOSE 3000
CMD ["node", "src/server.js"]
