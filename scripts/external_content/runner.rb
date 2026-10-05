# frozen_string_literal: true

require "date"
require "open3"
require "stringio"

require_relative "anpl_adapter"
require_relative "catalog"
require_relative "config"
require_relative "connect_adapter"
require_relative "json_writer"
require_relative "publication_adapter"
require_relative "publication_catalog"

module PFCL
  module ExternalContent
    Result = Data.define(:counts, :warnings, :revisions)

    class Runner
      SOURCE_IDS = %w[anpl connect].freeze

      def self.call(**arguments)
        new(**arguments).call
      end

      def initialize(config_path:, source_roots:, output_dir:, as_of:, revisions: {})
        @config_path = config_path
        @source_roots = stringify_keys(source_roots)
        @output_dir = File.expand_path(output_dir)
        @as_of = as_of
        @supplied_revisions = stringify_keys(revisions)
      end

      def call
        config = Config.load(@config_path)
        roots = SOURCE_IDS.to_h { |id| [id, source_root(id)] }
        revisions = SOURCE_IDS.to_h { |id| [id, revision_for(id, roots.fetch(id))] }
        warnings = StringIO.new

        anpl_source = config.fetch("anpl")
        connect_source = config.fetch("connect")
        anpl = AnplAdapter.new(source: anpl_source, root: roots.fetch("anpl"), revision: revisions.fetch("anpl"))
        connect = ConnectAdapter.new(source: connect_source, root: roots.fetch("connect"), revision: revisions.fetch("connect"))

        source_updates = anpl.updates + connect.updates
        projects = anpl.projects
        publication_sets = [
          PublicationAdapter.new(
            source: anpl_source,
            root: roots.fetch("anpl"),
            revision: revisions.fetch("anpl"),
            as_of: @as_of,
            warn_io: warnings
          ).records,
          PublicationAdapter.new(
            source: connect_source,
            root: roots.fetch("connect"),
            revision: revisions.fetch("connect"),
            as_of: @as_of,
            warn_io: warnings
          ).records
        ]
        publications = PublicationCatalog.merge(publication_sets)
        catalog = Catalog.new(
          source_updates: source_updates,
          publications: publications,
          projects: projects,
          as_of: @as_of
        )

        JsonWriter.write_all(
          File.join(@output_dir, "updates.json") => catalog.updates,
          File.join(@output_dir, "publications.json") => catalog.publications,
          File.join(@output_dir, "projects.json") => catalog.projects
        )

        Result.new(
          counts: {
            "updates" => catalog.updates.length,
            "publications" => catalog.publications.length,
            "projects" => catalog.projects.length
          }.freeze,
          warnings: warnings.string.lines(chomp: true).freeze,
          revisions: revisions.freeze
        )
      end

      private

      def source_root(id)
        value = @source_roots[id]
        raise SourceError, "source root for #{id} is required" if value.nil? || value.to_s.strip.empty?

        root = File.expand_path(value)
        raise SourceError, "source root for #{id} does not exist: #{root}" unless Dir.exist?(root)

        root
      end

      def revision_for(id, root)
        supplied = @supplied_revisions[id]
        revision = supplied || git_revision(root)
        unless revision.match?(/\A[0-9a-f]{40}\z/i)
          raise SourceError, "revision for #{id} must be a 40-character Git commit"
        end

        revision.downcase
      end

      def git_revision(root)
        stdout, stderr, status = Open3.capture3("git", "-C", root, "rev-parse", "HEAD")
        return stdout.strip if status.success?

        raise SourceError, "cannot resolve source revision for #{root}: #{stderr.strip}"
      rescue Errno::ENOENT => e
        raise SourceError, "cannot resolve source revision for #{root}: #{e.message}"
      end

      def stringify_keys(hash)
        hash.to_h { |key, value| [key.to_s, value] }
      end
    end
  end
end
