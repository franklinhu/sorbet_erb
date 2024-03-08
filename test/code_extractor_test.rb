# frozen_string_literal: true

require 'test_helper'

class CodeExtractorTest < Minitest::Spec
  it 'handles erb' do
    test_cases = [
      {
        name: 'normal code',
        input: <<~END,
          <div>
            <% value -%>
          </div>
        END
        output: [
          ' value '
        ],
        locals: nil
      },
      {
        name: 'expression',
        input: <<~END,
          <%= @something %>
        END
        output: [
          ' @something '
        ],
        locals: nil
      },
      {
        name: 'comment',
        input: <<~END,
          <%# comment %>
        END
        output: [],
        locals: nil
      },
      {
        name: 'for loop',
        input: <<~END,
          <% collection.each do |item| %>
            <%= item.name %>
          <% end %>
        END
        output: [
          ' collection.each do |item| ',
          ' item.name ',
          ' end '
        ],
        locals: nil
      },
      {
        name: 'strict locals - no defaults',
        input: <<~END,
          <%# locals: (a:, b:) %>
          <%= a %>
        END
        output: [
          ' a '
        ],
        locals: '(a:, b:)'
      }
    ]
    test_cases.each do |tc|
      e = SorbetErb::CodeExtractor.new
      actual, locals = e.extract(tc[:input])
      assert_equal(tc[:output], actual, tc[:name])
      if tc[:locals].nil?
        assert_nil(locals, tc[:name])
      else
        assert_equal(tc[:locals], locals, tc[:name])
      end
    end
  end
end
