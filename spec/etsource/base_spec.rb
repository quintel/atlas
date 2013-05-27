require 'spec_helper'

module ETSource ; describe ETSource do

  describe "root" do
    it "should return a Pathname" do
      expect(ETSource.root).to be_a(Pathname)
    end
  end

  describe '#data_dir' do
    it 'returns a Pathname' do
      expect(ETSource.data_dir).to be_a(Pathname)
    end

    it 'is a subdirectory of the root path' do
      expect(ETSource.data_dir.to_s).to include(ETSource.root.to_s)
    end
  end

  describe '#data_dir=' do
    around(:each) do |example|
      # Each example is wrapped in with_data_dir to ensure that the original
      # data_dir is restored.
      ETSource.with_data_dir('/tmp') { example.run }
    end

    context 'given nil' do
      let(:result) do
        ETSource.data_dir = nil
      end

      it 'raises an error' do
        expect { result }.to raise_error(ETSourceError, /is not absolute/)
      end

      it 'does not change the path' do
        expect { result rescue nil }.to_not change { ETSource.data_dir }
      end
    end

    context 'given a relative string' do
      let(:result) do
        ETSource.data_dir = 'nope/this/is/wrong'
      end

      it 'raises an error' do
        expect { result }.to raise_error(ETSourceError, /is not absolute/)
      end

      it 'does not change the path' do
        expect { result rescue nil }.to_not change { ETSource.data_dir }
      end
    end

    context 'given an absolute string' do
      let(:result) do
        ETSource.data_dir = '/tmp/etsource'
      end

      it 'does not raise an error' do
        expect { result }.to_not raise_error
      end

      it 'sets the path' do
        expect { result }.
          to change { ETSource.data_dir }.
          to(Pathname.new('/tmp/etsource'))
      end
    end

    context 'given a relative pathname' do
      let(:result) do
        ETSource.data_dir = Pathname.new('nope/this/is/wrong') 
      end

      it 'raises an error' do
        expect { result }.to raise_error(ETSourceError, /is not absolute/)
      end

      it 'does not change the path' do
        expect { result rescue nil }.to_not change { ETSource.data_dir }
      end
    end

    context 'given an absolute pathname' do
      let(:result) do
        ETSource.data_dir = Pathname.new('/tmp/etsource')
      end

      it 'does not raise an error' do
        expect { result }.to_not raise_error
      end

      it 'sets the path' do
        expect { result }.
          to change { ETSource.data_dir }.
          to(Pathname.new('/tmp/etsource'))
      end
    end
  end # data_dir=

  describe '#with_data_dir' do
    it 'temporarily changes the data directory' do
      ETSource.with_data_dir("#{ ETSource.root }/tmp") do
        expect(ETSource.data_dir.to_s).to eql("#{ ETSource.root }/tmp")
      end
    end

    it 'restores the previous directory when finished' do
      originally = ETSource.data_dir

      ETSource.with_data_dir('/tmp') {}

      expect(ETSource.data_dir).to eql(originally)
      expect(ETSource.data_dir).to_not eql('/tmp')
    end

    it 'restores the previous directory if an exception happens' do
      originally = ETSource.data_dir

      begin
        ETSource.with_data_dir('/tmp') { raise 'Nope' }
      rescue StandardError => exception
        raise exception unless exception.message == 'Nope'
      end

      expect(ETSource.data_dir).to eql(originally)
      expect(ETSource.data_dir).to_not eql('/tmp')
    end
  end

end ; end # describe ETSource, module ETSource
