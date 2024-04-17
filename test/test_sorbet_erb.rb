# frozen_string_literal: true

require 'test_helper'

class TestSorbetErb < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SorbetErb::VERSION
  end

  def test_constantize_path_name
    assert_equal(
      'Module::Class',
      SorbetErb.constantize_path_name('module/class.html.erb')
    )
  end
end
