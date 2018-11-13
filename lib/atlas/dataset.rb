module Atlas
  class Dataset
    include ActiveDocument

    DIRECTORY = 'datasets'

    # General Attributes
    attribute :area,      String
    attribute :id,        Integer
    attribute :parent_id, Integer
    attribute :group,     Symbol, default: :unsorted

    # Set to false in the document to disable the region in ETModel.
    attribute :enabled,   Hash[Symbol => Boolean],
                          default: { etengine: true, etmodel: true }

    attribute :analysis_year, Integer, default: 2011

    # Flags
    # -----

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
    attribute :has_import_export,        Boolean, default: true
    attribute :use_network_calculations, Boolean, default: true
    attribute :use_merit_order_demands,  Boolean, default: true
    attribute :has_aggregated_chemical_industry,  Boolean, default:true
    attribute :has_detailed_chemical_industry,    Boolean, default:false
    attribute :has_aggregated_other_industry,     Boolean, default:true
    attribute :has_detailed_other_industry,       Boolean, default:false

    # Numeric Data
    # ------------

    # These attributes are constants, and are expected to be the same regardless
    # of whether we're calculating the entire region, or simulating a smaller
    # sub-region.

    [ :buildings_insulation_constant_1,
      :buildings_insulation_constant_2,
      :buildings_insulation_cost_constant,
      :buildings_insulation_employment_constant,
      :co2_emission_1990_aviation_bunkers,
      :co2_emission_1990_marine_bunkers,
      :co2_emissions_of_imported_electricity_g_per_kwh,
      :co2_percentage_free,
      :co2_price,
      :ccs_cost_in_industry,
      :economic_multiplier,
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
      :new_houses_insulation_constant_1,
      :new_houses_insulation_constant_2,
      :new_houses_insulation_cost_constant,
      :new_houses_insulation_employment_constant,
      :old_houses_insulation_constant_1,
      :old_houses_insulation_constant_2,
      :old_houses_insulation_cost_constant,
      :old_houses_insulation_employment_constant,
      :man_hours_per_man_year,
      :technical_lifetime_insulation,
      :investment_hv_net_low,
      :investment_hv_net_high,
      :investment_hv_net_per_turbine,
      :insulation_profile_fraction_new_houses,
      :insulation_profile_fraction_old_houses,
      :lv_net_spare_capacity,
      :lv_net_total_costs_present,
      :lv_net_costs_per_capacity_step,
      :lv_net_capacity_per_step,
      :mv_net_spare_capacity,
      :mv_net_total_costs_present,
      :mv_net_costs_per_capacity_step,
      :mv_net_capacity_per_step,
      :hv_net_spare_capacity,
      :hv_net_total_costs_present,
      :hv_net_costs_per_capacity_step,
      :hv_net_capacity_per_step,
      :lv_mv_trafo_spare_capacity,
      :lv_mv_trafo_total_costs_present,
      :lv_mv_trafo_costs_per_capacity_step,
      :lv_mv_trafo_capacity_per_step,
      :mv_hv_trafo_spare_capacity,
      :mv_hv_trafo_total_costs_present,
      :mv_hv_trafo_costs_per_capacity_step,
      :mv_hv_trafo_capacity_per_step,
      :interconnection_net_costs_present,
      :offshore_net_costs_present,
      :flh_solar_pv_solar_radiation_max,
      :hydrogen_electrolysis_solar_pv_capacity_ratio,
      :insulation_detached_houses_low_share,
      :insulation_detached_houses_medium_share,
      :insulation_detached_houses_high_share,
      :insulation_apartments_low_share,
      :insulation_apartments_medium_share,
      :insulation_apartments_high_share,
      :insulation_semi_detached_houses_low_share,
      :insulation_semi_detached_houses_medium_share,
      :insulation_semi_detached_houses_high_share,
      :insulation_corner_houses_low_share,
      :insulation_corner_houses_medium_share,
      :insulation_corner_houses_high_share,
      :insulation_terraced_houses_low_share,
      :insulation_terraced_houses_medium_share,
      :insulation_terraced_houses_high_share,
      :insulation_detached_houses_start_value,
      :insulation_semi_detached_houses_start_value,
      :insulation_apartments_start_value,
      :insulation_corner_houses_start_value,
      :insulation_terraced_houses_start_value
    ].each do |name|
      attribute name, Float
    end

    attribute :electric_vehicle_profile_1_share, Float, default: 1.0
    attribute :electric_vehicle_profile_2_share, Float, default: 0.0
    attribute :electric_vehicle_profile_3_share, Float, default: 0.0

    attribute :solar_pv_profile_1_share, Float, default: 1.0
    attribute :solar_pv_profile_2_share, Float, default: 0.0

    # These attributes are relative to the size of the region. If we simulate a
    # sub-region (say, 5% of the "full" region size), these attributes can be
    # reduced in proportion to the sub-region size.

    [ :annual_infrastructure_cost_electricity,
      :annual_infrastructure_cost_gas,
      :areable_land,
      :capacity_buffer_decentral_in_mj_s,
      :capacity_buffer_in_mj_s,
      :co2_emission_1990,
      :co2_emission_2009,
      :coast_line,
      :interconnector_capacity,
      :land_available_for_solar,
      :number_of_buildings,
      :number_of_cars,
      :number_of_residences,
      :number_of_inhabitants,
      :number_of_existing_households,
      :number_of_new_residences,
      :number_of_old_residences,
      :offshore_suitable_for_wind,
      :onshore_suitable_for_wind,
      :residences_roof_surface_available_for_pv,
      :buildings_roof_surface_available_for_pv,
      :other_emission_agriculture,
      :other_emission_built_environment,
      :other_emission_transport,
      :other_emission_industry_energy,
      :number_of_detached_houses,
      :number_of_apartments,
      :number_of_semi_detached_houses,
      :number_of_corner_houses,
      :number_of_terraced_houses
    ].each do |name|
      attribute name, Float, proportional: true
    end

    validates :interconnector_capacity, numericality: true

    validates_with ResidencesValidator

    validates_with ShareAttributeValidator,
      group: :electric_vehicle_profile_share,
      attributes: [
        :electric_vehicle_profile_1_share,
        :electric_vehicle_profile_2_share,
        :electric_vehicle_profile_3_share
      ]

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

    def time_curves_dir
      dataset_dir.join('time_curves')
    end

    def time_curve_path(key)
      time_curves_dir.join("#{ key }_time_curve.csv")
    end

    # Public: Retrieves the time curve data for the file whose name matches
    # +key+.
    #
    # key - The name of the time curve file to load.
    #
    # For example:
    #   dataset.time_curve(woody_biomass).get(2011, :max_demand) # => 34.0
    #
    # Returns a CSVDocument.
    def time_curve(key)
      (@time_curves ||= {})[key.to_sym] ||=
        CSVDocument.new(time_curve_path(key))
    end

    # Public: Retrieves all the time curves for the dataset's region.
    #
    # Returns a hash of document keys, and the CSVDocuments.
    def time_curves
      Pathname.glob(time_curves_dir.join('*.csv')).each do |csv_path|
        time_curve(csv_path.basename('_time_curve.csv').to_s)
      end

      @time_curves ||= {}
    end

    # Public: Retrieves the load profile data for the file whose name matches
    # the given +key+.
    #
    # Public: Given the +key+ of a load profile, returns the path to the CSV
    # file containing the values. This file can be read into a
    # Merit::LoadProfile.
    #
    # key - The name of the load curve file path to create.
    #
    # For example:
    #   dataset.load_profile_path(:river)
    #   # => #<Pathname .../nl/load_profiles/river.csv>
    #
    # Returns a Pathname.
    def load_profile_path(key)
      dataset_dir.join("load_profiles/#{ key }.csv")
    end

    # Public: If the Merit library has been loaded, returns the
    # Merit::LoadProfile containing the values of the named curve.
    #
    # key - The name of the load curve file path to read.
    #
    # Returns a Merit::LoadProfile.
    def load_profile(key)
      Merit::LoadProfile.load(load_profile_path(key))
    rescue NameError => ex
      raise(ex.message.match(/Merit$/) ? MeritRequired.new : ex)
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

    # Public: A set of demands required for use inside ETlocal
    #
    # Returns a CSVDocument
    def parent_values
      @parent_values ||= CSVDocument.new(
        dataset_dir.join('demands').join('parent_values.csv'))
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

    # Public: Retrieves the FCE data for the file matching +key+.
    #
    # key - The name of the FCE file to load.
    #
    # Returns a hash.
    def fce(key)
      key = key.to_sym

      (@fce ||= {})[key] ||=
        YAML.load_file(dataset_dir.join("fce/#{key}.yml"))
          .symbolize_keys.transform_values(&:symbolize_keys)
    end

    # Public: Path to the directory in which the dataset specific data is
    # stored.
    #
    # Returns a Pathname.
    def dataset_dir
      path.parent
    end

    # Public: Removes the dataset and all associated files.
    #
    # Returns true or false.
    def destroy!
      super
      FileUtils.rm_rf(dataset_dir)
    end
  end # Dataset
end # Atlas
