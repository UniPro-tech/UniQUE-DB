#!/bin/bash
set -e

# 1. git clone
git clone https://github.com/UniPro-tech/UniQUE-DB.git
cd UniQUE-DB

# 2. 最新タグ取得
latest_tag=$(git describe --tags --abbrev=0)
git checkout "$latest_tag"

# 3. migration up
export DATABASE_URL="mysql://user:pass@tcp(host:3306)/dbname?multiStatements=true"
export MIGRATIONS_DIR="./migrations"
migrate -path "$MIGRATIONS_DIR" -database "$DATABASE_URL" up