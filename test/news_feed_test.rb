# frozen_string_literal: true

require "minitest/autorun"

class NewsFeedTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def setup
    @template = File.read(File.join(ROOT, "_includes", "news_feed.html"))
  end

  def test_feed_sorts_on_internal_date_and_displays_published_at_by_precision
    assert_match(/sort:\s*['\"]date['\"]/, @template)
    assert_includes @template, "item.date_precision"
    assert_includes @template, "item.published_at"
    assert_includes @template, "%B %Y"
    assert_includes @template, "%B %-d, %Y"
  end

  def test_feed_escapes_external_content_and_keeps_source_attribution
    assert_match(/item\.canonical_url\s*\|\s*escape/, @template)
    assert_match(/item\.title\s*\|\s*escape/, @template)
    assert_match(/item\.excerpt\s*\|\s*escape/, @template)
    assert_match(/source_label\s*\|\s*escape/, @template)
    assert_match(/rel=["']noopener noreferrer["']/, @template)
  end

  def test_month_precision_does_not_render_an_invented_day
    month_branch = @template[/\{%-?\s*if item\.date_precision == ['\"]month['\"].*?\{%-?\s*(?:else|endif)/m]

    refute_nil month_branch
    assert_includes month_branch, "%B %Y"
    refute_includes month_branch, "%B %-d, %Y"
  end
end
