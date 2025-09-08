# Makefile for Shlink UI Rails
# Docker Compose based development workflow

# デフォルトターゲット
.DEFAULT_GOAL := help

# 変数定義
DOCKER_COMPOSE := docker-compose
WEB_SERVICE := web
CSS_SERVICE := css
DB_SERVICE := db

# 色付きヘルプ出力用の変数
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
RESET := \033[0m

##@ 環境管理

.PHONY: up
up: ## サービス起動（2回目以降）
	@echo "$(BLUE)Starting services...$(RESET)"
	$(DOCKER_COMPOSE) up -d

.PHONY: up-build
up-build: ## サービス起動（初回ビルド付き）
	@echo "$(BLUE)Starting services with build...$(RESET)"
	$(DOCKER_COMPOSE) up --build -d

.PHONY: down
down: ## サービス停止
	@echo "$(BLUE)Stopping services...$(RESET)"
	$(DOCKER_COMPOSE) down

.PHONY: restart
restart: down up ## サービス再起動

.PHONY: logs
logs: ## 全サービスのログ表示
	$(DOCKER_COMPOSE) logs -f

.PHONY: logs-web
logs-web: ## Webサービスのログ表示
	$(DOCKER_COMPOSE) logs -f $(WEB_SERVICE)

.PHONY: logs-css
logs-css: ## CSSサービスのログ表示
	$(DOCKER_COMPOSE) logs -f $(CSS_SERVICE)

##@ 開発支援

.PHONY: console
console: ## Railsコンソール起動
	@echo "$(GREEN)Starting Rails console...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bin/rails console

.PHONY: routes
routes: ## ルート一覧表示
	@echo "$(GREEN)Showing routes...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bin/rails routes

.PHONY: shell
shell: ## Webコンテナにシェル接続
	@echo "$(GREEN)Connecting to web container shell...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) /bin/bash

.PHONY: generate
generate: ## Rails generator実行 (例: make generate ARGS="model User name:string")
	@if [ -z "$(ARGS)" ]; then \
		echo "$(YELLOW)Usage: make generate ARGS=\"generator_name arguments\"$(RESET)"; \
		echo "$(YELLOW)Example: make generate ARGS=\"model User name:string\"$(RESET)"; \
		exit 1; \
	fi
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bin/rails generate $(ARGS)

##@ データベース

.PHONY: db-create
db-create: ## データベース作成
	@echo "$(GREEN)Creating databases...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bin/rails db:create

.PHONY: db-migrate
db-migrate: ## 開発環境マイグレーション実行（Ridgepole）
	@echo "$(GREEN)Running database migration for development...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle exec ridgepole -c config/database.yml -E development --apply -f db/schemas/Schemafile

.PHONY: db-migrate-test
db-migrate-test: ## テスト環境マイグレーション実行（Ridgepole）
	@echo "$(GREEN)Running database migration for test...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle exec ridgepole -c config/database.yml -E test --apply -f db/schemas/Schemafile

.PHONY: db-migrate-all
db-migrate-all: db-migrate db-migrate-test ## 全環境マイグレーション実行

.PHONY: db-reset
db-reset: ## データベース初期化（作成・マイグレーション）
	@echo "$(GREEN)Resetting databases...$(RESET)"
	$(MAKE) db-create
	$(MAKE) db-migrate-all

.PHONY: db-seed
db-seed: ## シードデータ投入
	@echo "$(GREEN)Running database seeds...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bin/rails db:seed

##@ テストと品質管理

.PHONY: test
test: ## 全テスト実行（RSpec）
	@echo "$(GREEN)Running all tests...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle exec rspec

.PHONY: test-system
test-system: ## システムテスト実行
	@echo "$(GREEN)Running system tests...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle exec rspec spec/system

.PHONY: test-models
test-models: ## モデルテスト実行
	@echo "$(GREEN)Running model tests...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle exec rspec spec/models

.PHONY: test-services
test-services: ## サービステスト実行
	@echo "$(GREEN)Running service tests...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle exec rspec spec/services

.PHONY: test-coverage
test-coverage: ## カバレッジ付きテスト実行
	@echo "$(GREEN)Running tests with coverage...$(RESET)"
	$(DOCKER_COMPOSE) exec -e COVERAGE=true $(WEB_SERVICE) bundle exec rspec

.PHONY: test-file
test-file: ## 特定のテストファイル実行 (例: make test-file FILE=spec/models/user_spec.rb)
	@if [ -z "$(FILE)" ]; then \
		echo "$(YELLOW)Usage: make test-file FILE=path/to/spec_file.rb$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Running test file: $(FILE)$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle exec rspec $(FILE)

.PHONY: lint
lint: ## RuboCop実行
	@echo "$(GREEN)Running RuboCop...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle exec rubocop

.PHONY: lint-fix
lint-fix: ## RuboCop自動修正
	@echo "$(GREEN)Running RuboCop with auto-correct...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle exec rubocop -A

.PHONY: security
security: ## Brakemanセキュリティチェック
	@echo "$(GREEN)Running security check with Brakeman...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle exec brakeman

##@ CSS管理

.PHONY: css-build
css-build: ## CSS ビルド
	@echo "$(GREEN)Building CSS...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bin/rails tailwindcss:build

.PHONY: css-watch
css-watch: ## CSS ウォッチ（開発用）
	@echo "$(GREEN)Watching CSS changes...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bin/rails tailwindcss:watch

##@ クリーンアップ

.PHONY: clean
clean: ## 一時ファイル削除
	@echo "$(YELLOW)Cleaning temporary files...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bin/rails tmp:clear
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bin/rails log:clear

.PHONY: clean-all
clean-all: down ## 全データ削除（コンテナ・ボリューム・ネットワーク）
	@echo "$(YELLOW)Removing all containers, volumes, and networks...$(RESET)"
	$(DOCKER_COMPOSE) down -v --remove-orphans
	docker system prune -f

##@ Bundle管理

.PHONY: bundle-install
bundle-install: ## Bundler install実行
	@echo "$(GREEN)Running bundle install...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle install

.PHONY: bundle-update
bundle-update: ## Bundler update実行
	@echo "$(GREEN)Running bundle update...$(RESET)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bundle update

##@ セットアップ

.PHONY: setup
setup: up-build db-reset bundle-install css-build ## 初回セットアップ（ビルド・DB・Bundle・CSS）
	@echo "$(GREEN)Setup completed! You can now access the application at http://localhost:3000$(RESET)"

.PHONY: setup-quick
setup-quick: up db-migrate-all ## クイックセットアップ（既存コンテナ使用）
	@echo "$(GREEN)Quick setup completed!$(RESET)"

##@ ヘルプ

.PHONY: help
help: ## 使用可能なコマンド一覧を表示
	@awk 'BEGIN {FS = ":.*##"; printf "\n$(BLUE)Shlink UI Rails - Development Commands$(RESET)\n\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(BLUE)Examples:$(RESET)"
	@echo "  make setup                    # 初回セットアップ"
	@echo "  make up                       # サービス起動"
	@echo "  make test                     # 全テスト実行"
	@echo "  make test-file FILE=spec/models/user_spec.rb  # 特定ファイルテスト"
	@echo "  make generate ARGS=\"model User name:string\"   # Rails generator"
	@echo ""

##@ その他

.PHONY: status
status: ## サービス状態確認
	@echo "$(BLUE)Service status:$(RESET)"
	$(DOCKER_COMPOSE) ps

.PHONY: stats
stats: ## リソース使用状況確認
	@echo "$(BLUE)Resource usage:$(RESET)"
	$(DOCKER_COMPOSE) top