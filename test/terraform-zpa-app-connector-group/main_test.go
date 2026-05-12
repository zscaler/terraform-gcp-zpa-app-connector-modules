package terraform_zpa_app_connector_group

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// CreateTerraformOptions returns the canonical terratest configuration for this
// fixture. ZPA OneAPI credentials are inherited from the process environment via
// the empty `provider "zpa" {}` block in main.tf.
func CreateTerraformOptions(t *testing.T) *terraform.Options {
	return terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"test.tfvars"},
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
	})
}

// TestValidate runs `terraform init` then `terraform plan` so that schema
// validation, provider download, and remote data-source lookups (e.g. the
// internal "Connector" enrollment cert) are all exercised. We use Plan instead
// of Validate because Validate does not accept VarFiles.
func TestValidate(t *testing.T) {
	opts := CreateTerraformOptions(t)
	terraform.Init(t, opts)
	terraform.Plan(t, opts)
}

// TestPlan is functionally equivalent to TestValidate today; it exists as a
// distinct entry point so CI can split fast vs slow phases per Makefile target.
func TestPlan(t *testing.T) {
	opts := CreateTerraformOptions(t)
	terraform.Init(t, opts)
	terraform.Plan(t, opts)
}

// TestApply provisions a real App Connector Group in the target ZPA tenant,
// verifies the module's outputs, then destroys the resource. Idempotent across
// PRs because random_pet generates a unique name per run.
func TestApply(t *testing.T) {
	opts := CreateTerraformOptions(t)
	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	idValid := terraform.Output(t, opts, "app_connector_group_id_valid")
	assert.Equal(t, "true", idValid, "App Connector Group ID should be valid")

	id := terraform.Output(t, opts, "app_connector_group_id")
	assert.NotEmpty(t, id, "App Connector Group ID should not be empty")
	t.Logf("Created App Connector Group ID: %s", id)
}

// TestIdempotence applies the configuration, then re-applies it and asserts
// that the second apply produces no changes.
func TestIdempotence(t *testing.T) {
	opts := CreateTerraformOptions(t)
	defer terraform.Destroy(t, opts)
	terraform.InitAndApplyAndIdempotent(t, opts)
}
