require_relative 'lib/atlas'

Dir[File.dirname(__FILE__) + '/lib/tasks/**/*.rb'].each {|file| require file }

task a: :environment do
  nodes = Atlas::EnergyNode.all
    .select { |n| n.merit_order }
    .select { |n| n.merit_order.type == :flex && n.merit_order.group }

  nodes.each do |node|
    lines = node.path.read.split("\n")
    File.write(
      node.path,
      lines.reject { |l| l.start_with?('- merit_order.group') }.join("\n") + "\n"
    )
  end
end
