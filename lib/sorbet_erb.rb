# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'pathname'
require 'psych'

require_relative 'sorbet_erb/code_extractor'
require_relative 'sorbet_erb/version'

module SorbetErb
  CONFIG_FILE_NAME = '.sorbet_erb.yml'

  DEFAULT_CONFIG = {
    'input_dirs' => ['app'],
    'output_dir' => 'sorbet/erb',
    'extra_includes' => [],
    'extra_body' => '',
  }

  USAGE = <<~USAGE
    Usage: sorbet_erb input_dir output_dir
      input_dir - where to scan for ERB files
      output_dir - where to write files with Ruby extracted from ERB
  USAGE

  ERB_TEMPLATE = <<~ERB_TEMPLATE
    # typed: true
    class SorbetErb<%= class_suffix %> < ApplicationController
      include ActionView::Helpers
      include ApplicationController::HelperMethods
      <% extra_includes.each do |i| %>
        include <%= i %>
      <% end %>

      <%= extra_body %>

      def body<%= locals %>
        <% lines.each do |line| %>
          <%= line %>
        <% end %>
      end
    end
  ERB_TEMPLATE

  def self.extract_rb_from_erb(input_dir, output_dir)
    config = read_config
    input_dirs =
      if input_dir
        [input_dir]
      else
        config.fetch('input_dirs')
      end
    output_dir ||= config.fetch('output_dir')

    puts 'Clearing output directory'
    FileUtils.rm_rf(output_dir)

    paths = input_dirs.flat_map do |d|
      Dir.glob(File.join(path, '**', '*.erb'))
    end
    paths.each do |p|
      puts "Processing #{p}"
      pathname = Pathname.new(p)

      extractor = CodeExtractor.new
      lines, locals = extractor.extract(File.read(p))

      next if pathname.basename.to_s.start_with?('_') && locals.nil?

      # Partials must use strict locals

      locals ||= '()'

      rel_output_dir = File.join(
        output_dir,
        pathname.dirname.relative_path_from(path)
      )
      FileUtils.mkdir_p(rel_output_dir)

      output_path = File.join(
        rel_output_dir,
        "#{pathname.basename}.generated.rb"
      )
      erb = ERB.new(ERB_TEMPLATE)
      File.open(output_path, 'w') do |f|
        result = erb.result_with_hash(
          class_suffix: SecureRandom.hex(6),
          locals: locals,
          extra_includes: config.fetch('extra_includes']),
          extra_body: config.fetch('extra_body'),
          lines: lines
        )
        f.write(result)
      end
    end
  end

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

  def self.start(argv)
    input = argv[0]
    output = argv[1]

    SorbetErb.extract_rb_from_erb(input, output)
  end
end
