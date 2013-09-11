namespace :export do

  desc 'Exports all the properties for all the nodes'
  task :nodes do
    require 'atlas'
    require 'csv'
    require 'fileutils'

    Atlas.data_dir = '../etsource/data'

    export_dir = 'tmp/export/nodes'

    FileUtils.mkdir_p(export_dir)

    Dir.chdir(export_dir)

    Atlas::Node.all.each do |node|
      file_name = "#{ node.key.to_s }.csv"
      File.open(file_name, 'w') do |f|
        f.write(node.to_csv)
      end
      puts "* #{ file_name } created in #{ export_dir }"
    end

  end

end
