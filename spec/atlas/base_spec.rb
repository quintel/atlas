require 'spec_helper'

module Atlas ; describe Atlas do

  describe "root" do
    it "should return a Pathname" do
      expect(Atlas.root).to be_a(Pathname)
    end
  end

  describe '#data_dir' do
    it 'returns a Pathname' do
      expect(Atlas.data_dir).to be_a(Pathname)
    end
  end

  describe '#data_dir=' do
    around(:each) do |example|
      # Each example is wrapped in with_data_dir to ensure that the original
      # data_dir is restored.
      Atlas.with_data_dir('/tmp') { example.run }
    end

    it 'sets the path, given an absolute string' do
      expect { Atlas.data_dir = '/tmp/data' }.
        to change { Atlas.data_dir }.
        to(Pathname.new('/tmp/data'))
    end

    it 'sets the path, given an absolute pathname' do
      expect { Atlas.data_dir = Pathname.new('/tmp/data') }.
        to change { Atlas.data_dir }.
        to(Pathname.new('/tmp/data'))
    end

    it 'sets the path, given a relative string' do
      expect { Atlas.data_dir = 'data' }.
        to change { Atlas.data_dir }.
        to(Atlas.root.join('data'))
    end

    it 'sets the path, given a relative pathname' do
      expect { Atlas.data_dir = Pathname.new('data') }.
        to change { Atlas.data_dir }.
        to(Atlas.root.join('data'))
    end
  end

  describe '#with_data_dir' do
    it 'temporarily changes the data directory' do
      Atlas.with_data_dir("#{ Atlas.root }/tmp") do
        expect(Atlas.data_dir.to_s).to eql("#{ Atlas.root }/tmp")
      end
    end

    it 'restores the previous directory when finished' do
      originally = Atlas.data_dir

      Atlas.with_data_dir('/tmp') {}

      expect(Atlas.data_dir).to eql(originally)
      expect(Atlas.data_dir).to_not eql('/tmp')
    end

    it 'restores the previous directory if an exception happens' do
      originally = Atlas.data_dir

      begin
        Atlas.with_data_dir('/tmp') { raise 'Nope' }
      rescue StandardError => exception
        raise exception unless exception.message == 'Nope'
      end

      expect(Atlas.data_dir).to eql(originally)
      expect(Atlas.data_dir).to_not eql('/tmp')
    end
  end

end ; end
