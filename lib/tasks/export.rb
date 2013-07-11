namespace :export do

  desc 'Export all node information.'
  task :nodes, [:attr, :data_dir] do |_, args|

    $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))
    require 'tome'

    if args.data_dir.nil?
      Tome.data_dir = '../etsource/data'
    else
      Tome.data_dir = args.data_dir
    end

    if args.attr.nil?
      raise "You need to supply a attribute as an argument; " \
            "e.g.: rake export:nodes full_load_hours"
    end

    nodes = Tome::Node.all

    print 'key'
    print ','
    puts  args.attr

    nodes.each do |node|
      print node.key
      print ','
      puts  node.send(args.attr)
    end

  end
end
