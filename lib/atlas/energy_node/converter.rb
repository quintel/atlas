# frozen_string_literal: true

module Atlas
  class EnergyNode
    # Describes nodes which have effciencies, and are 'true' converters: they convert energy from
    # one carrier to the other.
    class Converter < EnergyNode
    end
  end
end
