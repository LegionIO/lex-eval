# frozen_string_literal: true

require 'spec_helper'
require 'sequel'

RSpec.describe Legion::Extensions::Eval::Helpers::AnnotationSchema do
  let(:db) { Sequel.sqlite }

  describe '.create_tables' do
    it 'creates annotation_queues table' do
      described_class.create_tables(db)
      expect(db.table_exists?(:annotation_queues)).to be true
    end

    it 'creates annotation_items table' do
      described_class.create_tables(db)
      expect(db.table_exists?(:annotation_items)).to be true
    end

    it 'is idempotent' do
      described_class.create_tables(db)
      expect { described_class.create_tables(db) }.not_to raise_error
    end

    it 'creates annotation_queues with expected columns' do
      described_class.create_tables(db)
      columns = db[:annotation_queues].columns
      expect(columns).to include(:id, :name, :description, :assignment_strategy, :items_per_annotator, :created_at)
    end

    it 'creates annotation_items with expected columns' do
      described_class.create_tables(db)
      columns = db[:annotation_items].columns
      expect(columns).to include(:id, :queue_id, :input, :output, :status, :assigned_to, :label_score)
    end
  end
end
