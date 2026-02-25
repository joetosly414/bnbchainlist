FROM node:20-bookworm-slim as builder

ARG COMMIT_SHA
ENV COMMIT_SHA=$COMMIT_SHA

WORKDIR /opt/app

COPY . .
RUN yarn
ENV NODE_ENV production
RUN yarn build

FROM node:20-bookworm-slim

RUN mkdir /mnt/efs

WORKDIR /opt/app
COPY --from=builder /opt/app/.next .next
COPY --from=builder /opt/app/node_modules node_modules
COPY --from=builder /opt/app/package.json package.json
COPY --from=builder /opt/app/yarn.lock yarn.lock
COPY --from=builder /opt/app/public public

EXPOSE 3000

ENV NODE_ENV production

CMD [ "yarn", "start" ]
