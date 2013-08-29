module Atlas
  class Carrier
    include ActiveDocument

    DIRECTORY = 'carriers'

    attribute :sustainable,                Float
    attribute :infinite,                   Boolean
    attribute :cost_per_mj,                Float
    attribute :mj_per_kg,                  Float
    attribute :co2_conversion_per_mj,      Float
    attribute :typical_production_per_km2, Float
    attribute :kg_per_liter,               Float
    attribute :graphviz_color,             Symbol

    attribute :co2_conversion_per_mj,      Float
    attribute :co2_exploration_per_mj,     Float
    attribute :co2_extraction_per_mj,      Float
    attribute :co2_treatment_per_mj,       Float
    attribute :co2_transportation_per_mj,  Float
    attribute :co2_waste_treatment_per_mj, Float

    attribute :fce,                        Hash[Symbol => Hash]

  end # Carrier
end # Atlas
