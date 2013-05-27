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

    it 'sets the path, given an absolute string' do
      expect { ETSource.data_dir = '/tmp/data' }.
        to change { ETSource.data_dir }.
        to(Pathname.new('/tmp/data'))
    end

    it 'sets the path, given an absolute pathname' do
      expect { ETSource.data_dir = Pathname.new('/tmp/data') }.
        to change { ETSource.data_dir }.
        to(Pathname.new('/tmp/data'))
    end

    it 'sets the path, given a relative string' do
      expect { ETSource.data_dir = 'data' }.
        to change { ETSource.data_dir }.
        to(ETSource.root.join('data'))
    end

    it 'sets the path, given a relative pathname' do
      expect { ETSource.data_dir = Pathname.new('data') }.
        to change { ETSource.data_dir }.
        to(ETSource.root.join('data'))
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
