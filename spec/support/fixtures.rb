module Atlas
  module Spec
    # Included into RSpec examples and groups when they ask for it. Changes
    # the fixture directory and creates a copy of the fixtures.
    module Fixtures
      # Public: The directory which will be used to store copies of the
      # fixtures for each test.
      #
      # Each test run has fixtures placed into a directory unique to that run.
      # This ensures that if RSpec is running multiple times (e.g. Guard is
      # running the specs already, and you execute "rspec" in a separate
      # window), one run will not affect the files used by the other.
      #
      # Returns a Pathname.
      def self.working_dir
        @working_dir ||= Pathname.new(Dir.mktmpdir)
      end

      # Sets up the RSpec hooks.
      def self.included(klass)
        dir = Atlas::Spec::Fixtures.working_dir

        klass.around(:each) do |example|
          Atlas.with_data_dir(dir) { example.run }
        end

        klass.before(:each) do
          dir.children.each { |subdir| FileUtils.rm_rf(subdir) }
          FileUtils.cp_r(Atlas.root.join('spec/fixtures/.'), dir)
        end
      end
    end # Fixtures
  end # Spec
end # Atlas
