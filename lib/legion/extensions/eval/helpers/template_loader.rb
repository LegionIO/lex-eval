# frozen_string_literal: true

require 'yaml'

module Legion
  module Extensions
    module Eval
      module Helpers
        class TemplateLoader
          TEMPLATE_DIR = File.expand_path('../templates', __dir__).freeze

          def load_template(name)
            load_from_prompt(name) || load_from_yaml(name)
          end

          def list_templates
            return [] unless Dir.exist?(TEMPLATE_DIR)

            Dir.glob(File.join(TEMPLATE_DIR, '*.yml')).map do |path|
              YAML.safe_load_file(path, symbolize_names: true)
            end
          end

          def seed_prompts
            return unless prompt_client_available?

            list_templates.each do |tmpl|
              prompt_name = "eval.#{tmpl[:name]}"
              existing = prompt_client.get_prompt(name: prompt_name)
              next unless existing[:error]

              prompt_client.create_prompt(name: prompt_name, template: tmpl[:template],
                                          description: tmpl[:description],
                                          model_params: { threshold: tmpl[:threshold],
                                                          category:  tmpl[:category] })
              prompt_client.tag_prompt(name: prompt_name, tag: :production)
            end
          end

          private

          def load_from_prompt(name)
            return nil unless prompt_client_available?

            result = prompt_client.get_prompt(name: "eval.#{name}", tag: :production)
            return nil if result[:error]

            result
          end

          def load_from_yaml(name)
            path = File.join(TEMPLATE_DIR, "#{name}.yml")
            return nil unless File.exist?(path)

            YAML.safe_load_file(path, symbolize_names: true)
          end

          def prompt_client_available?
            defined?(Legion::Extensions::Prompt::Client)
          end

          def prompt_client
            @prompt_client ||= Legion::Extensions::Prompt::Client.new
          end
        end
      end
    end
  end
end
