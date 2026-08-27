#!/usr/bin/env ruby
require "yaml"
require "json"
require "date"
require "uri"

class ContentValidator
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  SLUG_REGEX = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  ALLOWED_LAB_KINDS = %w[research-group teaching-lab shared-facility].freeze
  ALLOWED_TEAM_CATEGORIES = %w[leadership faculty research-staff lab-staff visiting emeritus].freeze
  ALLOWED_RECRUITMENT_STATUSES = %w[available ongoing completed].freeze
  ALLOWED_PROJECT_TYPES = %w[research experimental software hardware teaching].freeze
  ALLOWED_STUDENT_LEVELS = %w[undergraduate master phd].freeze
  ALLOWED_NEWS_CATEGORIES = %w[news event publication project award position research-highlight].freeze

  def initialize(root_dir = ".")
    @root_dir = File.expand_path(root_dir)
  end

  def run
    errors = validate_all
    if errors.empty?
      puts "Content validation passed successfully."
      exit 0
    else
      warn "Content validation failed with #{errors.size} error(s):"
      errors.each { |err| warn "  - #{err}" }
      exit 1
    end
  end

  def validate_all
    errors = []
    known_lab_slugs = ["pfcl"]

    # 1. Parse and validate _labs
    lab_files = Dir[File.join(@root_dir, "_labs", "*.md")]
    lab_slugs_seen = []
    lab_files.each do |file|
      data = parse_frontmatter(file, errors)
      next unless data
      slug = data["slug"]
      if slug && SLUG_REGEX.match?(slug)
        if lab_slugs_seen.include?(slug)
          errors << "#{file}: duplicate lab slug '#{slug}'"
        else
          lab_slugs_seen << slug
          known_lab_slugs << slug
        end
      end
      errors.concat(validate_lab_data(data, file, lab_slugs_seen))
    end

    # 2. Parse and validate _team
    team_files = Dir[File.join(@root_dir, "_team", "*.md")]
    team_slugs_seen = []
    team_files.each do |file|
      data = parse_frontmatter(file, errors)
      next unless data
      errors.concat(validate_team_data(data, file, team_slugs_seen, known_lab_slugs))
    end

    # 3. Parse and validate _projects
    project_files = Dir[File.join(@root_dir, "_projects", "*.md")]
    project_slugs_seen = []
    project_files.each do |file|
      data = parse_frontmatter(file, errors)
      next unless data
      errors.concat(validate_project_data(data, file, project_slugs_seen, known_lab_slugs))
    end

    # 4. Parse and validate _news
    news_files = Dir[File.join(@root_dir, "_news", "*.md")]
    news_files.each do |file|
      data = parse_frontmatter(file, errors)
      next unless data
      errors.concat(validate_news_data(data, file, known_lab_slugs))
    end

    # 5. Validate generated updates JSON
    updates_path = File.join(@root_dir, "_data", "generated", "updates.json")
    if File.exist?(updates_path)
      begin
        updates_data = JSON.parse(File.read(updates_path))
        errors.concat(validate_generated_updates(updates_data))
      rescue JSON::ParserError => e
        errors << "#{updates_path}: invalid JSON (#{e.message})"
      end
    end

    errors
  end

  def parse_frontmatter(file_path, errors)
    content = File.read(file_path)
    if content =~ /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m
      begin
        YAML.safe_load(Regexp.last_match(1), permitted_classes: [Date, Time])
      rescue => e
        errors << "#{file_path}: YAML parsing error: #{e.message}"
        nil
      end
    else
      errors << "#{file_path}: missing YAML frontmatter"
      nil
    end
  end

  def validate_lab_data(data, file, _seen_slugs)
    errs = []
    req_fields = %w[title short_name slug kind leader_names summary website active order]
    req_fields.each do |f|
      errs << "#{file}: missing required field '#{f}'" if data[f].nil? || (data[f].is_a?(String) && data[f].strip.empty?)
    end
    if data["slug"] && !SLUG_REGEX.match?(data["slug"])
      errs << "#{file}: invalid slug '#{data["slug"]}' (must be lowercase alphanumeric and hyphens)"
    end
    if data["kind"] && !ALLOWED_LAB_KINDS.include?(data["kind"])
      errs << "#{file}: invalid kind '#{data["kind"]}'. Allowed: #{ALLOWED_LAB_KINDS.join(", ")}"
    end
    if data["leader_names"] && !data["leader_names"].is_a?(Array)
      errs << "#{file}: 'leader_names' must be an array"
    end
    if data["website"] && !valid_url?(data["website"])
      errs << "#{file}: invalid website URL '#{data["website"]}'"
    end
    if data["email"] && !valid_email?(data["email"])
      errs << "#{file}: invalid email '#{data["email"]}'"
    end
    errs
  end

  def validate_team_data(data, file, seen_slugs, known_lab_slugs)
    errs = []
    req_fields = %w[title slug role category lab_ids active order]
    req_fields.each do |f|
      errs << "#{file}: missing required field '#{f}'" if data[f].nil? || (data[f].is_a?(String) && data[f].strip.empty?)
    end
    if data["slug"]
      if !SLUG_REGEX.match?(data["slug"])
        errs << "#{file}: invalid slug '#{data["slug"]}'"
      elsif seen_slugs.include?(data["slug"])
        errs << "#{file}: duplicate team slug '#{data["slug"]}'"
      else
        seen_slugs << data["slug"]
      end
    end
    if data["category"] && !ALLOWED_TEAM_CATEGORIES.include?(data["category"])
      errs << "#{file}: invalid category '#{data["category"]}'. Allowed: #{ALLOWED_TEAM_CATEGORIES.join(", ")}"
    end
    if data["lab_ids"]
      if !data["lab_ids"].is_a?(Array) || data["lab_ids"].empty?
        errs << "#{file}: 'lab_ids' must be a non-empty array"
      else
        data["lab_ids"].each do |lab_id|
          unless known_lab_slugs.include?(lab_id)
            errs << "#{file}: references unknown lab_id '#{lab_id}'"
          end
        end
      end
    end
    if data["email"] && !valid_email?(data["email"])
      errs << "#{file}: invalid email '#{data["email"]}'"
    end
    errs
  end

  def validate_project_data(data, file, seen_slugs, known_lab_slugs)
    errs = []
    req_fields = %w[title slug lab_ids recruitment_status project_types student_levels advisor_names summary published updated_at]
    req_fields.each do |f|
      errs << "#{file}: missing required field '#{f}'" if data[f].nil? || (data[f].is_a?(String) && data[f].strip.empty?)
    end
    if data["slug"]
      if !SLUG_REGEX.match?(data["slug"])
        errs << "#{file}: invalid slug '#{data["slug"]}'"
      elsif seen_slugs.include?(data["slug"])
        errs << "#{file}: duplicate project slug '#{data["slug"]}'"
      else
        seen_slugs << data["slug"]
      end
    end
    if data["recruitment_status"] && !ALLOWED_RECRUITMENT_STATUSES.include?(data["recruitment_status"])
      errs << "#{file}: invalid recruitment_status '#{data["recruitment_status"]}'. Allowed: #{ALLOWED_RECRUITMENT_STATUSES.join(", ")}"
    end
    if data["recruitment_status"] == "available"
      if data["contact_email"].nil? || data["contact_email"].to_s.strip.empty? || !valid_email?(data["contact_email"])
        errs << "#{file}: available project must have 'contact_email' with a valid email address"
      end
    end
    if data["project_types"]
      if !data["project_types"].is_a?(Array) || data["project_types"].empty?
        errs << "#{file}: 'project_types' must be a non-empty array"
      else
        data["project_types"].each do |pt|
          errs << "#{file}: invalid project_type '#{pt}'" unless ALLOWED_PROJECT_TYPES.include?(pt)
        end
      end
    end
    if data["student_levels"]
      if !data["student_levels"].is_a?(Array) || data["student_levels"].empty?
        errs << "#{file}: 'student_levels' must be a non-empty array"
      else
        data["student_levels"].each do |sl|
          errs << "#{file}: invalid student_level '#{sl}'" unless ALLOWED_STUDENT_LEVELS.include?(sl)
        end
      end
    end
    if data["lab_ids"]
      if !data["lab_ids"].is_a?(Array) || data["lab_ids"].empty?
        errs << "#{file}: 'lab_ids' must be a non-empty array"
      else
        data["lab_ids"].each do |lab_id|
          unless known_lab_slugs.include?(lab_id)
            errs << "#{file}: references unknown lab_id '#{lab_id}'"
          end
        end
      end
    end
    errs
  end

  def validate_news_data(data, file, known_lab_slugs)
    errs = []
    req_fields = %w[title date lab_id category excerpt canonical_url source_name]
    req_fields.each do |f|
      errs << "#{file}: missing required field '#{f}'" if data[f].nil? || (data[f].is_a?(String) && data[f].strip.empty?)
    end
    if data["category"] && !ALLOWED_NEWS_CATEGORIES.include?(data["category"])
      errs << "#{file}: invalid category '#{data["category"]}'. Allowed: #{ALLOWED_NEWS_CATEGORIES.join(", ")}"
    end
    if data["lab_id"] && !known_lab_slugs.include?(data["lab_id"])
      errs << "#{file}: references unknown lab_id '#{data["lab_id"]}'"
    end
    if data["canonical_url"] && !valid_url?(data["canonical_url"])
      errs << "#{file}: invalid canonical_url '#{data["canonical_url"]}'"
    end
    errs
  end

  def validate_generated_updates(updates)
    errs = []
    unless updates.is_a?(Array)
      return ["_data/generated/updates.json: root element must be a JSON array"]
    end
    req_keys = %w[id title published_at lab_id category excerpt canonical_url source_name]
    updates.each_with_index do |item, idx|
      req_keys.each do |k|
        errs << "_data/generated/updates.json[#{idx}]: missing required key '#{k}'" if item[k].nil?
      end
      if item["canonical_url"] && !valid_url?(item["canonical_url"])
        errs << "_data/generated/updates.json[#{idx}]: invalid canonical_url '#{item["canonical_url"]}'"
      end
    end
    errs
  end

  private

  def valid_url?(string)
    uri = URI.parse(string.to_s)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def valid_email?(string)
    EMAIL_REGEX.match?(string.to_s)
  end
end

if __FILE__ == $PROGRAM_NAME
  ContentValidator.new(".").run
end

