# typed: strict
# frozen_string_literal: true

return unless defined?(ViewComponent)

require 'sorbet-runtime'
require 'tapioca/dsl'

module Tapioca
  module Dsl
    module Compilers
      # Generates RBI for ViewComponent::Slotable
      # See https://github.com/ViewComponent/view_component/blob/main/lib/view_component/slotable.rb
      class ViewComponentSlotables < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ViewComponent::Slotable) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes
              .select { |c| c < ViewComponent::Slotable && c.name != 'ViewComponent::Base' }
          end
        end

        sig { override.void }
        def decorate
          root.create_path(constant) do |klass|
            T.unsafe(constant).registered_slots.each do |name, config|
              is_many = T.let(config[:collection], T::Boolean)

              module_name = 'ViewComponentSlotablesMethodsModule'
              klass.create_module(module_name) do |mod|
                if config[:renderable_hash]
                  generate_polymorphic_instance_methods(mod, name.to_s, config[:renderable_hash], false)
                else
                  return_type = renderable_to_type_name(config[:renderable])

                  generate_instance_methods(mod, name.to_s, return_type, is_many)
                end
              end
              klass.create_include(module_name)
            end
          end
        end

        sig { params(r: T.untyped).returns(String) }
        def renderable_to_type_name(r)
          case r
          when String
            r
          when Class
            T.must(r.name)
          else
            'T.untyped'
          end
        end

        sig do
          params(
            klass: RBI::Scope,
            slot_name: String,
            underlying_types: T::Hash[Symbol, T.untyped],
            is_many: T::Boolean
          ).void
        end
        def generate_polymorphic_instance_methods(klass, slot_name, underlying_types, is_many)
          klass.create_method(slot_name, return_type: 'T.untyped') # TODO: should this be T.any of underlying types?
          klass.create_method("#{slot_name}?", return_type: 'T::Boolean')

          underlying_types.each do |name, config|
            namespaced_name = "#{slot_name}_#{name}"
            return_type = renderable_to_type_name(config[:renderable])

            klass.create_method(
              "with_#{namespaced_name}",
              parameters: [
                create_rest_param('args', type: 'T.untyped'),
                create_block_param('block', type: 'T.untyped')
              ],
              return_type: return_type
            )
          end
        end

        sig { params(klass: RBI::Scope, name: String, return_type: String, is_many: T::Boolean).void }
        def generate_instance_methods(klass, name, return_type, is_many)
          return_type_maybe_plural =
            if is_many
              "T::Enumerable[#{return_type}]"
            else
              return_type
            end

          klass.create_method(name, return_type: return_type_maybe_plural)
          klass.create_method("#{name}?", return_type: 'T::Boolean')

          klass.create_method(
            "with_#{name}",
            parameters: [
              create_rest_param('args', type: 'T.untyped'),
              create_block_param(
                'block',
                type: "T.nilable(T.proc.params(#{name}: #{return_type_maybe_plural}).returns(T.untyped))"
              )
            ],
            return_type: return_type_maybe_plural
          )

          if is_many
            # For collection subcomponents, ViewComponent generates methods for the singular version
            # of the name.
            singular_name = ActiveSupport::Inflector.singularize(name)

            klass.create_method(
              "with_#{singular_name}",
              parameters: [
                create_rest_param('args', type: 'T.untyped'),
                create_block_param(
                  'block',
                  type: "T.nilable(T.proc.params(#{singular_name}: #{return_type}).returns(T.untyped))"
                )
              ],
              return_type: return_type
            )
            klass.create_method(
              "with_#{singular_name}_content",
              parameters: [
                create_param('content', type: 'T.untyped')
              ],
              return_type: 'T.untyped'
            )

          else
            klass.create_method(
              "with_#{name}_content",
              parameters: [
                create_param('content', type: 'T.untyped')
              ],
              return_type: return_type
            )
          end
        end
      end
    end
  end
end
