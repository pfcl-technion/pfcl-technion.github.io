# frozen_string_literal: true

require "minitest/autorun"

class PublicationsPageTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def setup
    @template = File.read(File.join(ROOT, "publications.md"))
  rescue Errno::ENOENT
    @template = ""
  end

  def test_page_groups_generated_publications_by_descending_year
    assert_includes @template, "permalink: /publications/"
    assert_includes @template, "site.data.generated.publications"
    assert_match(/group_by:\s*['\"]year['\"]/, @template)
    assert_match(/sort:.*name.*reverse/m, @template)
    assert_includes @template, "group.name"
  end

  def test_page_renders_metadata_labs_sources_and_external_canonical_link
    %w[publication.authors publication.venue publication.lab_ids publication.source_names publication.canonical_url].each do |expression|
      assert_includes @template, expression
    end
    assert_match(/site\.labs\s*\|\s*where:\s*['\"]slug['\"]/, @template)
    assert_match(/target=["']_blank["']/, @template)
    assert_match(/rel=["']noopener noreferrer["']/, @template)
  end

  def test_every_untrusted_publication_value_is_escaped_and_no_pdf_download_is_offered
    %w[publication.title author_list publication.venue source_name publication.canonical_url].each do |expression|
      assert_match(/#{Regexp.escape(expression)}\s*\|\s*escape/, @template, expression)
    end
    assert_match(/lab\.(?:short_name|title).*\|\s*escape/, @template)
    refute_match(/download|\.pdf/i, @template)
  end

  def test_page_has_a_clear_empty_state
    assert_match(/No publications are available/i, @template)
  end
end
