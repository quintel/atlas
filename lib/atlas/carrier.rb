module Atlas
  class Carrier
    include ActiveDocument

    DIRECTORY = 'carriers'

    attribute :sustainable,                     Float
    attribute :infinite,                        Boolean
    attribute :cost_per_mj,                     Float
    attribute :mj_per_kg,                       Float
    attribute :co2_conversion_per_mj,           Float
    attribute :potential_co2_conversion_per_mj, Float
    attribute :typical_production_per_km2,      Float
    attribute :kg_per_liter,                    Float
    attribute :kg_per_mol,                      Float
    attribute :graphviz_color,                  Symbol

    attribute :co2_conversion_per_mj,           Float
    attribute :co2_exploration_per_mj,          Float
    attribute :co2_extraction_per_mj,           Float
    attribute :co2_treatment_per_mj,            Float
    attribute :co2_transportation_per_mj,       Float
    attribute :co2_waste_treatment_per_mj,      Float

    def fce(region)
      region = region.to_sym

      @fce ||= {}
      @fce.key?(region) ? @fce[region] : @fce[region] = load_fce_values(region)
    end

    private

    def load_fce_values(region)
      path = Atlas::Dataset.find(region).dataset_dir.join("fce/#{ key }.yml")
      path.file? && YAML.load_file(path)
    end
  end
end
