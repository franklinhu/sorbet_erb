# typed: strict
# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'pathname'
require 'psych'
require 'sorbet-runtime'

require_relative 'sorbet_erb/code_extractor'
require_relative 'sorbet_erb/version'

module SorbetErb
  extend T::Sig

  CONFIG_FILE_NAME = '.sorbet_erb.yml'

  DEFAULT_CONFIG = T.let({
    'input_dirs' => ['app'],
    'exclude_paths' => [],
    'output_dir' => 'sorbet/erb',
    'extra_includes' => [],
    'extra_body' => '',
    'skip_missing_locals' => true
  }.freeze, T::Hash[String, T.untyped])

  USAGE = <<~USAGE
    Usage: sorbet_erb input_dir output_dir
      input_dir - where to scan for ERB files
      output_dir - where to write files with Ruby extracted from ERB
  USAGE

  ERB_TEMPLATE = <<~ERB_TEMPLATE
    # typed: true
    class <%= class_name %><%= extend_app_controller ? " < ApplicationController" : "" %>
      extend T::Sig
      include ActionView::Helpers
      include ApplicationController::HelperMethods
      <% extra_includes.each do |i| %>
        include <%= i %>
      <% end %>

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def local_assigns
        # Shim for typechecking
        {}
      end

      <%= extra_body %>

      <%= locals_sig %>
      def body<%= locals %>
        <% lines.each do |line| %>
          <%= line %>
        <% end %>
      end
    end
  ERB_TEMPLATE

  sig do
    params(
      input_dir: T.nilable(String),
      output_dir: T.nilable(String)
    ).void
  end
  def self.extract_rb_from_erb(input_dir, output_dir)
    config = read_config
    input_dirs =
      if input_dir
        [input_dir]
      else
        config.fetch('input_dirs')
      end
    exclude_paths = config.fetch('exclude_paths')
    output_dir ||= config.fetch('output_dir')
    skip_missing_locals = config.fetch('skip_missing_locals')

    puts 'Clearing output directory'
    FileUtils.rm_rf(output_dir)

    input_dir_to_paths = input_dirs.flat_map do |d|
      Dir.glob(File.join(d, '**', '*.erb')).map do |p|
        [d, p]
      end
    end
    input_dir_to_paths.each do |d, p|
      pathname = Pathname.new(p)

      next if exclude_paths.any? { |p| p.include?(pathname.to_s) }

      extractor = CodeExtractor.new
      lines, locals, locals_sig = extractor.extract(File.read(p))

      # Partials and Turbo streams must use strict locals
      next if requires_defined_locals?(pathname.basename.to_s) && locals.nil? && skip_missing_locals

      locals ||= '()'
      locals_sig ||= ''

      class_name, extend_app_controller = class_name_from_path(pathname)

      rel_output_dir = File.join(
        output_dir,
        pathname.dirname.relative_path_from(d)
      )
      FileUtils.mkdir_p(rel_output_dir)

      output_path = File.join(
        rel_output_dir,
        "#{pathname.basename}.generated.rb"
      )
      erb = ERB.new(ERB_TEMPLATE)
      File.open(output_path, 'w') do |f|
        result = erb.result_with_hash(
          class_name: class_name,
          extend_app_controller: extend_app_controller,
          locals: locals,
          locals_sig: locals_sig,
          extra_includes: config.fetch('extra_includes'),
          extra_body: config.fetch('extra_body'),
          lines: lines
        )
        f.write(result)
      end
    end
  end

  sig { returns(T::Hash[String, T.untyped]) }
  def self.read_config
    path = File.join(Dir.pwd, CONFIG_FILE_NAME)
    config =
      if File.exist?(path)
        Psych.safe_load_file(path)
      else
        {}
      end
    DEFAULT_CONFIG.merge(config)
  end

  sig { params(file_name: String).returns(T::Boolean) }
  def self.requires_defined_locals?(file_name)
    file_name.start_with?('_') || file_name.end_with?('.turbo_stream.erb')
  end

  sig { params(pathname: Pathname).returns([String, T::Boolean]) }
  def self.class_name_from_path(pathname)
    # ViewComponents are stored under app/components, and the partials need access to the instance
    # methods and variables available on the component class, so set the class name to the component
    # class name.
    # TODO: support namespacing
    if pathname.to_s.start_with?('app/components')
      return [
        extract_class_name(pathname).map do |part|
          ActiveSupport::Inflector.camelize(part)
        end.join('::'),
        false
      ]
    end

    # Otherwise make a random class so this doesn't collide with any existing code
    ["SorbetErb#{SecureRandom.hex(6)}", true]
  end

  sig { params(pathname: Pathname).returns(T::Array[String]) }
  def self.extract_class_name(pathname)
    return [] if ['app/components', '.'].include?(pathname.to_s)

    # Strip template suffix
    basename = File.basename(pathname.basename, '.html.erb')

    # We need to handle the cases where the dirname matches the component name, or if there's
    # a namespace
    # `app/components/my_component/my_component.html.erb`
    # `app/components/namespace/my_component/my_component.html.erb`
    dirname = pathname.dirname
    dirname = dirname.dirname if basename.to_s == dirname.basename.to_s

    extract_class_name(dirname) + [basename]
  end

  sig { params(argv: T::Array[String]).void }
  def self.start(argv)
    input = argv[0]
    output = argv[1]

    SorbetErb.extract_rb_from_erb(input, output)
  end
end
