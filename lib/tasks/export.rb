namespace :export do

  desc 'Exports all the properties for all the nodes'
  task :nodes do
    require 'atlas'
    require 'csv'

    Atlas.data_dir = '../etsource/data'

    Dir.chdir('tmp')

    Atlas::Node.all.each do |node|
      File.open(node.key, 'w') do
        node.to_csv
      end
    end

  end

end
