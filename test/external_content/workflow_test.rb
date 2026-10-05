# frozen_string_literal: true

require "minitest/autorun"

class ExternalContentWorkflowTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  def setup
    @workflow = File.read(File.join(ROOT, ".github", "workflows", "pages.yml"))
  end

  def test_keeps_push_and_manual_triggers_and_adds_off_hour_daily_schedule
    assert_match(/^on:\s*$/m, @workflow)
    assert_match(/^  push:\s*$/m, @workflow)
    assert_match(/^  workflow_dispatch:\s*$/m, @workflow)
    assert_match(/^  schedule:\s*\n\s*- cron:\s*["']17 3 \* \* \*["']/m, @workflow)
  end

  def test_anpl_checkout_is_shallow_read_only_and_uses_only_allowlisted_paths
    block = step_block("Checkout ANPL source")

    assert_includes block, "repository: anpl-technion/anpl-technion.github.io"
    assert_includes block, "path: external/anpl"
    assert_includes block, "fetch-depth: 1"
    assert_includes block, "persist-credentials: false"
    assert_includes block, "sparse-checkout-cone-mode: false"
    assert_sparse_paths block, %w[_data/tweets.json _bibliography/VadimIndelman.bib _student-projects]
  end

  def test_connect_checkout_is_shallow_read_only_and_uses_only_allowlisted_paths
    block = step_block("Checkout ConNeCt source")

    assert_includes block, "repository: Connect-Lab-Technion/Connect-Lab-Technion.github.io"
    assert_includes block, "path: external/connect"
    assert_includes block, "fetch-depth: 1"
    assert_includes block, "persist-credentials: false"
    assert_includes block, "sparse-checkout-cone-mode: false"
    assert_sparse_paths block, %w[_news _bibliography/DZ_Complete.bib]
  end

  def test_sync_validate_complete_tests_and_build_run_in_that_order
    sync = @workflow.index("scripts/sync_external_content.rb")
    validation = @workflow.index("scripts/validate_content.rb")
    tests = @workflow.index("Dir.glob('test/**/*_test.rb').sort")
    build = @workflow.index("jekyll build --trace")

    refute_nil sync
    refute_nil validation
    refute_nil tests
    refute_nil build
    assert_operator validation, :>, sync
    assert_operator tests, :>, validation
    assert_operator build, :>, tests
    assert_includes @workflow, "--anpl-root external/anpl"
    assert_includes @workflow, "--connect-root external/connect"
    assert_includes @workflow, "--output-dir _data/generated"
  end

  def test_deployment_requires_the_successful_build_job
    deploy = @workflow[/^  deploy:\s*$.*\z/m]

    refute_nil deploy
    assert_match(/^    needs: build\s*$/m, deploy)
    assert_includes deploy, "actions/deploy-pages@v4"
  end

  private

  def step_block(name)
    block = @workflow[/^      - name: #{Regexp.escape(name)}\s*$.*?(?=^      - (?:name:|uses:)|^  \w|\z)/m]
    refute_nil block, "missing workflow step #{name.inspect}"
    block
  end

  def assert_sparse_paths(block, expected)
    value = block[/sparse-checkout:\s*\|\s*\n((?:\s{10,}.+\n?)+)/, 1].to_s
    paths = value.lines.map(&:strip).reject(&:empty?)
    assert_equal expected, paths
  end
end
