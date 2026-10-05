# frozen_string_literal: true

require "date"
require "minitest/autorun"

begin
  require_relative "../../scripts/external_content/catalog"
rescue LoadError
  # The RED run proves feed catalog construction is not implemented.
end

class ExternalContentCatalogTest < Minitest::Test
  AS_OF = Date.new(2026, 10, 4)

  def test_recent_publications_use_exact_calendar_window_and_exclude_year_only_and_theses
    publications = [
      publication("current", 2026, 10),
      publication("window-start", 2025, 11),
      publication("too-old", 2025, 10),
      publication("future", 2026, 11),
      publication("year-only", 2026, nil),
      publication("thesis", 2026, 9, type: "phdthesis")
    ]

    updates = catalog(publications: publications).updates.select { |item| item["category"] == "publication" }

    assert_equal(
      %w[publication:doi:10.1000/current publication:doi:10.1000/window-start],
      updates.map { |item| item.fetch("publication_id") }.sort
    )
  end

  def test_caps_publication_updates_at_five_newest_per_lab
    publications = (1..7).map do |month|
      publication("paper-#{month}", 2026, month)
    end

    updates = catalog(publications: publications).updates.select { |item| item["category"] == "publication" }

    assert_equal 5, updates.length
    assert_equal [7, 6, 5, 4, 3], updates.map { |item| Date.iso8601(item.fetch("date")).month }
  end

  def test_publication_updates_are_month_precise_and_cross_lab_records_are_attributed_per_lab
    shared = publication("shared", 2026, 9, labs: %w[anpl connect], sources: %w[ANPL ConNeCt])

    updates = catalog(publications: [shared]).updates

    assert_equal %w[anpl connect], updates.map { |item| item.fetch("lab_id") }.sort
    updates.each do |item|
      assert_equal "2026-09", item.fetch("published_at")
      assert_equal "2026-09-01", item.fetch("date")
      assert_equal "month", item.fetch("date_precision")
      assert_equal "publication:doi:10.1000/shared", item.fetch("publication_id")
      assert_equal item.fetch("lab_id"), item.fetch("provenance").fetch("lab_id")
    end
  end

  def test_human_update_linking_the_same_doi_or_arxiv_suppresses_only_automatic_update
    human = source_update(
      "anpl:x:1",
      expanded_urls: ["https://doi.org/10.1000/shared", "https://arxiv.org/abs/2601.00001v2"]
    )
    publications = [
      publication("shared", 2026, 9),
      publication("arxiv", 2026, 8, id: "publication:arxiv:2601.00001", canonical: "https://arxiv.org/abs/2601.00001")
    ]

    updates = catalog(source_updates: [human], publications: publications).updates

    assert_equal ["anpl:x:1"], updates.map { |item| item.fetch("id") }
  end

  def test_all_catalogs_are_deterministically_ordered
    publications = [publication("older", 2025, 12), publication("newer", 2026, 1)]
    projects = [{ "id" => "z", "title" => "Zulu" }, { "id" => "a", "title" => "Alpha" }]
    source_updates = [source_update("old", date: "2026-01-01"), source_update("new", date: "2026-02-01")]

    first = catalog(source_updates: source_updates, publications: publications, projects: projects)
    second = catalog(source_updates: source_updates.reverse, publications: publications.reverse, projects: projects.reverse)

    assert_equal first.updates, second.updates
    assert_equal first.publications, second.publications
    assert_equal first.projects, second.projects
    assert_equal %w[Alpha Zulu], first.projects.map { |item| item.fetch("title") }
  end

  private

  def catalog(source_updates: [], publications: [], projects: [])
    catalog_class.new(
      source_updates: source_updates,
      publications: publications,
      projects: projects,
      as_of: AS_OF
    )
  end

  def catalog_class
    assert defined?(PFCL::ExternalContent::Catalog), "PFCL::ExternalContent::Catalog must be defined"
    PFCL::ExternalContent::Catalog
  end

  def publication(name, year, month, type: "article", labs: ["anpl"], sources: ["ANPL"], id: nil, canonical: nil)
    identifier = id || "publication:doi:10.1000/#{name}"
    value = {
      "id" => identifier,
      "title" => name.tr("-", " ").split.map(&:capitalize).join(" "),
      "authors" => ["Researcher, Ada"],
      "year" => year,
      "date_precision" => month ? "month" : "year",
      "publication_type" => type,
      "canonical_url" => canonical || "https://doi.org/10.1000/#{name}",
      "lab_ids" => labs,
      "source_names" => sources,
      "provenance" => labs.map.with_index do |lab, index|
        {
          "repository" => "#{lab}/site",
          "lab_id" => lab,
          "revision" => (index + 1).to_s * 40,
          "source_path" => "publications.bib",
          "source_key" => name
        }
      end.reverse
    }
    value["month"] = month if month
    value
  end

  def source_update(id, date: "2026-09-15", expanded_urls: [])
    {
      "id" => id,
      "title" => "Human update",
      "date" => date,
      "published_at" => date,
      "date_precision" => "day",
      "lab_id" => "anpl",
      "category" => "news",
      "excerpt" => "Human-authored news.",
      "canonical_url" => "https://example.test/news",
      "source_name" => "ANPL",
      "expanded_urls" => expanded_urls,
      "featured" => false,
      "show_on_showcase" => true,
      "display_weight" => 0,
      "provenance" => {
        "repository" => "anpl/site",
        "revision" => "a" * 40,
        "source_path" => "tweets.json"
      }
    }
  end
end
