# frozen_string_literal: true

require 'spec_helper'

describe Atlas::Config do
  shared_examples_for 'successfully reading a config file' do
    context 'when the file exists' do
      it 'parses the YAML file content' do
        expect(described_class.public_send(method_name, 'unscaleable_units')).to eq(%w[a b])
      end

      it 'removes non-alphanumeric characters from the basename' do
        expect(described_class.public_send(method_name, '../un/sc^aleable_units')).to eq(%w[a b])
      end
    end
  end

  describe '.read' do
    let(:method_name) { :read }

    include_examples 'successfully reading a config file'

    context 'when the file does not exist' do
      it 'throws an error' do
        expect { described_class.read('no') }.to raise_error(
          Atlas::DocumentNotFoundError,
          'Could not find a config with the key "no"'
        )
      end

      it 'removes non-alphanumeric characters from the basename' do
        expect { described_class.read('no/file') }.to raise_error(
          Atlas::DocumentNotFoundError,
          'Could not find a config with the key "nofile"'
        )
      end
    end
  end

  describe '.read?' do
    let(:method_name) { :read? }

    include_examples 'successfully reading a config file'

    context 'when the file does not exist' do
      it 'throws an error' do
        expect(described_class.read?('no')).to be_nil
      end

      it 'removes non-alphanumeric characters from the basename' do
        expect(described_class.read?('no/file')).to be_nil
      end
    end
  end
end
