# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlas::ActiveDocument::DocumentReferenceValidator do
  let(:klass) do
    Class.new do
      include Atlas::ActiveDocument

      def self.name
        'DocumentReferenceValidatorStub'
      end

      attribute :ref, String

      validates_with Atlas::ActiveDocument::DocumentReferenceValidator,
        class_name: 'Atlas::EnergyNode', attribute: :ref
    end
  end

  it 'has no errors when an existing document is referenced' do
    doc = klass.new(ref: :bar)
    expect(doc.errors_on(:ref)).to be_empty
  end

  it 'has an error when the attribute is nil' do
    doc = klass.new(ref: nil)
    expect(doc.errors_on(:ref)).to include('must contain a reference to a energy node')
  end

  it 'has an error when the attribute is an empty string' do
    doc = klass.new(ref: '')
    expect(doc.errors_on(:ref)).to include('must contain a reference to a energy node')
  end

  it 'has an error when a non-existent document is referenced' do
    doc = klass.new(ref: :no_such_document)

    expect(doc.errors_on(:ref))
      .to include('references a energy node which does not exist')
  end
end
