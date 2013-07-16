namespace :console do
  task :run, [:dir] do |_, args|
    command = system("which pry > /dev/null 2>&1") ? 'pry' : 'irb'
    dir     = args.dir.nil? ? '../etsource/data' : args.dir
    post    = %('Atlas.data_dir = #{ dir.inspect }')

    exec "#{ command } -I./lib -r./lib/atlas.rb -e #{ post }"
  end
end

desc 'Open a pry or irb session preloaded with Atlas'
task :console, [:dir] => ['console:run']
