# frozen_string_literal: true

require 'test_helper'

# ViewComponent must be required before the compiler class
require 'view_component'
require 'view_component/slotable'
require 'rails'
require_relative '../lib/tapioca/dsl/compilers/view_component_slotables'

require 'rubygems/user_interaction'
require 'tapioca/internal'
require 'tapioca/helpers/test/content'
require 'tapioca/helpers/test/dsl_compiler'

class TapiocaViewComponentSlotablesCompilerTest < Minitest::Spec
  include Tapioca::Helpers::Test::DslCompiler

  before do
    use_dsl_compiler(Tapioca::Dsl::Compilers::ViewComponentSlotables)
  end

  describe 'gather_constants' do
    it 'gathers no constants if there are no ViewComponent classes' do
      add_ruby_file('test_component.rb', <<~CONTENT)
      CONTENT
      assert_empty(Tapioca::Dsl::Compilers::ViewComponentSlotables.gather_constants)
    end

    it 'gathers constants with ViewComponent module' do
      add_ruby_file('test_component.rb', <<~CONTENT)
        class TestComponent < ViewComponent::Base
        end
      CONTENT

      constants = Tapioca::Dsl::Compilers::ViewComponentSlotables.gather_constants
      assert_equal(1, constants.count)
      assert_equal('TestComponent', constants.first.name)
    end
  end

  describe 'decorate' do
    it 'generates empty RBI if there are no slots' do
      add_ruby_file('test_component.rb', <<~CONTENT)
        class TestComponent < ViewComponent::Base
        end
      CONTENT

      expected = <<~RBI
        # typed: strong

        class TestComponent; end
      RBI

      assert_equal(expected, rbi_for(:TestComponent))
    end

    it 'generates method sigs for every view component slot' do
      add_ruby_file('test_component.rb', <<~CONTENT)
        class TestComponent < ViewComponent::Base
          renders_one :parent
          renders_many :children
        end
      CONTENT

      expected = <<~RBI
        # typed: strong

        class TestComponent
          include ViewComponentSlotablesMethodsModule

          module ViewComponentSlotablesMethodsModule
            sig { returns(T::Enumerable[T.untyped]) }
            def children; end

            sig { returns(T::Boolean) }
            def children?; end

            sig { returns(T.untyped) }
            def parent; end

            sig { returns(T::Boolean) }
            def parent?; end

            sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
            def with_child(*args, &block); end

            sig { params(content: T.untyped).returns(T.untyped) }
            def with_child_content(content); end

            sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
            def with_children(*args, &block); end

            sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
            def with_parent(*args, &block); end

            sig { params(content: T.untyped).returns(T.untyped) }
            def with_parent_content(content); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:TestComponent))
    end

    it 'generates method sigs with param types when type set on slot' do
      add_ruby_file('test_component.rb', <<~CONTENT)
        class TestComponent < ViewComponent::Base
          class ParentType < ViewComponent::Base; end
          renders_one :parent, ParentType
        end
      CONTENT

      expected = <<~RBI
        # typed: strong

        class TestComponent
          include ViewComponentSlotablesMethodsModule

          module ViewComponentSlotablesMethodsModule
            sig { returns(TestComponent::ParentType) }
            def parent; end

            sig { returns(T::Boolean) }
            def parent?; end

            sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
            def with_parent(*args, &block); end

            sig { params(content: T.untyped).returns(T.untyped) }
            def with_parent_content(content); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:TestComponent))
    end

    it 'generates method sigs with param types when type is a proc' do
      add_ruby_file('test_component.rb', <<~CONTENT)
        class TestComponent < ViewComponent::Base
          class OtherComponent < ViewComponent::Base; end
          renders_one :other_component, ->(name:, scheme:, classes:, **options) do
            OtherComponent.new(name: name, scheme: scheme, classes: classes, **options)
          end
        end
      CONTENT

      expected = <<~RBI
        # typed: strong

        class TestComponent
          include ViewComponentSlotablesMethodsModule

          module ViewComponentSlotablesMethodsModule
            sig { returns(T.untyped) }
            def other_component; end

            sig { returns(T::Boolean) }
            def other_component?; end

            sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
            def with_other_component(*args, &block); end

            sig { params(content: T.untyped).returns(T.untyped) }
            def with_other_component_content(content); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:TestComponent))
    end
  end
end
