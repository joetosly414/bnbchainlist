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

WORKDIR /opt/app
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

EXPOSE 3000
ENV NODE_ENV=production
ENV PORT=3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:' + (process.env.PORT || 3000), (res) => { process.exit(res.statusCode < 500 ? 0 : 1); }).on('error', () => process.exit(1));"

CMD ["yarn", "start"]
