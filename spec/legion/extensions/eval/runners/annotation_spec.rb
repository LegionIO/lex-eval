# frozen_string_literal: true

require 'spec_helper'
require 'sequel'

RSpec.describe Legion::Extensions::Eval::Runners::Annotation do
  let(:db) { Sequel.sqlite }
  let(:host) do
    obj = Object.new
    obj.extend(described_class)
    obj.instance_variable_set(:@db, db)
    obj
  end

  before do
    Legion::Extensions::Eval::Helpers::AnnotationSchema.create_tables(db)
  end

  describe '#create_queue' do
    it 'creates a named queue' do
      result = host.create_queue(name: 'review_queue', description: 'For review')
      expect(result[:created]).to be true
      expect(result[:name]).to eq('review_queue')
    end

    it 'returns error for duplicate name' do
      host.create_queue(name: 'dup_queue')
      result = host.create_queue(name: 'dup_queue')
      expect(result[:error]).to eq('already_exists')
    end
  end

  describe '#enqueue_items' do
    before { host.create_queue(name: 'test_queue') }

    it 'adds items to the queue' do
      items = [
        { input: 'input1', output: 'output1' },
        { input: 'input2', output: 'output2' },
        { input: 'input3', output: 'output3' }
      ]
      result = host.enqueue_items(queue_name: 'test_queue', items: items)
      expect(result[:enqueued]).to eq(3)
    end

    it 'returns error for unknown queue' do
      result = host.enqueue_items(queue_name: 'missing', items: [])
      expect(result[:error]).to eq('queue_not_found')
    end
  end

  describe '#assign_next' do
    before do
      host.create_queue(name: 'assign_queue')
      host.enqueue_items(queue_name: 'assign_queue', items: [
                           { input: 'i1', output: 'o1' },
                           { input: 'i2', output: 'o2' }
                         ])
    end

    it 'assigns pending items to an annotator' do
      result = host.assign_next(queue_name: 'assign_queue', annotator: 'alice', count: 1)
      expect(result[:assigned]).to eq(1)
      expect(result[:items].first[:assigned_to]).to eq('alice')
      expect(result[:items].first[:status]).to eq('assigned')
    end
  end

  describe '#complete_annotation' do
    before do
      host.create_queue(name: 'complete_queue')
      host.enqueue_items(queue_name: 'complete_queue', items: [{ input: 'i', output: 'o' }])
      assigned = host.assign_next(queue_name: 'complete_queue', annotator: 'bob', count: 1)
      @item_id = assigned[:items].first[:id]
    end

    it 'marks item as completed with label' do
      result = host.complete_annotation(item_id: @item_id, label_score: 0.9,
                                        label_category: 'correct', explanation: 'Good answer')
      expect(result[:completed]).to be true
    end
  end

  describe '#skip_annotation' do
    before do
      host.create_queue(name: 'skip_queue')
      host.enqueue_items(queue_name: 'skip_queue', items: [{ input: 'i', output: 'o' }])
      assigned = host.assign_next(queue_name: 'skip_queue', annotator: 'carol', count: 1)
      @item_id = assigned[:items].first[:id]
    end

    it 'marks item as skipped' do
      result = host.skip_annotation(item_id: @item_id, reason: 'ambiguous')
      expect(result[:skipped]).to be true
    end
  end

  describe '#queue_stats' do
    before do
      host.create_queue(name: 'stats_queue')
      host.enqueue_items(queue_name: 'stats_queue', items: [
                           { input: 'i1', output: 'o1' },
                           { input: 'i2', output: 'o2' },
                           { input: 'i3', output: 'o3' }
                         ])
      assigned = host.assign_next(queue_name: 'stats_queue', annotator: 'dave', count: 2)
      host.complete_annotation(item_id: assigned[:items].first[:id],
                               label_score: 0.8, label_category: 'ok', explanation: 'Fine')
    end

    it 'returns correct counts' do
      result = host.queue_stats(queue_name: 'stats_queue')
      expect(result[:total]).to eq(3)
      expect(result[:pending]).to eq(1)
      expect(result[:assigned]).to eq(1)
      expect(result[:completed]).to eq(1)
    end
  end

  describe '#export_to_dataset' do
    before do
      host.create_queue(name: 'export_queue')
      host.enqueue_items(queue_name: 'export_queue', items: [{ input: 'i1', output: 'o1' }])
      assigned = host.assign_next(queue_name: 'export_queue', annotator: 'eve', count: 1)
      host.complete_annotation(item_id: assigned[:items].first[:id],
                               label_score: 0.9, label_category: 'correct', explanation: 'Good')
    end

    it 'returns completed items as dataset rows' do
      result = host.export_to_dataset(queue_name: 'export_queue')
      expect(result[:rows].size).to eq(1)
      expect(result[:rows].first[:input]).to eq('i1')
      expect(result[:rows].first[:label_score]).to eq(0.9)
    end
  end
end
