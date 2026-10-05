# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"

class ProjectsFilterTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SCRIPT = File.join(ROOT, "assets", "js", "projects.js")

  def test_script_exports_a_dom_free_predicate_used_by_the_browser_filter
    source = File.read(SCRIPT)

    assert_includes source, "function matchesProject"
    assert_includes source, "module.exports"
    assert_match(/matchesProject\(project, filters\)/, source)
    assert_match(/matchesProject\(descriptor, filters\)/, source)
    assert_match(/typeof document === ["']undefined["']/, source)
  end

  def test_external_anpl_card_filter_behavior_when_node_is_available
    skip "Node is not installed in this test environment" unless executable?("node")

    javascript = <<~JS
      const filters = require(#{SCRIPT.to_json});
      const project = { labs: ["anpl"], status: [], type: [], text: "autonomous perception" };
      const results = [
        filters.matchesProject(project, { labs: "", status: "", type: "", query: "" }),
        filters.matchesProject(project, { labs: "anpl", status: "", type: "", query: "" }),
        filters.matchesProject(project, { labs: "", status: "available", type: "", query: "" }),
        filters.matchesProject(project, { labs: "", status: "", type: "research", query: "" })
      ];
      process.stdout.write(JSON.stringify(results));
    JS
    stdout, stderr, status = Open3.capture3("node", "-e", javascript)

    assert status.success?, stderr
    assert_equal [true, true, false, false], JSON.parse(stdout)
  end

  private

  def executable?(name)
    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |directory|
      File.file?(File.join(directory, name)) || File.file?(File.join(directory, "#{name}.exe"))
    end
  end
end
