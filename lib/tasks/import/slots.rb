namespace :import do
  OUT_SLOT_RE   = /^\((?<carrier>[\w_]+)\)-(?<node>[\w_]+)(?:$|: )/
  IN_SLOT_RE    = /^(?<node>[\w_]+)-\((?<carrier>[\w_]+)\)(?:$|: )/
  SLOT_DEFAULTS = Tome::Slot.new(key: 'a-@e').attributes

  # Internal: Given a slot string, returns two values: the key of the slot as
  # a symbol, and the data for the slot.
  def parse_slot(string)
    key, data = string.split(': ', 2)
    data = (data.nil? ? {} : eval(data)).with_indifferent_access 

    data[:key] = if match = IN_SLOT_RE.match(key)
      Tome::Slot.key(match[:node], :in, match[:carrier])
    elsif match = OUT_SLOT_RE.match(key)
      Tome::Slot.key(match[:node], :out, match[:carrier])
    end

    data[:path] = "#{ data[:key].to_s.split('_', 2).first }/#{ data[:key] }"

    return [key, data]
  end

  # Internal: Reads the old NL dataset, extracting slots and slot conversions
  # to be imported as new Slot documents. Any slot whose only attribute is
  # "conversion=1.0" will be omitted since Tome/Refinery will assume this as
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

    nodes.map { |_, node| node['slots'] || [] }.flatten.each do |string|
      key, data = parse_slot(string)

      slot = slots[key]

      # Merge in the NL regional data.
      slot.merge!(data)

      # Change the old "conversion" attribute to "share".
      slot[:share] = slot.delete(:conversion) if slot.key?(:conversion)
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
      value.nil? || SLOT_DEFAULTS[key.to_sym] == value
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
    include Tome

    # runner = ImportRun.new('slots')
    slots  = nl_slots.values

    reporter = Tome::Term::Reporter.new(
      'Importing slots', imported: :green, skipped: :yellow)

    # We need to select all the slots whose values differ from the defaults.
    inputs, outputs = slots.partition { |data| data[:key].to_s.include?('+') }
    skip, use       = outputs.partition { |data| all_slot_defaults?(data) }

    skip.push(*inputs)

    # Now we make a list of all nodes which had a slot added, so that we can
    # add *all* of the slots for the side (in or out) of that node.
    used_sides = use.map do |data|
      data[:key].to_s.split('@').first
    end.uniq

    skip.each do |data|
      if used_sides.include?(data[:key].to_s.split('@').first)
        use.push(data)
      end
    end

    grouped = use.group_by do |data|
      data[:key].to_s.split(/[-+]@/, 2)[0].to_sym
    end

    reporter.report do |reporter|
      grouped.each do |node_key, slots|
        efficiencies = slots.each_with_object(Hash.new) do |data, collection|
          reporter.inc(:imported)

          collection[data[:key].to_s.split('@').last] =
            data[:type] == :loss ? :elastic : data[:share]
        end

        node = Node.find(node_key)
        node.efficiency = efficiencies
        node.save(false)
      end

      # Show how many were skipped.
      (slots.length - use.length).times { reporter.inc(:skipped) }
    end

    puts
  end # slots
end # import
