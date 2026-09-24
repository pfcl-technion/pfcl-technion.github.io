#!/usr/bin/env ruby
# frozen_string_literal: true

# Validates PFCL collection frontmatter and generated update data.
# Usage: ruby scripts/validate_content.rb [site_dir]
# Exits 1 and prints one "ERROR <file>: <problem>" line per problem.

require "yaml"
require "json"
require "date"

class ContentValidator
  REQUIRED_FIELDS = {
    "labs" => %w[title slug kind leader_names summary active order],
    "team" => %w[title slug role category lab_ids active order],
    "projects" => %w[title slug lab_ids recruitment_status project_types student_levels
                    advisor_names summary contact_email published updated_at featured show_on_showcase],
    "news" => %w[title date lab_id category excerpt canonical_url source_name featured show_on_showcase]
  }.freeze

  LAB_KINDS = %w[research-group teaching-lab shared-facility].freeze
  TEAM_CATEGORIES = %w[leadership faculty research-fellows research-staff lab-staff visiting emeritus].freeze
  RECRUITMENT_STATUSES = %w[available ongoing completed].freeze
  PROJECT_TYPES = %w[research experimental software hardware teaching].freeze
  STUDENT_LEVELS = %w[undergraduate masters phd].freeze
  NEWS_CATEGORIES = %w[news event publication project award position research-highlight].freeze
  RESERVED_LAB_ID = "pfcl"
  UPDATE_REQUIRED_KEYS = %w[id title published_at lab_id category excerpt canonical_url
                            source_name featured show_on_showcase display_weight].freeze

  SLUG_RE = /\A[a-z0-9]+(-[a-z0-9]+)*\z/.freeze
  DATE_RE = /\A\d{4}-\d{2}-\d{2}\z/.freeze

  attr_reader :errors

  def initialize(site_dir)
    @site_dir = site_dir
    @errors = []
    @lab_slugs = []
  end

  def validate
    # First pass: labs, to learn the known lab slugs for lab_ids checks.
    validate_collection("labs")
    known_labs = @lab_slugs + [RESERVED_LAB_ID]
    validate_collection("team", known_labs)
    validate_collection("projects", known_labs)
    validate_collection("news", known_labs)
    validate_updates(known_labs)
    self
  end

  private

  def validate_collection(name, known_labs = nil)
    dir = File.join(@site_dir, "_#{name}")
    return unless Dir.exist?(dir)

    slugs = {}
    Dir.glob(File.join(dir, "**", "*.md")).sort.each do |path|
      rel = relative_path(path)
      doc = read_document(path, rel)
      next unless doc

      fields = doc
      REQUIRED_FIELDS[name].each do |field|
        error(rel, "missing required field '#{field}'") unless present?(fields[field])
      end

      slug = fields["slug"].to_s
      if present?(fields["slug"]) && slug !~ SLUG_RE
        error(rel, "slug '#{slug}' must be lowercase ASCII letters, digits, hyphens")
      end
      if slugs.key?(slug)
        error(rel, "duplicate slug '#{slug}' (also in #{slugs[slug]})")
      else
        slugs[slug] = rel
      end
      @lab_slugs << slug if name == "labs"

      case name
      when "labs"
        check_enum(rel, fields, "kind", LAB_KINDS)
        check_string_list(rel, fields, "leader_names")
        check_url(rel, fields, "website")
        check_url(rel, fields, "faculty_url")
      when "team"
        check_enum(rel, fields, "category", TEAM_CATEGORIES)
        check_string_list(rel, fields, "lab_ids", known_labs)
      when "projects"
        check_enum(rel, fields, "recruitment_status", RECRUITMENT_STATUSES)
        check_string_list(rel, fields, "lab_ids", known_labs)
        check_string_list(rel, fields, "project_types", PROJECT_TYPES)
        check_string_list(rel, fields, "student_levels", STUDENT_LEVELS)
        check_string_list(rel, fields, "advisor_names")
        check_url(rel, fields, "application_url")
        check_url(rel, fields, "canonical_url")
        check_date(rel, fields, "updated_at")
        check_thumbnail(rel, fields, "thumbnail")
        if fields["recruitment_status"] == "available" &&
           !present?(fields["contact_email"]) && !present?(fields["application_url"])
          error(rel, "available project needs a public contact path (contact_email or application_url)")
        end
      when "news"
        check_enum(rel, fields, "category", NEWS_CATEGORIES)
        check_lab_id(rel, fields, "lab_id", known_labs)
        check_date(rel, fields, "date")
        check_canonical(rel, fields)
      end
    end
  end

  def validate_updates(known_labs)
    path = File.join(@site_dir, "_data", "generated", "updates.json")
    return unless File.exist?(path)

    rel = relative_path(path)
    begin
      items = JSON.parse(File.read(path))
    rescue JSON::ParserError => e
      error(rel, "invalid JSON: #{e.message}")
      return
    end
    return error(rel, "expected an array, got #{items.class}") unless items.is_a?(Array)

    items.each_with_index do |item, i|
      prefix = "#{rel}[#{i}]"
      UPDATE_REQUIRED_KEYS.each do |key|
        error(prefix, "missing required key '#{key}'") unless item.is_a?(Hash) && item.key?(key)
      end
      next unless item.is_a?(Hash)

      lab_id = item["lab_id"].to_s
      unless known_labs.include?(lab_id)
        error(prefix, "unknown lab_id '#{lab_id}'")
      end
      unless valid_url?(item["canonical_url"])
        error(prefix, "canonical_url must be an http(s) URL")
      end
      if lab_id != RESERVED_LAB_ID && !present?(item["source_name"])
        error(prefix, "imported item needs source_name attribution")
      end
      begin
        DateTime.parse(item["published_at"].to_s)
      rescue Date::Error, ArgumentError, TypeError
        error(prefix, "published_at must be ISO-8601")
      end
      unless item["display_weight"].is_a?(Numeric)
        error(prefix, "display_weight must be numeric")
      end
    end
  end

  def read_document(path, rel)
    content = File.read(path, encoding: "UTF-8")
    unless content.start_with?("---")
      error(rel, "missing YAML frontmatter")
      return nil
    end
    # Negative limit keeps trailing empty strings, so documents with an empty
    # body still split into [preamble, frontmatter, body].
    parts = content.split(/^---\s*$/, -1)
    if parts.length < 3
      error(rel, "unterminated YAML frontmatter")
      return nil
    end

    begin
      fields = YAML.safe_load(parts[1], permitted_classes: [Date], aliases: false) || {}
    rescue Psych::SyntaxError, Date::Error => e
      error(rel, "invalid YAML: #{e.message}")
      return nil
    end
    fields.is_a?(Hash) ? fields : (error(rel, "frontmatter must be a mapping"); nil)
  end

  def check_enum(rel, fields, field, allowed)
    value = fields[field]
    return unless present?(value)

    error(rel, "#{field} '#{value}' not allowed (use one of: #{allowed.join(', ')})") unless allowed.include?(value.to_s)
  end

  def check_string_list(rel, fields, field, allowed_values = nil)
    value = fields[field]
    return unless value.is_a?(Array)

    value.each do |entry|
      unless entry.is_a?(String) && !entry.strip.empty?
        error(rel, "#{field} entries must be non-empty strings")
        next
      end
      next unless allowed_values && !allowed_values.include?(entry)

      error(rel, "unknown lab_id '#{entry}'") if field == "lab_ids"
      error(rel, "#{field} entry '#{entry}' not allowed") if field != "lab_ids"
    end
  end

  def check_lab_id(rel, fields, field, known_labs)
    value = fields[field]
    return unless present?(value)

    error(rel, "unknown lab_id '#{value}'") unless known_labs.include?(value.to_s)
  end

  def check_url(rel, fields, field)
    value = fields[field]
    return unless present?(value)

    error(rel, "#{field} '#{value}' must be an http(s) URL") unless valid_url?(value)
  end

  def check_date(rel, fields, field)
    value = fields[field]
    return unless present?(value)

    return error(rel, "#{field} must be formatted YYYY-MM-DD") if value.to_s !~ DATE_RE

    Date.parse(value.to_s)
  rescue ArgumentError
    error(rel, "#{field} '#{value}' is not a real calendar date")
  end

  def check_canonical(rel, fields)
    value = fields["canonical_url"]
    return unless present?(value)

    local_ok = fields["lab_id"].to_s == RESERVED_LAB_ID && value.to_s.start_with?("/")
    error(rel, "canonical_url must be an http(s) URL (or a local /path for lab_id 'pfcl')") unless local_ok || valid_url?(value)
  end

  def check_thumbnail(rel, fields, field)
    value = fields[field]
    return unless present?(value)

    valid = value.is_a?(String) && (value.start_with?("/assets/") || valid_url?(value))
    error(rel, "#{field} '#{value}' must start with '/assets/' or be an http(s) URL") unless valid
  end

  def valid_url?(value)
    value.is_a?(String) && value.match?(%r{\Ahttps?://\S+\z})
  end

  def present?(value)
    !(value.nil? || value.to_s.strip.empty?)
  end

  def error(rel, message)
    @errors << "#{rel}: #{message}"
  end

  def relative_path(path)
    path.delete_prefix("#{@site_dir}/")
  end
end

if $PROGRAM_NAME == __FILE__
  validator = ContentValidator.new(ARGV[0] || ".")
  validator.validate
  if validator.errors.empty?
    puts "Content validation passed."
  else
    validator.errors.each { |e| warn "ERROR #{e}" }
    warn "#{validator.errors.size} content validation error(s)."
    exit 1
  end
end
