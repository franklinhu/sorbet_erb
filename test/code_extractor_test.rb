# frozen_string_literal: true

require "test_helper"

class CodeExtractorTest < Minitest::Spec
  it 'handles erb' do
    test_cases = [
      {
        name: "normal code",
        input: <<~END,
          <div>
            <% value -%>
          </div>
        END
        output: [
          " value ",
        ]
      },
      {
        name: "expression",
        input: <<~END,
          <%= @something %>
        END
        output: [
          " @something ",
        ],
      },
      {
        name: "comment",
        input: <<~END,
        <%# comment %>
        END
        output: [],
      },
      {
        name: "for loop",
        input: <<~END,
        <% collection.each do |item| %>
          <%= item.name %>
        <% end %>
        END
        output: [
          " collection.each do |item| ",
          " item.name ",
          " end ",
        ],
      },
    ]
    test_cases.each do |tc|
      e = SorbetErb::CodeExtractor.new
      actual = e.extract(tc[:input])
      assert_equal(tc[:output], actual, tc[:name])
    end
  end
end
