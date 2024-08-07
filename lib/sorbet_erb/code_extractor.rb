# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'

module SorbetErb
  class CodeExtractor
    def initialize; end

    def extract(input)
      buffer = Parser::Source::Buffer.new('(buffer)')
      buffer.source = input
      parser = BetterHtml::Parser.new(buffer)

      p = CodeProcessor.new
      p.process(parser.ast)
      [p.output, p.locals, p.locals_sig]
    end
  end

  class CodeProcessor
    include AST::Processor::Mixin

    LOCALS_PREFIX = 'locals:'
    LOCALS_SIG_PREFIX = 'locals_sig:'

    attr_accessor :output, :locals, :locals_sig

    def initialize
      @output = []
      @locals = nil
      @locals_sig = nil
    end

    def handler_missing(node)
      # Some children may be strings, so only look for AST nodes
      children = node.children.select { |c| c.is_a?(BetterHtml::AST::Node) }
      process_all(children)
    end

    def on_erb(node)
      indicator_node = node.children.compact.find { |c| c.type == :indicator }
      code_node = node.children.compact.find { |c| c.type == :code }

      return process(code_node) if indicator_node.nil?

      indicator = indicator_node.children.first
      case indicator
      when '#'
        # Ignore comments if it's not strict locals
        code_text = code_node.children.first.strip
        if code_text.start_with?(LOCALS_PREFIX)
          # No need to parse the locals
          @locals = code_text.delete_prefix(LOCALS_PREFIX).strip
        elsif code_text.start_with?(LOCALS_SIG_PREFIX)
          @locals_sig = code_text.delete_prefix(LOCALS_SIG_PREFIX).strip
        end
      else
        process_all(node.children)
      end
    end

    def on_code(node)
      @output += node.children
    end
  end
end
