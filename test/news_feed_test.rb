# frozen_string_literal: true

require "minitest/autorun"
require "jekyll"

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

  def test_social_update_renders_complete_post_once_without_derived_title
    tweet = "Complete ANPL post with research details & a second sentence."
    rendered = render_feed(
      generated_updates: [
        update(
          "content_type" => "social",
          "title" => "Derived duplicate title",
          "excerpt" => tweet,
          "canonical_url" => "https://twitter.com/ANPL_Technion/status/123"
        )
      ]
    )

    assert_equal 1, rendered.scan("Complete ANPL post with research details").length
    refute_includes rendered, "Derived duplicate title"
    assert_includes rendered, "Complete ANPL post with research details &amp; a second sentence."
    assert_includes rendered, "ANPL on X"
  end

  def test_regular_update_keeps_title_and_excerpt_layout
    rendered = render_feed(
      generated_updates: [
        update(
          "title" => "ConNeCt event title",
          "excerpt" => "ConNeCt event summary",
          "source_name" => "ConNeCt",
          "lab_id" => "connect",
          "canonical_url" => "https://connect-lab-technion.github.io/news/event"
        )
      ]
    )

    assert_includes rendered, "ConNeCt event title"
    assert_includes rendered, "ConNeCt event summary"
  end

  private

  def render_feed(generated_updates:)
    site = {
      "news" => [],
      "data" => { "generated" => { "updates" => generated_updates } },
      "labs" => []
    }
    filter_site = Struct.new(:filter_cache).new({})

    Liquid::Template.parse(@template).render!(
      { "site" => site, "include" => { "limit" => 0 } },
      filters: [Jekyll::Filters], registers: { site: filter_site }
    )
  end

  def update(overrides = {})
    {
      "title" => "ANPL update",
      "date" => "2026-09-07",
      "published_at" => "2026-09-07T17:40:50Z",
      "date_precision" => "day",
      "lab_id" => "anpl",
      "excerpt" => "ANPL update text",
      "canonical_url" => "https://twitter.com/ANPL_Technion/status/123",
      "source_name" => "ANPL"
    }.merge(overrides)
  end
end
