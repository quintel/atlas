namespace :yaml do
  OUT_SLOT_RE   = /^\((?<carrier>[\w_]+)\)-(?<node>[\w_]+)(?:$|: )/
  IN_SLOT_RE    = /^(?<node>[\w_]+)-\((?<carrier>[\w_]+)\)(?:$|: )/
  SLOT_DEFAULTS = Atlas::Slot.new(key: 'a-@e').attributes

  # Internal: Given a slot string, returns two values: the key of the slot as
  # a symbol, and the data for the slot.
  def parse_slot(string)
    key, data = string.split(': ', 2)
    data = (data.nil? ? {} : eval(data)).with_indifferent_access 

    data[:key] = if match = IN_SLOT_RE.match(key)
      Atlas::Slot.key(match[:node], :in, match[:carrier])
    elsif match = OUT_SLOT_RE.match(key)
      Atlas::Slot.key(match[:node], :out, match[:carrier])
    end

    data[:path] = "#{ data[:key].to_s.split('_', 2).first }/#{ data[:key] }"

    return [key, data]
  end

  # Internal: Reads the old NL dataset, extracting slots and slot conversions
  # to be imported as new Slot documents. Any slot whose only attribute is
  # "conversion=1.0" will be omitted since Atlas/Refinery will assume this as
  # the default anyway.
  #
  # Regional data looks like:
  #   (useable_heat)-agriculture_burner_crude_oil: {...}  # Hash key and value
  #
  # Global data looks like:
  #   "(loss)-agriculture_burner_crude_oil: {...}"  # String
  # 
  # Returns a hash of slot data.
  def nl_slots
    slots = {}.with_indifferent_access

    # Start by reading the Dutch dataset, extracting information about the
    # slots there.

    Dir.glob($from_dir.join('datasets/nl/graph/**.yml')).each do |file|
      YAML.load_file(file).each do |key, properties|
        if key.match(IN_SLOT_RE) || key.match(OUT_SLOT_RE)
          slots[key] = properties
        end
      end
    end

    # Now we parse the node data, extracting the global information about
    # slots.

    nodes = YAML.load_file($from_dir.join('topology/export.graph'))
    node_data = nodes_by_sector

    nodes.each do |node_key, node|
      (node['slots'] || []).flatten.each do |string|
        key, data = parse_slot(string)

        slot = slots[key]

        # Merge in the NL regional data.
        slot.merge!(data)

        if data[:type] == :carrier_efficient
          ndata = node_data[node['sector']].assoc(node_key).last
          ceff  = ndata['carrier_efficiency'][data[:key].to_s.split('@').last]

          # Determine the efficiency from the share of inputs. This is "safe"
          # since input slots for the node are always read before the outputs.

          conversion = ceff.sum do |carrier, conv|
            if input = slots["#{ node_key }-(#{ carrier })"]
              conv * input[:share]
            else
              0.0
            end
          end.round(4)

          slot[:conversion] = conversion
        end

        # Change the old "conversion" attribute to "share".
        slot[:share] = slot.delete(:conversion) if slot.key?(:conversion)
      end
    end

    slots
  end

  # Internal: Checks if the attributes for a slot are identical to the
  # defaults, in which case we don't need to add an explicit slot.
  def all_slot_defaults?(attributes)
    without_path = attributes.dup
    without_path.delete(:path)
    without_path.delete(:key)

    without_path.all? do |key, value|
      # The value matches the default, or ...
      (value.nil? || SLOT_DEFAULTS[key.to_sym] == value) ||
        # ... it's a share attribute, and has the default of 1.0.
        (key.to_sym == :share && value == 1.0)
    end
  end

  # --------------------------------------------------------------------------

  desc <<-DESC
    Import slots from the old format to ActiveDocument.

    This starts by *deleting* everything in data/nodes on the assumption that
    there are no hand-made changes. Then the global slot data (from
    export/topology) is merged with data from the NL dataset to complete the
    slot information.
  DESC
  task :slots, [:from, :to] => [:setup] do |_, args|
    include Atlas

    slots    = nl_slots.values
    required = YAML.load_file(Atlas.data_dir.join('import/required_slots.yml'))
    ignored  = YAML.load_file(Atlas.data_dir.join('import/ignored_slots.yml'))

    # We start by building two lists; one containing the slots which we
    # definitely need to import, and one containing those we thing can be
    # skipped.

    use, skip = slots.partition do |data|
      direction = data[:key].to_s.include?('-') ? :output : :input
      node_key  = data[:key].to_s.split(/[+-]/).first

      # We import *all* output slots whose share is not the default 1.0.
      (! ignored.include?(node_key) || data[:type] == :loss) &&
       ((direction == :output && ! all_slot_defaults?(data)) ||
        # Include coupling carriers...
        data[:key].to_s.include?('coupling_carrier') ||
        # ... or any slot (including input slots) named in the ETSource
        # data/import/required_inputs_slots.yml file.
        required[direction].include?(node_key))
    end

    # Next, we create a list of all the nodes which need to have one or more
    # slots defined so that we can add all the input/output slots for that
    # node.

    used_sides = use.map do |data|
      node_key = data[:key].to_s.split(/[-+]/).first

      # We don't need to store the entire "side" if the slot is for a coupling
      # carrier... that can be included on its own since it is ignored when
      # performing Refinery calculations.
      unless data[:key].to_s.include?('coupling_carrier') || ignored.include?(node_key)
        data[:key].to_s.split('@').first
      end
    end.compact.uniq

    skip.each do |data|
      use.push(data) if used_sides.include?(data[:key].to_s.split('@').first)
    end

    # Before proceeding with the import, group all the slots which need to be
    # added by the node key and slot direction so that we can save them all
    # at once.

    grouped = use.group_by do |data|
      data[:key].to_s.split('@', 2).first.to_sym
    end

    Atlas::Term::Reporter.new(
      'Importing slots', imported: :green, skipped: :yellow
    ).report do |reporter|
    # reporter.report do |reporter|
      grouped.each do |token, slots|
        # The token is the node key, followed by a + or -
        node_key = token[0..-2]
        getter   = token[-1] == ?- ? 'output' : 'input'
        setter   = token[-1] == ?- ? :output= : :input=

        next if IGNORED_NODES.include?(node_key.to_sym)

        node = Node.find(node_key)

        # Add the slots in a predictable order each time.
        slots = slots.sort_by { |s| s[:key] }

        # Create a hash containing the data to be saved into the node. Loss
        # slots are ignored and set to elastic.
        slot_data = slots.each_with_object({}) do |data, collection|
          carrier = data[:key].to_s.split('@').last

          # Skip slots for which there is a query.
          next if node.queries.key?("#{ getter }.#{ carrier }")

          collection[carrier] = data[:type] == :loss ? :elastic : data[:share]
        end

        node.public_send(setter, slot_data)
        node.save(false)

        slot_data.length.times { reporter.inc(:imported) }
      end

      # Show many many were skipped.
      (slots.length - use.length).times { reporter.inc(:skipped) }
    end
  end # slots
end # yaml
