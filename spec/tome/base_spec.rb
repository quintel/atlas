require 'spec_helper'

module Tome ; describe Tome do

  describe "root" do
    it "should return a Pathname" do
      expect(Tome.root).to be_a(Pathname)
    end
  end

  describe '#data_dir' do
    it 'returns a Pathname' do
      expect(Tome.data_dir).to be_a(Pathname)
    end

    it 'is a subdirectory of the root path' do
      expect(Tome.data_dir.to_s).to include(Tome.root.to_s)
    end
  end

  describe '#data_dir=' do
    around(:each) do |example|
      # Each example is wrapped in with_data_dir to ensure that the original
      # data_dir is restored.
      Tome.with_data_dir('/tmp') { example.run }
    end

    it 'sets the path, given an absolute string' do
      expect { Tome.data_dir = '/tmp/data' }.
        to change { Tome.data_dir }.
        to(Pathname.new('/tmp/data'))
    end

    it 'sets the path, given an absolute pathname' do
      expect { Tome.data_dir = Pathname.new('/tmp/data') }.
        to change { Tome.data_dir }.
        to(Pathname.new('/tmp/data'))
    end

    it 'sets the path, given a relative string' do
      expect { Tome.data_dir = 'data' }.
        to change { Tome.data_dir }.
        to(Tome.root.join('data'))
    end

    it 'sets the path, given a relative pathname' do
      expect { Tome.data_dir = Pathname.new('data') }.
        to change { Tome.data_dir }.
        to(Tome.root.join('data'))
    end
  end # data_dir=

  describe '#with_data_dir' do
    it 'temporarily changes the data directory' do
      Tome.with_data_dir("#{ Tome.root }/tmp") do
        expect(Tome.data_dir.to_s).to eql("#{ Tome.root }/tmp")
      end
    end

    it 'restores the previous directory when finished' do
      originally = Tome.data_dir

      Tome.with_data_dir('/tmp') {}

      expect(Tome.data_dir).to eql(originally)
      expect(Tome.data_dir).to_not eql('/tmp')
    end

    it 'restores the previous directory if an exception happens' do
      originally = Tome.data_dir

      begin
        Tome.with_data_dir('/tmp') { raise 'Nope' }
      rescue StandardError => exception
        raise exception unless exception.message == 'Nope'
      end

      expect(Tome.data_dir).to eql(originally)
      expect(Tome.data_dir).to_not eql('/tmp')
    end
  end

end ; end # describe Tome, module Tome
