# frozen_string_literal: true

require 'fileutils'

require_relative "sorbet_erb/code_extractor"
require_relative "sorbet_erb/version"

module SorbetErb
  def self.extract_rb_from_erb(path, output_dir)
    puts "Extracting ruby from erb: #{path} -> #{output_dir}"
    Dir.glob(File.join(path, "**", "*.erb")).each do |p|
      puts "Processing #{p}"
      pathname = Pathname.new(p)

      extractor = CodeExtractor.new
      lines, locals = extractor.extract(File.read(p))

      rel_output_dir = File.join(
        output_dir,
        pathname.dirname.relative_path_from(path),
      )
      FileUtils.mkdir_p(rel_output_dir)

      output_path = File.join(
        rel_output_dir,
        "#{pathname.basename}.generated.rb",
      )
      File.open(output_path, "w") do |f|
        # TODO: put this in an ERB template
        f.write("# typed: true\n")
        f.write("class SorbetErb#{SecureRandom.hex(6)} < ActionController::Base\n")

        f.write("  include ActionView::Helpers::ActiveModelHelper\n")
        f.write("  include ActionView::Helpers::AssetTagHelper\n")
        f.write("  include ActionView::Helpers::AssetUrlHelper\n")
        f.write("  include ActionView::Helpers::AtomFeedHelper\n")
        f.write("  include ActionView::Helpers::CacheHelper\n")
        f.write("  include ActionView::Helpers::CaptureHelper\n")
        f.write("  include ActionView::Helpers::ContentExfiltrationPreventionHelper\n")
        f.write("  include ActionView::Helpers::CspHelper\n")
        f.write("  include ActionView::Helpers::CsrfHelper\n")
        f.write("  include ActionView::Helpers::DateHelper\n")
        f.write("  include ActionView::Helpers::DebugHelper\n")
        f.write("  include ActionView::Helpers::FormHelper\n")
        f.write("  include ActionView::Helpers::FormOptionsHelper\n")
        f.write("  include ActionView::Helpers::FormTagHelper\n")
        f.write("  include ActionView::Helpers::JavaScriptHelper\n")
        f.write("  include ActionView::Helpers::NumberHelper\n")
        f.write("  include ActionView::Helpers::OutputSafetyHelper\n")
        f.write("  include ActionView::Helpers::RenderingHelper\n")
        f.write("  include ActionView::Helpers::SanitizeHelper\n")
        f.write("  include ActionView::Helpers::TagHelper\n")
        f.write("  include ActionView::Helpers::TextHelper\n")
        f.write("  include ActionView::Helpers::TranslationHelper\n")
        f.write("  include ActionView::Helpers::UrlHelper\n")
        f.write("  include GeneratedPathHelpersModule\n")
        f.write("  def body#{locals}\n")
        lines.each do |line|
          f.write(line)
          f.write("\n")
        end
        f.write("  end\n")
        f.write("end\n")
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  input = ARGV[0]
  output = ARGV[1]
  SorbetErb.extract_rb_from_erb(input, output)
end

