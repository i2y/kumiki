# frozen_string_literal: true

require_relative "lib/kumiki/version"

Gem::Specification.new do |spec|
  spec.name = "kumiki"
  spec.version = Kumiki::VERSION
  spec.authors = ["Yasushi Itoh"]
  spec.summary = "A reactive GUI framework for Ruby (ranma + Vello)"
  spec.description = "Kumiki is a declarative, reactive GUI framework for Ruby with a DSL-based component system, powered by ranma (tao + Vello) for native GPU rendering."
  spec.homepage = "https://github.com/i2y/kumiki"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ranma"
end
