namespace :edge do
  desc 'Create an Edge from one converter to the other.'
  task :create do

    from     = ENV['from']
    to       = ENV['to']
    carrier  = ENV['carrier']
    type     = ENV['type'] || :share

    Atlas.data_dir = '../etsource/data'

    fail 'please specify from, e.g. rake edge:create from=foo' unless from
    fail 'please specify to, e.g. rake edge:create to=bar' unless to
    fail 'please specify carrier, e.g. rake edge:create carrier=electricity' unless carrier

    # Validations (will raise error automatically)
    Atlas::Node.find(from.to_sym)
    Atlas::Node.find(to.to_sym)
    Atlas::Carrier.find(carrier)

    edge = Atlas::Edge.new(key: "#{ from }-#{ to }@#{ carrier }", type: type)

    edge.save!

  end
end
