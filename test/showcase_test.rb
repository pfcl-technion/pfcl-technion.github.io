# frozen_string_literal: true

require "minitest/autorun"

class ShowcaseTest < Minitest::Test
  def setup
    @root = File.expand_path("..", __dir__)
    @page_path = File.join(@root, "showcase.md")
    @layout_path = File.join(@root, "_layouts", "showcase.html")
    @script_path = File.join(@root, "assets", "js", "showcase.js")
    @style_path = File.join(@root, "_sass", "showcase.scss")
    @qr_lib_path = File.join(@root, "assets", "js", "vendor", "qrcode-generator-1.4.4.min.js")
  end

  def test_showcase_files_exist
    assert File.exist?(@page_path), "Expected showcase.md to exist"
    assert File.exist?(@layout_path), "Expected _layouts/showcase.html to exist"
    assert File.exist?(@script_path), "Expected assets/js/showcase.js to exist"
    assert File.exist?(@style_path), "Expected _sass/showcase.scss to exist"
    assert File.exist?(@qr_lib_path), "Expected vendored assets/js/vendor/qrcode-generator-1.4.4.min.js to exist"
  end

  def test_showcase_page_frontmatter
    skip unless File.exist?(@page_path)
    content = File.read(@page_path)
    assert_match(/^layout:\s*showcase/m, content, "showcase.md must use layout: showcase")
    assert_match(%r{^permalink:\s*/showcase/?}m, content, "showcase.md must have permalink: /showcase/")
  end

  def test_showcase_slide_categories_present
    skip unless File.exist?(@page_path)
    content = File.read(@page_path)
    refute_includes content, "site.labs", "showcase.md must not render research-group lab slides"
    assert_includes content, "site.projects", "showcase.md must iterate over site.projects"
    assert_includes content, "site.data.generated.projects", "showcase.md must iterate over generated projects"
    assert_includes content, "site.news", "showcase.md must iterate over site.news"
    assert_includes content, "site.data.generated.updates", "showcase.md must iterate over generated updates"
    assert_includes content, "show_on_showcase", "showcase.md must filter items by show_on_showcase"
    assert_includes content, "showcase-hero-layer", "showcase.md must include full-bleed hero layers"
    assert_includes content, "showcase-hero-scrim", "showcase.md must include gradient scrims"
  end

  def test_showcase_single_screen_structure
    skip unless File.exist?(@page_path)
    content = File.read(@page_path)
    assert_includes content, "showcase-slider", "showcase.md must use single showcase-slider container"
    assert_includes content, "showcase-slide", "showcase.md must include showcase-slide elements"
    assert_includes content, "showcase-slide-text", "showcase.md must include left text pane"
    assert_includes content, "showcase-slide-visual", "showcase.md must include right visual pane"
    refute_includes content, "showcase-split-container", "showcase.md must NOT use dual-split container"
    refute_includes content, "showcase-column-divider", "showcase.md must NOT include column divider"
  end

  def test_showcase_layout_structure
    skip unless File.exist?(@layout_path)
    content = File.read(@layout_path)
    assert_includes content, "showcase-clock", "showcase layout must include a live clock element"
    assert_includes content, "PFCL-1_edited.png", "showcase layout must include the top center emblem logo"
    assert_includes content, "showcase_qr.png", "showcase layout must include the bottom center website QR code"
    assert_includes content, "logo_aerospace.png", "showcase layout must include the aerospace logo on the left"
    assert_includes content, "Point your camera HERE", "showcase layout must include callout text for the QR code"
    assert_includes content, "showcase.js", "showcase layout must include showcase.js script"
    refute_includes content, "showcase-progress", "showcase layout must NOT include progress bar"
    refute_includes content, "showcase-counter", "showcase layout must NOT include bottom slide counter"
    refute_includes content, "showcase-key-hint", "showcase layout must NOT include keyboard hints"
    refute_includes content, "showcase-pause-status", "showcase layout must NOT include pause control"
    refute_includes content, "{% include header.html %}", "showcase layout must NOT include standard site header"
    refute_includes content, "{% include footer.html %}", "showcase layout must NOT include standard site footer"
  end

  def test_showcase_aerospace_logo_present
    skip unless File.exist?(@layout_path)
    content = File.read(@layout_path)
    assert_includes content, "logo_aerospace.png", "Header left must show logo_aerospace.png"
    assert_includes content, "Faculty of Aerospace Engineering", "Aerospace logo must have descriptive alt text"
    refute_includes content, "showcase-main-title", "Header left must not have text title"
    refute_includes content, "showcase-sub-title", "Header left must not have text subtitle"
  end

  def test_showcase_js_shuffles_and_cycles
    skip unless File.exist?(@script_path)
    content = File.read(@script_path)
    assert_match(/function shuffleSlides/, content, "showcase.js must shuffle slide order at startup")
    assert_match(/function showSlide/, content, "showcase.js must cycle slides")
    refute_includes content, "showcase-progress", "showcase.js must NOT control progress bar"
  end

  def test_showcase_styles_match_site_typography
    skip unless File.exist?(@style_path)
    content = File.read(@style_path)
    assert_includes content, '"Montserrat"', "Showcase body font must match the website's Montserrat"
    assert_includes content, "Inconsolata", "Showcase clock must use the site's monospace stack"
    assert_includes content, "showcase-qr-img", "Showcase styles must style website QR code"
    refute_includes content, "showcase-progress", "Showcase styles must not contain progress bar rules"
  end

  def test_showcase_light_theme_and_sharp_corners
    skip unless File.exist?(@style_path)
    content = File.read(@style_path)
    assert_includes content, "#001b54", "Showcase styles must use #001b54 brand navy"
    assert_includes content, "border-radius: 0", "Showcase styles must enforce sharp corners"
    refute_match(/border-radius:\s*(16px|12px|8px|9999px)/, content, "Showcase styles must not use rounded corners")
  end
end
