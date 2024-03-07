# frozen_string_literal: true

require 'erb'
require 'fileutils'

require_relative "sorbet_erb/code_extractor"
require_relative "sorbet_erb/version"

module SorbetErb

  ERB_TEMPLATE = <<~END
    # typed: true
    class SorbetErb<%= class_suffix %> < ApplicationController
      include ApplicationController::HelperMethods

      def body<%= locals %>
        <% lines.each do |line| %>
          <%= line %>
        <% end %>
      end
    end
  END

  def self.extract_rb_from_erb(path, output_dir)
    puts "Clearing output directory"
    FileUtils.rm_rf(output_dir)

    puts "Extracting ruby from erb: #{path} -> #{output_dir}"
    Dir.glob(File.join(path, "**", "*.erb")).each do |p|
      puts "Processing #{p}"
      pathname = Pathname.new(p)

      extractor = CodeExtractor.new
      lines, locals = extractor.extract(File.read(p))

      if pathname.basename.to_s.start_with?("_") && locals.nil?
        # Partials must use strict locals
        next
      else
        locals ||= "()"
      end

      rel_output_dir = File.join(
        output_dir,
        pathname.dirname.relative_path_from(path),
      )
      FileUtils.mkdir_p(rel_output_dir)

      output_path = File.join(
        rel_output_dir,
        "#{pathname.basename}.generated.rb",
      )
      erb = ERB.new(ERB_TEMPLATE)
      File.open(output_path, "w") do |f|
        result = erb.result_with_hash(
          class_suffix: SecureRandom.hex(6),
          locals: locals,
          lines: lines,
        )
        f.write(result)
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  input = ARGV[0]
  output = ARGV[1]
  SorbetErb.extract_rb_from_erb(input, output)
end

