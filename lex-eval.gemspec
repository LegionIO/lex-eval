# frozen_string_literal: true

require_relative 'lib/legion/extensions/eval/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-eval'
  spec.version       = Legion::Extensions::Eval::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@iverson.io']

  spec.summary       = 'LLM output evaluation framework for LegionIO'
  spec.description   = 'Provides LLM-as-judge and code-based evaluators for scoring LLM outputs, ' \
                       'with built-in templates for hallucination, relevance, and toxicity detection.'
  spec.homepage      = 'https://github.com/LegionIO/lex-eval'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
