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
    "projects" => %w[title slug lab_ids recruitment_status project_type
                    advisor_names summary contact_email published updated_at featured show_on_showcase],
    "news" => %w[title date lab_id category excerpt canonical_url source_name featured show_on_showcase]
  }.freeze

  LAB_KINDS = %w[research-group teaching-lab shared-facility].freeze
  TEAM_CATEGORIES = %w[leadership faculty research-fellows research-staff lab-staff visiting emeritus].freeze
  RECRUITMENT_STATUSES = %w[available ongoing completed].freeze
  PROJECT_TYPES = %w[research experimental].freeze
  NEWS_CATEGORIES = %w[news event publication project award position research-highlight].freeze
  RESERVED_LAB_ID = "pfcl"
  UPDATE_REQUIRED_KEYS = %w[id title published_at lab_id category excerpt canonical_url
                            source_name featured show_on_showcase display_weight date
                            date_precision provenance].freeze
  PUBLICATION_REQUIRED_KEYS = %w[id title authors year date_precision publication_type canonical_url
                                 lab_ids source_names provenance].freeze
  GENERATED_PROJECT_REQUIRED_KEYS = %w[id slug title summary lab_ids source_name external thumbnail
                                       canonical_url provenance recruitment_status].freeze
  EXTERNAL_PROJECT_REQUIRED_FIELDS = %w[title slug lab_ids external canonical_url source_name published].freeze
  EXTERNAL_PROJECT_ALLOWED_FIELDS = (EXTERNAL_PROJECT_REQUIRED_FIELDS + %w[layout]).freeze
  INFERRED_PROJECT_FIELDS = %w[project_type contact_email application_url].freeze
  PUBLICATION_TYPES = %w[article inproceedings incollection book phdthesis mastersthesis].freeze

  SLUG_RE = /\A[a-z0-9]+(-[a-z0-9]+)*\z/.freeze
  DATE_RE = /\A\d{4}-\d{2}-\d{2}\z/.freeze
  MONTH_RE = /\A\d{4}-\d{2}\z/.freeze
  REVISION_RE = /\A[0-9a-f]{40}\z/i.freeze

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
    validate_generated_updates(known_labs)
    validate_generated_publications(known_labs)
    validate_generated_projects
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
      required_fields = if name == "projects" && fields.key?("external")
                          EXTERNAL_PROJECT_REQUIRED_FIELDS
                        else
                          REQUIRED_FIELDS[name]
                        end
      required_fields.each do |field|
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
        fields.key?("external") ? validate_external_project(rel, fields, known_labs) : validate_native_project(rel, fields, known_labs)
      when "news"
        check_enum(rel, fields, "category", NEWS_CATEGORIES)
        check_lab_id(rel, fields, "lab_id", known_labs)
        check_date(rel, fields, "date")
        check_canonical(rel, fields)
      end
    end
  end

  def validate_native_project(rel, fields, known_labs)
    check_enum(rel, fields, "recruitment_status", RECRUITMENT_STATUSES)
    check_string_list(rel, fields, "lab_ids", known_labs)
    check_enum(rel, fields, "project_type", PROJECT_TYPES)
    check_string_list(rel, fields, "tags") if fields.key?("tags")
    check_string_or_list(rel, fields, "prerequisites") if fields.key?("prerequisites")
    check_string(rel, fields, "duration") if fields.key?("duration")
    check_string_list(rel, fields, "advisor_names")
    check_url(rel, fields, "application_url")
    check_url(rel, fields, "canonical_url")
    check_date(rel, fields, "updated_at")
    check_thumbnail(rel, fields, "thumbnail")
    if fields["recruitment_status"] == "available" &&
       !present?(fields["contact_email"]) && !present?(fields["application_url"])
      error(rel, "available project needs a public contact path (contact_email or application_url)")
    end
  end

  def validate_external_project(rel, fields, known_labs)
    error(rel, "external must be true") unless fields["external"] == true
    check_string_list(rel, fields, "lab_ids", known_labs)
    error(rel, "external handoff lab_ids must be exactly [anpl]") unless fields["lab_ids"] == ["anpl"]
    check_url(rel, fields, "canonical_url")
    error(rel, "source_name must be a non-empty string") unless fields["source_name"].is_a?(String) && present?(fields["source_name"])
    error(rel, "published must be a boolean") unless [true, false].include?(fields["published"])

    (fields.keys.map(&:to_s) - EXTERNAL_PROJECT_ALLOWED_FIELDS).sort.each do |field|
      error(rel, "field '#{field}' is not allowed for an external project handoff")
    end
  end

  def validate_generated_updates(known_labs)
    validate_generated_array("updates.json", UPDATE_REQUIRED_KEYS) do |item, prefix|
      lab_id = item["lab_id"].to_s
      error(prefix, "unknown lab_id '#{lab_id}'") unless known_labs.include?(lab_id)
      error(prefix, "category '#{item['category']}' is not allowed") unless NEWS_CATEGORIES.include?(item["category"].to_s)
      check_generated_url(prefix, item["canonical_url"])
      if lab_id != RESERVED_LAB_ID && !present?(item["source_name"])
        error(prefix, "imported item needs source_name attribution")
      end
      check_update_date_precision(prefix, item)
      check_provenance(prefix, item["provenance"], multiple: false)
      error(prefix, "display_weight must be numeric") unless item["display_weight"].is_a?(Numeric)
    end
  end

  def validate_generated_publications(known_labs)
    validate_generated_array("publications.json", PUBLICATION_REQUIRED_KEYS) do |item, prefix|
      check_generated_string_list(prefix, item["authors"], "authors")
      check_generated_string_list(prefix, item["lab_ids"], "lab_ids", known_labs)
      check_generated_string_list(prefix, item["source_names"], "source_names")
      check_generated_url(prefix, item["canonical_url"])
      check_publication_date_precision(prefix, item)
      unless PUBLICATION_TYPES.include?(item["publication_type"].to_s)
        error(prefix, "publication_type '#{item['publication_type']}' is not allowed")
      end
      check_provenance(prefix, item["provenance"], multiple: true)
      error(prefix, "publication metadata contains a forbidden PDF field or link") if forbidden_pdf_data?(item)
    end
  end

  def validate_generated_projects
    validate_generated_array("projects.json", GENERATED_PROJECT_REQUIRED_KEYS) do |item, prefix|
      error(prefix, "external must be true") unless item["external"] == true
      error(prefix, "generated project lab_ids may contain only ANPL") unless item["lab_ids"] == ["anpl"]
      error(prefix, "source_name attribution is required") unless present?(item["source_name"])
      error(prefix, "recruitment_status must be 'available'") unless item["recruitment_status"] == "available"
      check_generated_url(prefix, item["canonical_url"])
      check_provenance(prefix, item["provenance"], multiple: false)
      check_generated_thumbnail(prefix, item["thumbnail"])
      inferred = INFERRED_PROJECT_FIELDS.select { |field| item.key?(field) }
      unless inferred.empty?
        error(prefix, "generated project contains inferred field(s): #{inferred.join(', ')}")
      end
    end
  end

  def validate_generated_array(filename, required_keys)
    path = File.join(@site_dir, "_data", "generated", filename)
    return unless File.exist?(path)

    rel = relative_path(path)
    begin
      items = JSON.parse(File.read(path, encoding: "UTF-8"))
    rescue JSON::ParserError => e
      error(rel, "invalid JSON: #{e.message}")
      return
    end
    return error(rel, "expected an array, got #{items.class}") unless items.is_a?(Array)

    ids = {}
    items.each_with_index do |item, index|
      prefix = "#{rel}[#{index}]"
      unless item.is_a?(Hash)
        error(prefix, "expected an object, got #{item.class}")
        next
      end
      required_keys.each do |key|
        error(prefix, "missing required key '#{key}'") unless item.key?(key)
      end
      id = item["id"]
      if !id.is_a?(String) || id.empty?
        error(prefix, "id must be a non-empty string")
      elsif ids.key?(id)
        error(prefix, "duplicate id '#{id}' (also at index #{ids[id]})")
      else
        ids[id] = index
      end
      yield item, prefix
    end
  end

  def check_update_date_precision(prefix, item)
    precision = item["date_precision"].to_s
    date = item["date"].to_s
    published_at = item["published_at"].to_s
    case precision
    when "day"
      valid_date = valid_calendar_date?(date)
      error(prefix, "day precision date must be YYYY-MM-DD") unless valid_date
      begin
        DateTime.iso8601(published_at)
      rescue Date::Error, ArgumentError
        error(prefix, "day precision published_at must be ISO-8601")
        return
      end
      error(prefix, "published_at and date disagree") if valid_date && published_at[0, 10] != date
    when "month"
      valid_month = published_at.match?(MONTH_RE) && valid_calendar_date?("#{published_at}-01")
      error(prefix, "month precision published_at must be YYYY-MM") unless valid_month
      error(prefix, "published_at and date disagree") if valid_month && date != "#{published_at}-01"
    else
      error(prefix, "date_precision '#{precision}' is not allowed")
    end
  end

  def check_publication_date_precision(prefix, item)
    year = item["year"]
    error(prefix, "year must be a four-digit integer") unless year.is_a?(Integer) && year.between?(1000, 9999)
    case item["date_precision"]
    when "year"
      error(prefix, "year precision must not include month") if item.key?("month")
    when "month"
      month = item["month"]
      error(prefix, "month precision requires month 1 through 12") unless month.is_a?(Integer) && month.between?(1, 12)
    else
      error(prefix, "date_precision '#{item['date_precision']}' is not allowed")
    end
  end

  def check_generated_string_list(prefix, value, field, allowed_values = nil)
    unless value.is_a?(Array) && !value.empty? && value.all? { |entry| entry.is_a?(String) && !entry.empty? }
      error(prefix, "#{field} must be a non-empty list of strings")
      return
    end
    return unless allowed_values

    value.each do |entry|
      error(prefix, "unknown lab_id '#{entry}'") unless allowed_values.include?(entry)
    end
  end

  def check_generated_url(prefix, value)
    error(prefix, "canonical_url must be an http(s) URL") unless valid_url?(value)
  end

  def check_generated_thumbnail(prefix, value)
    valid = value.is_a?(String) && (value.start_with?("/assets/") || valid_url?(value))
    error(prefix, "thumbnail must start with '/assets/' or be an http(s) URL") unless valid
  end

  def check_provenance(prefix, value, multiple:)
    entries = if multiple
                value.is_a?(Array) ? value : []
              else
                value.is_a?(Hash) ? [value] : []
              end
    if entries.empty?
      error(prefix, "provenance must be #{multiple ? 'a non-empty array' : 'an object'}")
      return
    end

    entries.each_with_index do |entry, index|
      provenance_prefix = multiple ? "#{prefix}.provenance[#{index}]" : "#{prefix}.provenance"
      unless entry.is_a?(Hash)
        error(provenance_prefix, "must be an object")
        next
      end
      %w[repository revision source_path].each do |field|
        error(provenance_prefix, "missing required key '#{field}'") unless present?(entry[field])
      end
      if present?(entry["revision"]) && !entry["revision"].to_s.match?(REVISION_RE)
        error(provenance_prefix, "revision must be a 40-character Git commit")
      end
    end
  end

  def forbidden_pdf_data?(value)
    case value
    when Hash
      value.any? { |key, nested| key.to_s.casecmp?("pdf") || forbidden_pdf_data?(nested) }
    when Array
      value.any? { |nested| forbidden_pdf_data?(nested) }
    when String
      value.match?(%r{\.pdf(?:\z|[?#])}i) || value.include?("/Publications/")
    else
      false
    end
  end

  def valid_calendar_date?(value)
    return false unless value.match?(DATE_RE)

    Date.iso8601(value)
    true
  rescue Date::Error
    false
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

  def check_string_or_list(rel, fields, field)
    value = fields[field]
    return unless present?(value)

    valid = value.is_a?(String) || (value.is_a?(Array) && value.all? { |v| v.is_a?(String) })
    error(rel, "#{field} must be a string or list of strings") unless valid
  end

  def check_string(rel, fields, field)
    value = fields[field]
    return unless present?(value)

    error(rel, "#{field} must be a string") unless value.is_a?(String)
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
