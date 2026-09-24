# frozen_string_literal: true

require "minitest/autorun"

class ShowcaseTest < Minitest::Test
  def setup
    @root = File.expand_path("..", __dir__)
    @page_path = File.join(@root, "showcase.md")
    @layout_path = File.join(@root, "_layouts", "showcase.html")
    @script_path = File.join(@root, "assets", "js", "showcase.js")
    @style_path = File.join(@root, "_sass", "showcase.scss")
  end

  def test_showcase_files_exist
    assert File.exist?(@page_path), "Expected showcase.md to exist"
    assert File.exist?(@layout_path), "Expected _layouts/showcase.html to exist"
    assert File.exist?(@script_path), "Expected assets/js/showcase.js to exist"
    assert File.exist?(@style_path), "Expected _sass/showcase.scss to exist"
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
    assert_includes content, "site.labs", "showcase.md must iterate over site.labs"
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
    refute_includes content, "{% include header.html %}", "showcase layout must NOT include standard site header"
    refute_includes content, "{% include footer.html %}", "showcase layout must NOT include standard site footer"
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
