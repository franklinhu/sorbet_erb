# typed: true
# frozen_string_literal: true

require 'test_helper'

class TestSorbetErb < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SorbetErb::VERSION
  end

  def test_extract_class_name
    test_cases = [
      {
        name: 'no directory',
        path: Pathname.new('app/components/my_component.html.erb'),
        expected: ['MyComponent', false]
      },
      {
        name: 'component with component directory',
        path: Pathname.new('app/components/my_component/my_component.html.erb'),
        expected: ['MyComponent', false]
      },
      {
        name: 'namespaced directory',
        path: Pathname.new('app/components/namespace/my_component.html.erb'),
        expected: ['Namespace::MyComponent', false]
      }
    ]
    test_cases.each do |tc|
      actual = SorbetErb.class_name_from_path(tc[:path])
      assert_equal(tc[:expected], actual, tc[:name])
    end
  end
end
