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
    assert_includes content, "site.news", "showcase.md must iterate over site.news"
    assert_includes content, "show_on_showcase", "showcase.md must filter items by show_on_showcase"
  end

  def test_showcase_layout_structure
    skip unless File.exist?(@layout_path)
    content = File.read(@layout_path)
    assert_includes content, "showcase-clock", "showcase layout must include a live clock element"
    assert_includes content, "showcase-progress", "showcase layout must include a progress bar"
    assert_includes content, "showcase.js", "showcase layout must include showcase.js script"
    assert_includes content, "qrcode-generator", "showcase layout must load the vendored QR library"
    refute_includes content, "{% include header.html %}", "showcase layout must NOT include standard site header"
    refute_includes content, "{% include footer.html %}", "showcase layout must NOT include standard site footer"
  end

  def test_showcase_subtitle_has_no_technion_suffix
    skip unless File.exist?(@layout_path)
    content = File.read(@layout_path)
    assert_includes content, "Stephen B. Klein Faculty of Aerospace Engineering</p>", "Subtitle must name the faculty"
    refute_includes content, "— Technion", "Subtitle must not repeat '— Technion' (it is in the logo/title context)"
  end

  def test_showcase_slides_carry_qr_urls
    skip unless File.exist?(@page_path)
    content = File.read(@page_path)
    assert_includes content, "data-qr-url", "Slides must expose per-slide QR target URLs"
    assert_includes content, "data-qr-target", "Slides must contain QR render targets"
    assert_includes content, "absolute_url", "QR URLs must be absolute (project pages, relative canonical URLs)"
  end

  def test_showcase_js_shuffles_and_renders_qr
    skip unless File.exist?(@script_path)
    content = File.read(@script_path)
    assert_match(/function shuffleSlides/, content, "showcase.js must shuffle slide order at startup")
    assert_includes content, "data-qr-url", "showcase.js must read per-slide QR URLs"
    assert_includes content, "createSvgTag", "showcase.js must render QR codes as SVG"
  end

  def test_showcase_styles_match_site_typography
    skip unless File.exist?(@style_path)
    content = File.read(@style_path)
    assert_includes content, '"Montserrat"', "Showcase body font must match the website's Montserrat"
    assert_includes content, "Inconsolata", "Showcase clock must use the site's monospace stack"
    assert_match(/\.showcase-qr-img\{?[^}]*height:\s*120px/m, content, "Footer QR must render at 120px (scannable from a distance)")
    refute_includes content, "showcase-lab-logo", "Lab-slide styles must be removed with the category"
  end

  def test_showcase_light_theme_and_sharp_corners
    skip unless File.exist?(@style_path)
    content = File.read(@style_path)
    assert_includes content, "#f8fafc", "Showcase styles must use #f8fafc light canvas surface"
    assert_includes content, "#001b54", "Showcase styles must use #001b54 brand navy"
    assert_includes content, "border-radius: 0", "Showcase styles must enforce sharp corners"
    refute_match(/border-radius:\s*(16px|12px|8px|9999px)/, content, "Showcase styles must not use rounded corners")
  end
end
