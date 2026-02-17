#!/bin/bash
git pull

bun install --frozen-lockfile

bun run build

bun run ./dist/index.js