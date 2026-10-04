# frozen_string_literal: true

require "minitest/autorun"

class HeroTest < Minitest::Test
  def setup
    @style_path = File.expand_path("../_sass/pfcl.scss", __dir__)
  end

  def test_medium_hero_anchors_text_at_bottom
    skip unless File.exist?(@style_path)
    content = File.read(@style_path)
    medium_block = content[/&\.is-medium\s*\{.*?\n  \}/m]

    refute_nil medium_block, "Expected an &.is-medium block in _sass/pfcl.scss"
    assert_includes medium_block, "justify-content: flex-end", "Medium hero body must anchor its content at the bottom"
    assert_includes medium_block, "margin-top: auto", "Medium hero container must be pushed to the bottom of the banner"
    assert_includes medium_block, "flex-grow: 0", "Medium hero container must not grow (Bulma's .container flex-grow:1 starves margin-top:auto and re-anchors text at the top)"
    refute_includes medium_block, "align-items: center", "Medium hero must not use the legacy top/center anchor"
  end

  def test_small_hero_keeps_compact_top_anchor
    skip unless File.exist?(@style_path)
    content = File.read(@style_path)
    small_block = content[/&\.is-small\s*\{.*?\n  \}/m]

    refute_nil small_block, "Expected an &.is-small block in _sass/pfcl.scss"
    refute_includes small_block, "margin-top: auto", "Small heroes are compact strips and must stay top-anchored"
    refute_includes small_block, "justify-content: flex-end", "Small heroes are compact strips and must stay top-anchored"
  end

  def test_hero_defaults_to_small_height_across_pages
    hero_include = File.read(File.expand_path("../_includes/hero.html", __dir__))
    assert_includes hero_include, "hero_height | default: 'is-small'", "Hero template should default to is-small"
    refute_includes hero_include, "default: 'is-medium'", "Hero template must not default home page to is-medium"
  end
end

