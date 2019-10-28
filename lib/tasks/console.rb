# frozen_string_literal: true

namespace :console do
  def start_console(dir, prelude = nil)
    command = system('which pry > /dev/null 2>&1') ? 'pry' : 'irb'
    dir     = dir.nil? ? '../etsource' : dir
    prelude = %(Atlas.data_dir = #{dir.inspect} ; #{prelude})

    prelude.gsub!("\n", '; ')

    exec "#{command} -I./lib -r./lib/atlas.rb -e '#{prelude}'"
  end

  task :run, [:dir] do |_, args|
    start_console(args.dir)
  end

  desc 'Opens a console with a graph ready for calculation by Refinery'
  task :refinery, [:dir] do |_, args|
    start_console(args.dir, <<-RUBY)
      runner  = Atlas::Runner.new(Atlas::Dataset.find(:nl))
      graph   = runner.refinery_graph
    RUBY
  end
end

desc 'Open a pry or irb session preloaded with Atlas'
task :console, [:dir] => ['console:run']
