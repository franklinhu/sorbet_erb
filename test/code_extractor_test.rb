# frozen_string_literal: true

require 'test_helper'

class CodeExtractorTest < Minitest::Spec
  it 'handles erb' do
    test_cases = [
      {
        name: 'normal code',
        input: <<~INPUT,
          <div>
            <% value -%>
          </div>
        INPUT
        output: [
          ' value '
        ],
        locals: nil
      },
      {
        name: 'expression',
        input: <<~INPUT,
          <%= @something %>
        INPUT
        output: [
          ' @something '
        ],
        locals: nil
      },
      {
        name: 'comment',
        input: <<~INPUT,
          <%# comment %>
        INPUT
        output: [],
        locals: nil
      },
      {
        name: 'for loop',
        input: <<~INPUT,
          <% collection.each do |item| %>
            <%= item.name %>
          <% end %>
        INPUT
        output: [
          ' collection.each do |item| ',
          ' item.name ',
          ' end '
        ],
        locals: nil
      },
      {
        name: 'strict locals - no defaults',
        input: <<~INPUT,
          <%# locals: (a:, b:) %>
          <%= a %>
        INPUT
        output: [
          ' a '
        ],
        locals: '(a:, b:)'
      },
      {
        name: 'strict locals - no space',
        input: <<~INPUT,
          <%# locals:(a:, b:) %>
          <%= a %>
        INPUT
        output: [
          ' a '
        ],
        locals: '(a:, b:)'
      },
      {
        name: 'locals sig',
        input: <<~INPUT,
          <%# locals_sig: sig { params(a: Integer, b: String).void } %>
          <%# locals:(a:, b:) %>
          <%= a %>
        INPUT
        output: [
          ' a '
        ],
        locals: '(a:, b:)',
        locals_sig: 'sig { params(a: Integer, b: String).void }'
      }
    ]
    test_cases.each do |tc|
      e = SorbetErb::CodeExtractor.new
      actual, locals, locals_sig = e.extract(tc[:input])
      assert_equal(tc[:output], actual, tc[:name])
      if tc[:locals].nil?
        assert_nil(locals, tc[:name])
      else
        assert_equal(tc[:locals], locals, tc[:name])
      end

      if tc[:locals_sig].nil?
        assert_nil(locals_sig, tc[:name])
      else
        assert_equal(tc[:locals_sig], locals_sig, tc[:name])
      end
    end
  end
end
