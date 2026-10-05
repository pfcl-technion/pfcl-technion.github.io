# frozen_string_literal: true

require "date"
require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

require_relative "../../scripts/external_content/front_matter_document"

begin
  require_relative "../../scripts/external_content/json_writer"
  require_relative "../../scripts/external_content/runner"
rescue LoadError
  # The RED run proves deterministic orchestration and writing are absent.
end

class ExternalContentRunnerTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  FIXTURE_ROOT = File.join(ROOT, "test", "fixtures", "external")
  CONFIG_PATH = File.join(ROOT, "_data", "external_sources.yml")
  AS_OF = Date.new(2026, 10, 4)
  REVISIONS = { "anpl" => "a" * 40, "connect" => "b" * 40 }.freeze

  def test_fixture_pipeline_is_byte_deterministic_and_returns_counts
    Dir.mktmpdir do |dir|
      first = File.join(dir, "first")
      second = File.join(dir, "second")

      first_result = run_pipeline(first)
      second_result = run_pipeline(second)

      %w[updates.json publications.json projects.json].each do |filename|
        assert_equal File.binread(File.join(first, filename)), File.binread(File.join(second, filename)), filename
      end
      assert_operator first_result.counts.fetch("updates"), :>, 0
      assert_operator first_result.counts.fetch("publications"), :>, 0
      assert_operator first_result.counts.fetch("projects"), :>, 0
      assert_equal first_result.counts, second_result.counts
      assert_equal REVISIONS, first_result.revisions
    end
  end

  def test_every_generated_record_has_source_provenance_and_no_pdf_data
    Dir.mktmpdir do |dir|
      run_pipeline(dir)

      %w[updates publications projects].each do |catalog|
        records = JSON.parse(File.read(File.join(dir, "#{catalog}.json")))
        refute_empty records
        records.each do |record|
          raw_provenance = record.fetch("provenance")
          provenance = raw_provenance.is_a?(Array) ? raw_provenance : [raw_provenance]
          refute_empty provenance
          provenance.each do |item|
            assert item.fetch("repository")
            assert_match(/\A[0-9a-f]{40}\z/, item.fetch("revision"))
            assert item.fetch("source_path")
          end
        end
        serialized = JSON.generate(records)
        refute_match(/"pdf"/i, serialized)
        refute_match(/\.pdf/i, serialized)
        refute_includes serialized, "/Publications/"
      end
    end
  end

  def test_source_failures_leave_all_existing_catalogs_unchanged
    mutations = {
      "missing tweets" => ->(root) { FileUtils.rm_f(File.join(root, "anpl", "_data", "tweets.json")) },
      "empty tweets" => ->(root) { File.write(File.join(root, "anpl", "_data", "tweets.json"), "[]") },
      "empty news" => ->(root) { FileUtils.rm(Dir.glob(File.join(root, "connect", "_news", "*.md"))) },
      "empty bibliography" => ->(root) { File.write(File.join(root, "anpl", "_bibliography", "VadimIndelman.bib"), "") },
      "empty projects" => ->(root) { FileUtils.rm(Dir.glob(File.join(root, "anpl", "_student-projects", "*.md"))) }
    }

    mutations.each do |label, mutate|
      Dir.mktmpdir do |dir|
        roots = copy_fixtures(File.join(dir, "sources"))
        output = File.join(dir, "output")
        FileUtils.mkdir_p(output)
        original = seed_catalogs(output)
        mutate.call(File.dirname(roots.fetch("anpl")))

        assert_raises(PFCL::ExternalContent::SourceError, label) do
          runner_class.call(
            config_path: CONFIG_PATH,
            source_roots: roots,
            output_dir: output,
            as_of: AS_OF,
            revisions: REVISIONS
          )
        end
        assert_equal original, read_catalog_bytes(output), label
      end
    end
  end

  def test_json_writer_sorts_hash_keys_and_adds_one_trailing_newline
    Dir.mktmpdir do |dir|
      path = File.join(dir, "value.json")

      writer_class.write(path, [{ "z" => 1, "a" => { "d" => 2, "b" => 3 } }])
      bytes = File.binread(path)

      assert_operator bytes.index('"a"'), :<, bytes.index('"z"')
      assert_operator bytes.index('"b"'), :<, bytes.index('"d"')
      assert bytes.end_with?("\n")
      refute bytes.end_with?("\n\n")
    end
  end

  def test_json_writer_prepares_every_value_before_replacing_destinations
    Dir.mktmpdir do |dir|
      first = File.join(dir, "first.json")
      second = File.join(dir, "second.json")
      File.binwrite(first, "old first\n")
      File.binwrite(second, "old second\n")

      assert_raises(JSON::GeneratorError) do
        writer_class.write_all(first => { "ok" => true }, second => [Float::NAN])
      end

      assert_equal "old first\n", File.binread(first)
      assert_equal "old second\n", File.binread(second)
      assert_empty Dir.children(dir).grep(/\.tmp\z/)
    end
  end

  def test_cli_accepts_explicit_roots_revisions_and_as_of_date
    Dir.mktmpdir do |dir|
      output = File.join(dir, "output")
      command = [
        RbConfig.ruby,
        File.join(ROOT, "scripts", "sync_external_content.rb"),
        "--config", CONFIG_PATH,
        "--anpl-root", File.join(FIXTURE_ROOT, "anpl"),
        "--connect-root", File.join(FIXTURE_ROOT, "connect"),
        "--output-dir", output,
        "--as-of", AS_OF.iso8601,
        "--anpl-revision", REVISIONS.fetch("anpl"),
        "--connect-revision", REVISIONS.fetch("connect")
      ]

      stdout, stderr, status = Open3.capture3(*command, chdir: ROOT)

      assert status.success?, stderr
      assert_includes stdout, "updates="
      assert_includes stdout, REVISIONS.fetch("anpl")
      assert File.file?(File.join(output, "publications.json"))
    end
  end

  private

  def run_pipeline(output_dir)
    runner_class.call(
      config_path: CONFIG_PATH,
      source_roots: {
        "anpl" => File.join(FIXTURE_ROOT, "anpl"),
        "connect" => File.join(FIXTURE_ROOT, "connect")
      },
      output_dir: output_dir,
      as_of: AS_OF,
      revisions: REVISIONS
    )
  end

  def copy_fixtures(destination)
    FileUtils.mkdir_p(destination)
    %w[anpl connect].each { |source| FileUtils.cp_r(File.join(FIXTURE_ROOT, source), destination) }
    { "anpl" => File.join(destination, "anpl"), "connect" => File.join(destination, "connect") }
  end

  def seed_catalogs(output)
    %w[updates publications projects].to_h do |name|
      bytes = "old #{name}\n"
      File.binwrite(File.join(output, "#{name}.json"), bytes)
      [name, bytes]
    end
  end

  def read_catalog_bytes(output)
    %w[updates publications projects].to_h do |name|
      [name, File.binread(File.join(output, "#{name}.json"))]
    end
  end

  def runner_class
    assert defined?(PFCL::ExternalContent::Runner), "PFCL::ExternalContent::Runner must be defined"
    PFCL::ExternalContent::Runner
  end

  def writer_class
    assert defined?(PFCL::ExternalContent::JsonWriter), "PFCL::ExternalContent::JsonWriter must be defined"
    PFCL::ExternalContent::JsonWriter
  end
end
