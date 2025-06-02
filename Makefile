deps: ## Install the dependencies of the backend
	@cabal build --only-dependencies

docs: ## Run mdbook
	@cd doc ; mdbook build

build: ## Build the project in fast mode
	@cabal build

clean: ## Remove compilation artifacts
	@cabal clean

repl: ## Start a REPL
	@cabal repl

test: ## Run the test suite
	@cabal test

lint: ## Run the code linter (HLint)
	@find src -name "*.hs" | xargs -P $(PROCS) -I {} hlint --refactor-options="-i" --refactor {}

style: ## Run the code styler (fourmolu and cabal-fmt)
	@cabal-gild --mode=format --io=masna3.cabal
	@cabal-gild --mode=format --io=cabal.project
	@fourmolu -q --mode inplace src

check:
	@./scripts/ci-check.sh

help: ## Display this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.* ?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

PROCS := $(shell nproc)

.PHONY: all $(MAKECMDGOALS)

.DEFAULT_GOAL := help
