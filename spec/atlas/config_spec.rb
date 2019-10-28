# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe Config do
    context 'when the file exists' do
      it 'parses the YAML file content' do
        expect(Atlas::Config.read('unscaleable_units')).to eq(%w[a b])
      end

      it 'removes non-alphanumeric characters from the basename' do
        expect(Atlas::Config.read('../un/sc^aleable_units')).to eq(%w[a b])
      end
    end

    context 'when the file does not exist' do
      it 'throws an error' do
        expect { Atlas::Config.read('no') }.to raise_error(
          Atlas::DocumentNotFoundError,
          'Could not find a config with the key "no"'
        )
      end

      it 'removes non-alphanumeric characters from the basename' do
        expect { Atlas::Config.read('no/file') }.to raise_error(
          Atlas::DocumentNotFoundError,
          'Could not find a config with the key "nofile"'
        )
      end
    end
  end
end
