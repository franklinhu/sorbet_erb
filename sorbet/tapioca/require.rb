# typed: true
# frozen_string_literal: true

require "better_html"
require "better_html/parser"
require "erb"
require "fileutils"
require "minitest/autorun"
require "pathname"
require "psych"
require "rails"
require "rubygems/user_interaction"
require "sorbet-runtime"
require "tapioca/dsl"
require "tapioca/helpers/test/content"
require "tapioca/helpers/test/dsl_compiler"
require "tapioca/internal"
require "view_component"
require "view_component/slotable"
