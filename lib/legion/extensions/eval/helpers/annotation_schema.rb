# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Helpers
        module AnnotationSchema
          def self.create_tables(db)
            db.create_table?(:annotation_queues) do
              primary_key :id
              String :name, null: false, unique: true
              String :description
              String :evaluator_config, text: true
              String :assignment_strategy, default: 'round_robin'
              Integer :items_per_annotator, default: 20
              DateTime :created_at
            end

            db.create_table?(:annotation_items) do
              primary_key :id
              foreign_key :queue_id, :annotation_queues, null: false
              String :span_id
              Integer :experiment_id
              String :input, text: true, null: false
              String :output, text: true, null: false
              String :context, text: true
              String :status, default: 'pending'
              String :assigned_to
              Float :label_score
              String :label_category
              String :explanation, text: true
              DateTime :assigned_at
              DateTime :completed_at
              DateTime :created_at
            end
          end
        end
      end
    end
  end
end
