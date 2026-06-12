# typed: true
# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'

class TestSorbetErb < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SorbetErb::VERSION
  end

  def test_exclude_paths_skips_matching_files
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('app/views/included')
        FileUtils.mkdir_p('app/views/excluded')
        File.write('app/views/included/show.html.erb', '<div></div>')
        File.write('app/views/excluded/show.html.erb', '<div></div>')
        File.write(
          '.sorbet_erb.yml',
          YAML.dump(
            {
              'input_dirs' => ['app'],
              'output_dir' => 'out',
              'exclude_paths' => ['app/views/excluded']
            }
          )
        )

        SorbetErb.extract_rb_from_erb(nil, nil)

        assert File.exist?('out/views/included/show.html.erb.generated.rb'),
               'expected included file to be generated'
        refute File.exist?('out/views/excluded/show.html.erb.generated.rb'),
               'expected excluded file to be skipped'
      end
    end
  end

  def test_exclude_paths_empty_includes_everything
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('app/views/a')
        FileUtils.mkdir_p('app/views/b')
        File.write('app/views/a/show.html.erb', '<div></div>')
        File.write('app/views/b/show.html.erb', '<div></div>')
        File.write(
          '.sorbet_erb.yml',
          YAML.dump(
            {
              'input_dirs' => ['app'],
              'output_dir' => 'out'
            }
          )
        )

        SorbetErb.extract_rb_from_erb(nil, nil)

        assert File.exist?('out/views/a/show.html.erb.generated.rb')
        assert File.exist?('out/views/b/show.html.erb.generated.rb')
      end
    end
  end

  def test_app_controller_class_override
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('app/views/a')
        File.write('app/views/a/show.html.erb', '<div></div>')
        File.write(
          '.sorbet_erb.yml',
          YAML.dump(
            {
              'input_dirs' => ['app'],
              'output_dir' => 'out',
              'app_controller_class' => 'MyAppController'
            }
          )
        )

        SorbetErb.extract_rb_from_erb(nil, nil)

        assert File.exist?('out/views/a/show.html.erb.generated.rb')
        assert File.read('out/views/a/show.html.erb.generated.rb').include?('MyAppController')
      end
    end
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
