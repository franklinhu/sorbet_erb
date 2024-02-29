# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'

module SorbetErb
  class CodeExtractor
    def initialize
    end

    def extract(input)
      buffer = Parser::Source::Buffer.new('(buffer)')
      buffer.source = input
      parser = BetterHtml::Parser.new(buffer)

      output = ""

      p = CodeProcessor.new
      p.process(parser.ast)
      return p.output
    end
  end

  class CodeProcessor
    include AST::Processor::Mixin

    attr_accessor :output

    def initialize
      @output = []
    end

    def handler_missing(node)
      # Some children may be strings, so only look for AST nodes
      children = node.children.select { |c| c.is_a?(BetterHtml::AST::Node) }
      process_all(children)
    end

    def on_erb(node)
      indicator_node = node.children.compact.find { |c| c.type == :indicator }
      if indicator_node.nil?
        return process_all(node.children)
      end

      indicator = indicator_node.children.first
      case indicator
      when "#"
        # Ignore comments
        return
      else
        process_all(node.children)
      end
    end

    def on_code(node)
      @output += node.children
    end
  end
end

