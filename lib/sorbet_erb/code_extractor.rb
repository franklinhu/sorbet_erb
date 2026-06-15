# typed: strict
# frozen_string_literal: true

require 'better_html'
require 'better_html/parser'
require 'sorbet-runtime'

module SorbetErb
  class CodeExtractor
    extend T::Sig

    sig do
      params(input: String).returns(
        [T::Array[String], T.nilable(String), T.nilable(String), T.nilable(String)]
      )
    end
    def extract(input)
      buffer = Parser::Source::Buffer.new('(buffer)')
      buffer.source = input
      parser = BetterHtml::Parser.new(buffer)

      p = CodeProcessor.new
      p.process(parser.ast)
      [p.output, p.locals, p.locals_sig, p.controller_class]
    end
  end

  class CodeProcessor
    extend T::Sig
    include AST::Processor::Mixin

    LOCALS_PREFIX = 'locals:'
    LOCALS_SIG_PREFIX = 'locals_sig:'
    CONTROLLER_CLASS_PREFIX = 'controller_class:'

    sig { returns(T::Array[String]) }
    attr_accessor :output

    sig { returns(T.nilable(String)) }
    attr_accessor :locals

    sig { returns(T.nilable(String)) }
    attr_accessor :locals_sig

    sig { returns(T.nilable(String)) }
    attr_accessor :controller_class

    sig { void }
    def initialize
      @output = T.let([], T::Array[String])
      @locals = T.let(nil, T.nilable(String))
      @locals_sig = T.let(nil, T.nilable(String))
      @controller_class = T.let(nil, T.nilable(String))
    end

    sig { params(node: AST::Node).void }
    def handler_missing(node)
      # Some children may be strings, so only look for AST nodes
      children = node.children.select { |c| c.is_a?(BetterHtml::AST::Node) }
      process_all(children)
    end

    sig { params(node: AST::Node).void }
    def on_erb(node)
      indicator_node = node.children.compact.find { |c| c.type == :indicator }
      code_node = node.children.compact.find { |c| c.type == :code }

      return process(code_node) if indicator_node.nil?

      indicator = indicator_node.children.first
      case indicator
      when '#'
        # Ignore comments unless they declare a recognized annotation.
        code_text = code_node.children.first.strip
        if code_text.start_with?(LOCALS_PREFIX)
          # No need to parse the locals
          @locals = code_text.delete_prefix(LOCALS_PREFIX).strip
        elsif code_text.start_with?(LOCALS_SIG_PREFIX)
          @locals_sig = code_text.delete_prefix(LOCALS_SIG_PREFIX).strip
        elsif code_text.start_with?(CONTROLLER_CLASS_PREFIX)
          @controller_class = code_text.delete_prefix(CONTROLLER_CLASS_PREFIX).strip
        end
      else
        process_all(node.children)
      end
    end

    sig { params(node: AST::Node).void }
    def on_code(node)
      @output += node.children
    end
  end
end
