namespace :console do
  task :run, [:dir] do |_, args|
    command = system("which pry > /dev/null 2>&1") ? 'pry' : 'irb'
    dir     = args.dir.nil? ? '../etsource/data' : args.dir
    post    = %('Tome.data_dir = #{ dir.inspect }')

    exec "#{ command } -I./lib -r./lib/tome.rb -e #{ post }"
  end
end

desc 'Open a pry or irb session preloaded with Tome'
task :console, [:dir] => ['console:run']
