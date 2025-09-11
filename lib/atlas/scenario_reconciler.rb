module Atlas
  # Given user values from an ETEngine scenario, examines the user values and suggests
  # adjustments to ensure that the input groups all balance (sum to 100).
  class ScenarioReconciler
    # Public: Creates a scenario reconciler.
    #
    # values   - A hash containing the user values.
    # defaults - A hash where each key is that of an input, and each value a
    #            hash containing the :min, :max, and :start values for that
    #            input.
    #
    # Returns a ScenarioReconciler.
    def initialize(values, defaults)
      fail OsmosisRequired.new(self.class) unless defined?(::Osmosis)

      @values   = values
      @defaults = defaults
    end

    # Public: A hash containing all the inputs which will be changed. Includes
    # unchanged inputs belonging to the same group as a changed input.
    #
    # Returns a hash.
    def to_h
      balance(@values.merge(missing_inputs.merge(corrected_values)))
        .select { |key, value| Input.exists?(key) || value.nil? }
    end

    # Public: Creates a string which describes the changes which would be made
    # to the scenario.
    #
    # Returns a string.
    def diff
      changes = to_h
      merged  = @values.merge(changes)

      string = user_groups.map do |group_key|
        input_keys = group(group_key).map(&:key).sort_by(&:to_s)

        # Skip any unchanged groups.
        next if input_keys.all? { |key| merged[key] == @values[key] }

        info = input_keys.map do |key|
          if changes.key?(key) && ! @values.key?(key)
            '+ %s :: (missing) -> %f' % [key, changes[key]]
          elsif changes[key] != @values[key]
            '~ %s :: %f -> %f' % [key, @values[key], changes[key]]
          else
            '  %s :: %f' % [key, @values[key]]
          end
        end

        <<-INFO.gsub(/^ {10}/, '')
          #{ group_key }
          #{ '-' * group_key.to_s.length }
          #{ info.join("\n") }
          = #{ group_sum(group_key, merged).to_f }
        INFO
      end.compact

      # Inputs changed based on their extrema.
      if (corrected = corrected_values).any?
        corrected_list = corrected.map do |key, value|
          '~ %s :: %f -> %f' % [key, @values[key], corrected[key]]
        end

        string.unshift(<<-CORRECTED.gsub(/^ {10}/, ''))
          Corrected Values
          ----------------
          #{ corrected_list.join("\n") }
        CORRECTED
      end

      string.join("\n")
    end

    private

    # Internal: Returns a hash containing new values for any input whose value
    # is too high or too low.
    def corrected_values
      Hash[@values.map do |key, value|
        next unless @defaults[key] && value

        if value > @defaults[key][:max]
          [key, @defaults[key][:max]]
        elsif value < @defaults[key][:min]
          [key, @defaults[key][:min]]
        end
      end.compact]
    end

    # Internal: Creates a hash containing any inputs which are missing from the
    # user values. Only inputs belonging to groups for which the user has
    # specified one or more value will be included.
    def missing_inputs
      missing = {}

      user_groups.each do |group_key|
        input_keys   = group(group_key).map(&:key)
        missing_keys = input_keys.reject { |key| @values.key?(key) }

        missing_keys.each do |input_key, data|
          missing[input_key] = @defaults[input_key][:start]
        end
      end

      missing
    end

    # Internal: Balances the input values to ensure that the groups all sum to
    # 100.
    def balance(values)
      user_groups.each do |group_key|
        # If adding missing inputs was enough to balance the group; do nothing.
        next if group_sum(group_key, values) == 100.0

        osmosis_data = osmosis_data_for(group_key, values)

        balanced = begin
          # The first balance attempt will be performed while keeping the user's
          # original values unchanged. This seeks to preserve the intent of the
          # user when they created their scenario.
          Osmosis.balance(osmosis_data, 100.0)
        rescue Osmosis::CannotBalanceError, Osmosis::NoVariablesError
          # We couldn't balance the group while preserving the user values.
          # Therefore we'll have to alter those values.
          osmosis_data.each { |_, data| data[:static] = false }
          Osmosis.balance(osmosis_data, 100.0)
        end

        balanced.each do |key, value|
          if value.abs <= 1.0e-7
            # If any input has a very tiny value, set it to zero.
            balanced[key] = 0.0
          elsif @values[key] && (value - @values[key]).abs <= 1.0e-7
            # For the sake of cleaner diffs, revert any tiny changes.
            balanced[key] = @values[key]
          end
        end

        values = values.merge(balanced)
      end

      values
    end

    # Internal: Creates a hash where each key is the name of a group, and each
    # value an array of the inputs belonging to the group.
    def groups
      @groups ||= Input.all.select(&:share_group).group_by(&:share_group)
    end

    # Internal: Returns an array containing the inputs which belong to the named
    # group.
    def group(group_key)
      groups[group_key]
    end

    # Internal: An array of group keys for which the user has specified at least
    # one input in their scenario.
    def user_groups
      @values.keys
        .select(&Input.method(:exists?))
        .map(&Input.method(:find))
        .map(&:share_group).compact.uniq
    end

    # Internal: Given the key of a group, and a collection of input values, sums
    # the values of the inputs.
    def group_sum(group_key, collection)
      input_keys = group(group_key).map(&:key)
      input_keys.map { |key| collection[key] || 0.0 }.reduce(:+)
    end

    # Internal: Creates the hash of values which define a group, to be given to
    # Osmosis for balancing.
    def osmosis_data_for(group_key, values)
      Hash[ group(group_key).map(&:key).map do |input_key|
        [ input_key, {
          min:    @defaults[input_key][:min],
          max:    @defaults[input_key][:max],
          value:  values[input_key],
          static: @values.key?(input_key)
        } ]
      end ]
    end
  end
end
