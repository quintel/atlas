# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlas::PathResolver do
  let(:root) { Pathname.new(Dir.mktmpdir) }

  before do
    # Create a directory structure like this:
    #
    # |- ./fallback
    # | |- both.txt
    # | |- fallback.txt
    # | |- ./inner-both
    # | | |- both.txt
    # | | |- fallback.txt
    # | |- ./inner-fallback
    # | | |- fallback.txt
    # |
    # |- ./preferred
    #   |- both.txt
    #   |- preferred.txt
    #   |- ./inner-both
    #   | |- both.txt
    #   | |- preferred.txt
    #   |- ./inner-preferred
    #   | |- preferred.txt
    #
    root.join('fallback').mkdir
    root.join('fallback/both.txt').write('')
    root.join('fallback/fallback.txt').write('')
    root.join('fallback/inner-both').mkdir
    root.join('fallback/inner-fallback').mkdir

    root.join('fallback/inner-both/both.txt').write('')
    root.join('fallback/inner-both/fallback.txt').write('')

    root.join('fallback/inner-fallback/fallback.txt').write('')

    root.join('preferred').mkdir
    root.join('preferred/both.txt').write('')
    root.join('preferred/preferred.txt').write('')
    root.join('preferred/inner-both').mkdir
    root.join('preferred/inner-preferred').mkdir

    root.join('preferred/inner-both/both.txt').write('')
    root.join('preferred/inner-both/preferred.txt').write('')

    root.join('preferred/inner-preferred/preferred.txt').write('')
  end

  after do
    root.rmtree
  end

  context 'when created with a single directory path' do
    let(:resolver) { described_class.create(root.join('fallback')) }

    it 'returns the basename' do
      expect(resolver.basename).to eq(Pathname.new('fallback'))
    end

    it 'returns the extname' do
      expect(resolver.extname).to eq('')
    end

    it 'exists' do
      expect(resolver).to be_exist
    end

    it 'is a directory' do
      expect(resolver).to be_directory
    end

    it 'is not a file' do
      expect(resolver).not_to be_file
    end

    it 'can return all children' do
      expect(resolver.children.sort_by(&:basename)).to eq([
        root.join('fallback/both.txt'),
        root.join('fallback/fallback.txt'),
        root.join('fallback/inner-both'),
        root.join('fallback/inner-fallback')
      ])
    end

    it 'joins the path with a basename' do
      expect(resolver.join('a.txt')).to eq(root.join('fallback/a.txt'))
    end

    it 'looks up a basename' do
      expect(resolver.resolve('a.txt')).to eq(root.join('fallback/a.txt'))
    end

    it 'can return glob matches in the same path' do
      expect(resolver.glob('*.txt').sort).to eq([
        root.join('fallback/both.txt'),
        root.join('fallback/fallback.txt')
      ])
    end

    it 'can return glob matches in the nested paths' do
      expect(resolver.glob('**/*.txt').sort).to eq([
        root.join('fallback/both.txt'),
        root.join('fallback/fallback.txt'),
        root.join('fallback/inner-both/both.txt'),
        root.join('fallback/inner-both/fallback.txt'),
        root.join('fallback/inner-fallback/fallback.txt')
      ])
    end
  end

  context 'when created with a fallback directory path' do
    let(:resolver) do
      described_class.create(root.join('preferred'), root.join('fallback'))
    end

    it 'returns the basename' do
      expect(resolver.basename).to eq(Pathname.new('fallback'))
    end

    it 'returns the extname' do
      expect(resolver.extname).to eq('')
    end

    it 'exists' do
      expect(resolver).to be_exist
    end

    it 'is a directory' do
      expect(resolver).to be_directory
    end

    it 'is not a file' do
      expect(resolver).not_to be_file
    end

    # children
    # --------

    # rubocop:disable RSpec/NestedGroups
    describe '#children' do
      context 'when the fallback does not exist' do
        before do
          root.join('fallback').rmtree
        end

        it 'returns children of the preferred' do
          expect(resolver.children.sort).to eq([
            root.join('preferred/both.txt'),
            root.join('preferred/inner-both'),
            root.join('preferred/inner-preferred'),
            root.join('preferred/preferred.txt')
          ])
        end
      end

      context 'when the preferred does not exist' do
        before do
          root.join('preferred').rmtree
        end

        it 'returns children of the fallback' do
          expect(resolver.children.sort).to eq([
            root.join('fallback/both.txt'),
            root.join('fallback/fallback.txt'),
            root.join('fallback/inner-both'),
            root.join('fallback/inner-fallback')
          ])
        end
      end

      context 'when neither directory exists' do
        before do
          root.join('fallback').rmtree
          root.join('preferred').rmtree
        end

        it 'returns an empty array' do
          expect(resolver.children).to eq([])
        end
      end

      context 'when both directories exist' do
        it 'can returns all unique children' do
          expect(resolver.children.sort).to eq([
            root.join('fallback/fallback.txt'),
            root.join('fallback/inner-fallback'),
            root.join('preferred/both.txt'),
            described_class.create(
              root.join('preferred/inner-both'),
              root.join('fallback/inner-both')
            ),
            root.join('preferred/inner-preferred'),
            root.join('preferred/preferred.txt')
          ])
        end
      end
    end
    # rubocop:enable RSpec/NestedGroups

    # glob
    # ----

    it 'can glob direct children of both directories, without duplicates' do
      expect(resolver.glob('*.txt').sort).to eq([
        root.join('fallback/fallback.txt'),
        root.join('preferred/both.txt'),
        root.join('preferred/preferred.txt')
      ])
    end

    it 'can glob direct nested children of both directories, without duplicates' do
      expect(resolver.glob('**/*.txt').sort).to eq([
        root.join('fallback/fallback.txt'),
        root.join('fallback/inner-both/fallback.txt'),
        root.join('fallback/inner-fallback/fallback.txt'),
        root.join('preferred/both.txt'),
        root.join('preferred/inner-both/both.txt'),
        root.join('preferred/inner-both/preferred.txt'),
        root.join('preferred/inner-preferred/preferred.txt'),
        root.join('preferred/preferred.txt')
      ])
    end

    # join
    # ----

    context 'when joining a file which exists in both directories' do
      it 'returns a PathResolver' do
        expect(resolver.join('both.txt')).to be_a(described_class)
      end

      it 'returns the path to the file in the preferred' do
        expect(resolver.join('both.txt')).to eq(root.join('preferred/both.txt'))
      end
    end

    context 'when joining a file which only exists in the fallback' do
      it 'returns a PathResolver' do
        expect(resolver.join('fallback.txt')).to be_a(described_class)
      end

      it 'returns the path to the file' do
        expect(resolver.join('fallback.txt')).to eq(root.join('fallback/fallback.txt'))
      end
    end

    context 'when joining a file which only exists in the preferred' do
      it 'returns a PathResolver' do
        expect(resolver.join('preferred.txt')).to be_a(described_class)
      end

      it 'returns the path to the file' do
        expect(resolver.join('preferred.txt')).to eq(root.join('preferred/preferred.txt'))
      end
    end

    context 'when joining a directory which exists in both directories' do
      it 'returns a PathResolver::WithFallback' do
        expect(resolver.join('inner-both')).to be_a(Atlas::PathResolver::WithFallback)
      end
    end

    context 'when joining a directory which only exists in the fallback' do
      it 'returns a PathResolver' do
        expect(resolver.join('inner-fallback')).to be_a(described_class)
      end
    end

    context 'when joining a directory which only exists in the preferred' do
      it 'returns a PathResolver' do
        expect(resolver.join('inner-preferred')).to be_a(described_class)
      end
    end

    # resolve
    # -------

    context 'when resolving a file which exists in both directories' do
      it 'returns a Pathname' do
        expect(resolver.resolve('both.txt')).to be_a(Pathname)
      end

      it 'returns the path to the file in the preferred' do
        expect(resolver.resolve('both.txt')).to eq(root.join('preferred/both.txt'))
      end
    end

    context 'when resolving a file which only exists in the fallback' do
      it 'returns a Pathname' do
        expect(resolver.resolve('fallback.txt')).to be_a(Pathname)
      end

      it 'returns the path to the file' do
        expect(resolver.resolve('fallback.txt')).to eq(root.join('fallback/fallback.txt'))
      end
    end

    context 'when resolving a file which only exists in the preferred' do
      it 'returns a Pathname' do
        expect(resolver.resolve('preferred.txt')).to be_a(Pathname)
      end

      it 'returns the path to the file' do
        expect(resolver.resolve('preferred.txt')).to eq(root.join('preferred/preferred.txt'))
      end
    end
  end
end
