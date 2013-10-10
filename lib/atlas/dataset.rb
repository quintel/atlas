module Atlas
  class Dataset
    include ActiveDocument

    DIRECTORY = 'datasets'

    # General Attributes
    attribute :country,   String
    attribute :area,      String
    attribute :id,        Integer
    attribute :entity,    String
    attribute :parent_id, Integer

    # Set to false in the document to disable the region in ETModel.
    attribute :enabled,   Hash[Symbol => Boolean],
                          default: { etengine: true, etmodel: true }

    attribute :analysis_year, Integer, default: 2011

    # Flags
    attribute :has_agriculture,          Boolean, default: true
    attribute :has_buildings,            Boolean, default: true
    attribute :has_climate,              Boolean, default: false
    attribute :has_coastline,            Boolean, default: true
    attribute :has_cold_network,         Boolean, default: false
    attribute :has_electricity_storage,  Boolean, default: true
    attribute :has_employment,           Boolean, default: true
    attribute :has_fce,                  Boolean, default: true
    attribute :has_industry,             Boolean, default: true
    attribute :has_lignite,              Boolean, default: false
    attribute :has_merit_order,          Boolean, default: false
    attribute :has_metal,                Boolean, default: true
    attribute :has_mountains,            Boolean, default: true
    attribute :has_old_technologies,     Boolean, default: false
    attribute :has_other,                Boolean, default: true
    attribute :has_solar_csp,            Boolean, default: false
    attribute :use_network_calculations, Boolean, default: true

    # Numeric Data
    [ :annual_infrastructure_cost_electricity,
      :annual_infrastructure_cost_gas,
      :areable_land,
      :available_land,
      :buildings_insulation_constant_1,
      :buildings_insulation_constant_2,
      :buildings_insulation_cost_constant,
      :buildings_insulation_employment_constant,
      :capacity_buffer_decentral_in_mj_s,
      :capacity_buffer_in_mj_s,
      :co2_emission_1990,
      :co2_emission_2009,
      :co2_emission_electricity_1990,
      :co2_percentage_free,
      :co2_price,
      :coast_line,
      :economic_multiplier,
      :el_export_capacity,
      :employment_fraction_production,
      :employment_local_fraction,
      :export_electricity_primary_demand_factor,
      :import_electricity_primary_demand_factor,
      :insulation_level_buildings_max,
      :insulation_level_buildings_min,
      :insulation_level_new_houses_max,
      :insulation_level_new_houses_min,
      :insulation_level_old_houses_max,
      :insulation_level_old_houses_min,
      :km_per_car,
      :km_per_truck,
      :land_available_for_solar,
      :man_hours_per_man_year,
      :market_share_daylight_control,
      :market_share_motion_detection,
      :new_houses_insulation_constant_1,
      :new_houses_insulation_constant_2,
      :new_houses_insulation_cost_constant,
      :new_houses_insulation_employment_constant,
      :number_buildings,
      :number_households,
      :number_inhabitants,
      :number_of_existing_households,
      :number_of_new_residences,
      :number_of_old_residences,
      :offshore_suitable_for_wind,
      :old_houses_insulation_constant_1,
      :old_houses_insulation_constant_2,
      :old_houses_insulation_cost_constant,
      :old_houses_insulation_employment_constant,
      :onshore_suitable_for_wind,
      :percentage_of_new_houses,
      :roof_surface_available_pv,
      :roof_surface_available_pv_buildings,
      :technical_lifetime_insulation
    ].each do |name|
      attribute name, Float
    end

    # Returns the Energy Balance for this area/dataset.
    def energy_balance
      @energy_balance ||= EnergyBalance.find(area)
    end

    # Public: Retrieves the share data for the file whose name matches +key+.
    #
    # key - The name of the shares file to load.
    #
    # For example:
    #   dataset.shares(:trucks).get(:gasoline) # => 0.4
    #
    # Returns a CSVDocument::OneDimensional.
    def shares(key)
      key = key.to_sym

      (@shares ||= {})[key] ||=
        CSVDocument::OneDimensional.new(
          dataset_dir.join("shares/#{ key }.csv"))
    end

    # Public: Retrieves the efficiency data from the named file.
    #
    # key - The name of the efficiencies file to load.
    #
    # For example:
    #   dataset.efficiencies(:transformation).get('output.coal') # => 0.3
    #
    # Returns a CSVDocument::OneDimensional.
    def efficiencies(key)
      (@efficiencies ||= {})[key.to_sym] ||=
        CSVDocument::OneDimensional.new(
          dataset_dir.join("efficiencies/#{ key }_efficiency.csv"))
    end

    # Public: Retrieves the time curve data for the file whose name matches
    # +key+.
    #
    # key - The name of the time curve file to load.
    #
    # For example:
    #   dataset.time_curve(bio_residues).get(2011, :max_demand) # => 34.0
    #
    # Returns a CSVDocument.
    def time_curve(key)
      (@time_curves ||= {})[key.to_sym] ||=
        CSVDocument.new(
          dataset_dir.join("time_curves/#{ key }_time_curve.csv"))
    end

    # Public: Retrieves all the time curves for the dataset's region.
    #
    # Returns a hash of document keys, and the CSVDocuments.
    def time_curves
      Pathname.glob(dataset_dir.join('time_curves/*.csv')).each do |csv_path|
        time_curve(csv_path.basename('_time_curve.csv').to_s)
      end

      @time_curves ||= {}
    end

    # Public: Retrieves demand and full load hours data for the region.
    # Expects to load a file at datasets/AREA/central_producers.csv.
    #
    # For example:
    #   dataset.central_producers.
    #     get(:energy_production_algae_diesel :full_load_hours)
    #   # => 4194.5
    #
    # Returns a CSVDocument.
    def central_producers
      @cental_prod ||= CSVDocument.new(
        dataset_dir.join('central_producers.csv'))
    end

    # Public: Retrieves demand and max demand data for the region. Expects to
    # load a file at datasets/AREA/primary_production.csv.
    #
    # For example:
    #   dataset.primary_production.
    #     get(:energy_production_bio_oil, :demand)
    #   # => 0.0
    #
    # Returns a CSVDocument.
    def primary_production
      @primary_prod ||= CSVDocument.new(
        dataset_dir.join('primary_production.csv'))
    end

    # Public: Retrieves the demand data for the file whose name matches +key+.
    #
    # key - The name of the demand file to load.
    #
    # For example:
    #   dataset.demands(:industry).get(:final_demand_coal_gas) # => 0.4
    #
    # Returns a CSVDocument::OneDimensional.
    def demands(key)
      key = key.to_sym

      (@demands ||= {})[key] ||=
        CSVDocument::OneDimensional.new(
          dataset_dir.join("demands/#{ key }.csv"))
    end

    # Public: Path to the directory in which the dataset specific data is
    # stored.
    #
    # Returns a Pathname.
    def dataset_dir
      Atlas.data_dir.join(DIRECTORY).join(key.to_s)
    end

  end # Dataset
end # Atlas
