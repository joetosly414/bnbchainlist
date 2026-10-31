FROM node:14 AS deps

WORKDIR /opt/app
COPY package.json yarn.lock* ./
RUN yarn install --frozen-lockfile --non-interactive

FROM node:14 AS builder

ARG COMMIT_SHA
ENV COMMIT_SHA=${COMMIT_SHA}
WORKDIR /opt/app

COPY --from=deps /opt/app/node_modules ./node_modules
COPY . .
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
RUN yarn build

ARG STATIC_BUCKET=""
ENV STATIC_BUCKET=${STATIC_BUCKET}
RUN if [ -n "${STATIC_BUCKET}" ]; then \
      apt-get update \
      && apt-get install -y --no-install-recommends awscli \
      && aws s3 cp /opt/app/.next/static s3://${STATIC_BUCKET}/static/_next/static --recursive --cache-control "private, max-age=31536000" \
      && aws s3 cp /opt/app/public s3://${STATIC_BUCKET}/static --recursive --cache-control "private, max-age=31536000"; \
    fi

FROM node:14 AS runner

ARG APP_PORT=3000
WORKDIR /opt/app

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    HOSTNAME=0.0.0.0 \
    PORT=${APP_PORT}

RUN groupadd --system app && useradd --system --gid app --create-home --home-dir /home/app app \
    && mkdir -p /mnt/efs \
    && chown -R app:app /opt/app /mnt/efs

COPY --from=builder /opt/app/package.json ./package.json
COPY --from=builder /opt/app/yarn.lock ./yarn.lock
COPY --from=builder /opt/app/node_modules ./node_modules
COPY --from=builder /opt/app/.next ./.next
COPY --from=builder /opt/app/public ./public
COPY --from=builder /opt/app/public/connectors ./public/connectors

USER app

EXPOSE ${APP_PORT}

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "const http = require('http'); const port = process.env.PORT || 3000; const req = http.get({ host: '127.0.0.1', port, path: '/' }, (res) => process.exit(res.statusCode < 500 ? 0 : 1)); req.on('error', () => process.exit(1));"

CMD ["sh", "-lc", "next start -H ${HOSTNAME:-0.0.0.0} -p ${PORT:-3000}"]
