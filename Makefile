# ZPA App Connector for GCP — Terratest Makefile
#
# Two invocation styles are supported:
#
# 1. Aggregate per-action targets (mirror terraform-aws-zpa-app-connector-modules):
#       make test                  # all tests in ./test/...
#       make test-validate         # -run TestValidate only
#       make test-plan             # -run TestPlan only
#       make test-apply            # -run TestApply only
#       make test-idempotence      # -run TestIdempotence only
#       make test-clean            # remove .terraform/, lock files, local state
#
# 2. Per-folder action target (mirror terraform-google-swfw-modules; consumed by
#    .github/actions/terratest/action.yml). The folder must contain both a
#    main.tf and a *_test.go (i.e. a directory under ./test/):
#       make test/terraform-zsac-network-gcp ACTION=TestValidate
#       make test/terraform-zpa-complete ACTION=TestApply
#
# Required environment variables for live runs (TestPlan / TestApply / TestIdempotence):
#   ZSCALER_CLIENT_ID, ZSCALER_CLIENT_SECRET, ZSCALER_VANITY_DOMAIN, ZPA_CUSTOMER_ID
#   PROJECT_ID                          (GCP project ID; passed as TF_VAR_project)
#   GOOGLE_APPLICATION_CREDENTIALS     (or any other ADC mechanism)
# Optional:
#   ZSCALER_CLOUD                       (e.g. "beta"; omit for production)
#   REGION                              (defaults to us-central1; passed as TF_VAR_region)

.PHONY: all help install-deps test test-validate test-plan test-apply test-idempotence test-clean invalidate

REGION ?= us-central1

# Export PROJECT_ID and REGION as TF_VAR_* so every test root inherits them
# without needing per-folder tfvars edits.
export TF_VAR_project ?= $(PROJECT_ID)
export TF_VAR_region  ?= $(REGION)

all: help

help:
	@echo "Aggregate targets:"
	@echo "  make test                Run every Test* function under ./test/..."
	@echo "  make test-validate       Run TestValidate only (no GCP/ZPA creds required)"
	@echo "  make test-plan           Run TestPlan only       (creds required)"
	@echo "  make test-apply          Run TestApply only      (creds + cloud spend)"
	@echo "  make test-idempotence    Run TestIdempotence only (creds + cloud spend)"
	@echo "  make test-clean          Remove .terraform/, lock files, local state"
	@echo
	@echo "Per-folder ACTION target (used by .github/actions/terratest/action.yml):"
	@echo "  make test/terraform-zsac-network-gcp ACTION=TestValidate"
	@echo "  make test/terraform-zpa-complete ACTION=TestApply"

install-deps:
	@echo "Installing Go dependencies..."
	go mod tidy
	go mod download

test: install-deps
	@echo "Running all tests..."
	go test ./test/... -v -timeout 90m -count=1

test-validate: install-deps
	@echo "Running TestValidate..."
	go test ./test/... -v -run TestValidate -timeout 30m -count=1

test-plan: install-deps
	@echo "Running TestPlan..."
	go test ./test/... -v -run TestPlan -timeout 60m -count=1

test-apply: install-deps
	@echo "Running TestApply..."
	go test ./test/... -v -run TestApply -timeout 90m -count=1

test-idempotence: install-deps
	@echo "Running TestIdempotence..."
	go test ./test/... -v -run TestIdempotence -timeout 90m -count=1

test-clean:
	@echo "Cleaning up test artifacts..."
	@find ./test -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find ./test -name "terraform.tfstate*" -type f -exec rm -f {} + 2>/dev/null || true
	@find ./test -name ".terraform.lock.hcl" -type f -exec rm -f {} + 2>/dev/null || true

# `invalidate` is a phony prerequisite that forces the path-target rule below
# to re-evaluate every time (Makefile pattern targets normally cache).
invalidate:

# Per-folder ACTION target. Matches both `test/<dir>` and `examples/<dir>`.
# Requires ACTION=<Go test function name>, e.g. ACTION=TestValidate.
%: invalidate %/main.tf
	@if [ -z "$(ACTION)" ]; then \
		echo "ERROR: ACTION is required. Example: make $@ ACTION=TestValidate" ; \
		exit 1 ; \
	fi
	@echo "::group::DOWNLOADING GO DEPENDENCIES"
	@go mod tidy
	@echo "::endgroup::"
	@echo "::group::RUNNING $(ACTION) IN $@"
	@cd $@ && go test -v -run $(ACTION) -timeout 90m -count=1
	@echo "::endgroup::"
