# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Runners
        module Annotation
          def create_queue(name:, **opts)
            db[:annotation_queues].insert(
              name:                name,
              description:         opts[:description],
              evaluator_config:    opts[:evaluator_config],
              assignment_strategy: opts.fetch(:assignment_strategy, 'round_robin'),
              items_per_annotator: opts.fetch(:items_per_annotator, 20),
              created_at:          Time.now.utc
            )
            { created: true, name: name }
          rescue Sequel::UniqueConstraintViolation
            { error: 'already_exists', name: name }
          end

          def enqueue_items(queue_name:, items:, **)
            queue = db[:annotation_queues].where(name: queue_name).first
            return { error: 'queue_not_found' } unless queue

            items.each do |item|
              db[:annotation_items].insert(
                queue_id: queue[:id],
                input: item[:input], output: item[:output],
                context: item[:context], span_id: item[:span_id],
                experiment_id: item[:experiment_id],
                status: 'pending', created_at: Time.now.utc
              )
            end
            { enqueued: items.size, queue: queue_name }
          end

          def assign_next(queue_name:, annotator:, count: 1, **)
            queue = db[:annotation_queues].where(name: queue_name).first
            return { error: 'queue_not_found' } unless queue

            pending = db[:annotation_items]
                      .where(queue_id: queue[:id], status: 'pending')
                      .order(:id).limit(count).all

            now = Time.now.utc
            assigned = pending.map do |item|
              db[:annotation_items].where(id: item[:id]).update(
                status: 'assigned', assigned_to: annotator, assigned_at: now
              )
              item.merge(status: 'assigned', assigned_to: annotator, assigned_at: now)
            end

            { assigned: assigned.size, items: assigned }
          end

          def complete_annotation(item_id:, label_score:, label_category: nil, explanation: nil, **)
            db[:annotation_items].where(id: item_id).update(
              status: 'completed', label_score: label_score,
              label_category: label_category, explanation: explanation,
              completed_at: Time.now.utc
            )
            { completed: true, item_id: item_id }
          end

          def skip_annotation(item_id:, reason: nil, **)
            db[:annotation_items].where(id: item_id).update(
              status: 'skipped', explanation: reason, completed_at: Time.now.utc
            )
            { skipped: true, item_id: item_id }
          end

          def queue_stats(queue_name:, **)
            queue = db[:annotation_queues].where(name: queue_name).first
            return { error: 'queue_not_found' } unless queue

            items = db[:annotation_items].where(queue_id: queue[:id])
            {
              queue:     queue_name,
              total:     items.count,
              pending:   items.where(status: 'pending').count,
              assigned:  items.where(status: 'assigned').count,
              completed: items.where(status: 'completed').count,
              skipped:   items.where(status: 'skipped').count
            }
          end

          def export_to_dataset(queue_name:, **)
            queue = db[:annotation_queues].where(name: queue_name).first
            return { error: 'queue_not_found' } unless queue

            completed = db[:annotation_items]
                        .where(queue_id: queue[:id], status: 'completed')
                        .order(:id).all

            rows = completed.map do |item|
              { input: item[:input], output: item[:output],
                label_score: item[:label_score], label_category: item[:label_category],
                explanation: item[:explanation] }
            end

            { queue: queue_name, rows: rows, count: rows.size }
          end

          private

          def db
            @db
          end
        end
      end
    end
  end
end
