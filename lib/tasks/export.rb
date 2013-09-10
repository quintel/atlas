namespace :export do

  desc 'Exports all the properties for all the nodes'
  task :nodes do
    require 'atlas'
    require 'csv'

    Atlas.data_dir = '../etsource/data'

    Atlas::Node.all.each do |node|
      node.attributes.each do |attr|
        puts attr
      end
    end

  end

end
