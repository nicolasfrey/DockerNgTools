version: "3.7"

services:
  nodejs:
    build: .docker/node
    restart: "no"
    volumes:
      - ./app:/home/node/app:cached
      - ~/.npmrc:/home/node/.npmrc
