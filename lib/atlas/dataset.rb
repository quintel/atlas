module Atlas
  class Dataset
    include ActiveDocument

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

    attribute :has_agriculture,                             Boolean, default: true
    attribute :has_buildings,                               Boolean, default: true
    attribute :has_coastline,                               Boolean, default: true
    attribute :has_cold_network,                            Boolean, default: false
    attribute :has_electricity_storage,                     Boolean, default: true
    attribute :has_employment,                              Boolean, default: true
    attribute :has_industry,                                Boolean, default: true
    attribute :has_lignite,                                 Boolean, default: false
    attribute :has_merit_order,                             Boolean, default: false
    attribute :has_metal,                                   Boolean, default: true
    attribute :has_mountains,                               Boolean, default: true
    attribute :has_old_technologies,                        Boolean, default: false
    attribute :has_other,                                   Boolean, default: true
    attribute :has_solar_csp,                               Boolean, default: false
    attribute :has_offshore_solar,                          Boolean, default: false
    attribute :has_other_emissions_section,                 Boolean, default: true
    attribute :has_import_export,                           Boolean, default: true
    attribute :use_network_calculations,                    Boolean, default: true
    attribute :use_merit_order_demands,                     Boolean, default: true
    attribute :has_weather_curves,                          Boolean, default: false
    attribute :has_aggregated_chemical_industry,            Boolean, default:true
    attribute :has_detailed_chemical_industry,              Boolean, default:false
    attribute :has_coal_oil_for_heating_built_environment,  Boolean, default:false

    # Numeric Data
    # ------------

    # These attributes are constants, and are expected to be the same regardless
    # of whether we're calculating the entire region, or simulating a smaller
    # sub-region.

    [ :buildings_insulation_employment_constant,
      :households_insulation_employment_constant,
      :co2_emission_1990_aviation_bunkers,
      :co2_emission_1990_marine_bunkers,
      :co2_emissions_of_imported_electricity_g_per_kwh,
      :co2_percentage_free,
      :co2_price,
      :offshore_ccs_potential_mt_per_year,
      :economic_multiplier,
      :employment_fraction_production,
      :employment_local_fraction,
      :export_electricity_primary_demand_factor,
      :import_electricity_primary_demand_factor,
      :man_hours_per_man_year,
      :investment_hv_net_low,
      :investment_hv_net_high,
      :investment_hv_net_per_turbine,
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
      :insulation_terraced_houses_start_value,
      :insulation_buildings_start_value,
      :typical_roof_surface_corner_house_available_for_pv,
      :typical_roof_surface_terraced_house_available_for_pv,
      :typical_roof_surface_detached_house_available_for_pv,
      :typical_roof_surface_semi_detached_house_available_for_pv,
      :typical_roof_surface_apartment_available_for_pv,
      :typical_useful_demand_space_heating_corner_house,
      :typical_useful_demand_space_heating_detached_house,
      :typical_useful_demand_space_heating_semi_detached_house,
      :typical_useful_demand_space_heating_terraced_house,
      :typical_useful_demand_space_heating_apartment,
      :heat_demand_reduction_medium_insulation_corner_house,
      :heat_demand_reduction_medium_insulation_detached_house,
      :heat_demand_reduction_medium_insulation_semi_detached_house,
      :heat_demand_reduction_medium_insulation_terraced_house,
      :heat_demand_reduction_medium_insulation_apartments,
      :heat_demand_reduction_high_insulation_corner_house,
      :heat_demand_reduction_high_insulation_detached_house,
      :heat_demand_reduction_high_insulation_semi_detached_house,
      :heat_demand_reduction_high_insulation_terraced_house,
      :heat_demand_reduction_high_insulation_apartments,
      :heat_demand_reduction_high_insulation_buildings,
      :heat_share_of_apartments_with_block_heating,
      :heat_households_indoor_pipelines_investment_costs_with_block_heating_eur,
      :heat_households_indoor_pipelines_investment_costs_without_block_heating_eur,
      :heat_buildings_indoor_investment_costs_eur_per_kw,
      :heat_buildings_heat_meter_investment_costs_eur_per_kw,
      :heat_buildings_heat_meter_investment_costs_eur_per_connection,
      :heat_exchanger_station_investment_costs_eur_per_kw,
      :heat_sub_station_investment_costs_eur_per_kw,
      :heat_distribution_pipelines_investment_costs_eur_per_meter,
      :heat_length_of_distribution_pipelines_in_meter_per_residence_object_first_bracket,
      :heat_length_of_distribution_pipelines_in_meter_per_residence_object_second_bracket,
      :heat_length_of_distribution_pipelines_in_meter_per_residence_object_third_bracket,
      :heat_length_of_distribution_pipelines_in_meter_per_residence_object_fourth_bracket,
      :heat_length_of_distribution_pipelines_in_meter_per_residence_object_fifth_bracket,
      :heat_length_of_connection_pipelines_in_meter_per_residence_first_bracket,
      :heat_length_of_connection_pipelines_in_meter_per_residence_second_bracket,
      :heat_length_of_connection_pipelines_in_meter_per_residence_third_bracket,
      :heat_length_of_connection_pipelines_in_meter_per_residence_fourth_bracket,
      :heat_length_of_connection_pipelines_in_meter_per_residence_fifth_bracket,
      :heat_primary_pipelines_investment_costs_per_kw,
      :heat_yearly_indoor_infrastructure_maintenance_costs_factor,
      :heat_yearly_outdoor_infrastructure_maintenance_costs_factor
    ].each do |name|
      attribute name, Float
    end

    attribute :electric_vehicle_profile_1_share, Float, default: 1.0
    attribute :electric_vehicle_profile_2_share, Float, default: 0.0
    attribute :electric_vehicle_profile_3_share, Float, default: 0.0
    attribute :electric_vehicle_profile_4_share, Float, default: 0.0
    attribute :electric_vehicle_profile_5_share, Float, default: 0.0

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
      :total_land_area,
      :number_of_buildings,
      :number_of_cars,
      :number_of_residences,
      :number_of_inhabitants,
      :offshore_suitable_for_wind,
      :residences_roof_surface_available_for_pv,
      :buildings_roof_surface_available_for_pv,
      :energetic_emissions_other_ghg_industry,
      :energetic_emissions_other_ghg_energy,
      :energetic_emissions_other_ghg_transport,
      :energetic_emissions_other_ghg_buildings,
      :energetic_emissions_other_ghg_households,
      :energetic_emissions_other_ghg_agriculture,
      :non_energetic_emissions_co2_chemical_industry,
      :non_energetic_emissions_co2_other_industry,
      :non_energetic_emissions_co2_agriculture_manure,
      :non_energetic_emissions_co2_agriculture_soil_cultivation,
      :non_energetic_emissions_co2_waste_management,
      :non_energetic_emissions_other_ghg_chemical_industry,
      :non_energetic_emissions_other_ghg_other_industry,
      :non_energetic_emissions_other_ghg_agriculture_fermentation,
      :non_energetic_emissions_other_ghg_agriculture_manure,
      :non_energetic_emissions_other_ghg_agriculture_soil_cultivation,
      :non_energetic_emissions_other_ghg_agriculture_other,
      :non_energetic_emissions_other_ghg_waste_management,
      :indirect_emissions_co2,
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
        :electric_vehicle_profile_3_share,
        :electric_vehicle_profile_4_share,
        :electric_vehicle_profile_5_share
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
        CSVDocument::OneDimensional.read(path_resolver.resolve("shares/#{key}.csv"))
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
        CSVDocument::OneDimensional.read(
          path_resolver.resolve("efficiencies/#{key}_efficiency.csv")
        )
    end

    # Public: Gets the InsulationCostCSV for the given house type. The CSV is a
    # matrix of present and future insulation levels and the associated cost of
    # upgrading a household or building from one level to another.
    #
    # Returns a Dataset::InsulationCostCSV.
    def insulation_costs(type)
      (@insulation_costs ||= {})[type.to_sym] ||= InsulationCostCSV.read(
        path_resolver.resolve("real_estate/insulation_costs_#{type}.csv")
      )
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
    #   # => #<Pathname .../nl/curves/river.csv>
    #
    # Returns a Pathname.
    def load_profile_path(key)
      path_resolver.resolve("curves/#{key}.csv")
    end

    # Public: If the Merit library has been loaded, returns the
    # Merit::LoadProfile containing the values of the named curve.
    #
    # key - The name of the load curve file path to read.
    #
    # Returns a Merit::Curve.
    def load_profile(key)
      Util.load_curve(load_profile_path(key))
    end

    # Public: A collection containing all of the curve sets which belong to the
    # dataset.
    #
    # Returns a CurveSetCollection.
    def curve_sets
      @curve_sets ||= CurveSetCollection.at_path(path_resolver.join('curves'))
    end

    # Public: Retrieves and caches data about carriers from the carriers.csv file.
    #
    # Returns a CSVDocument.
    def carriers
      @carrier_data ||= CSVDocument.read(path_resolver.resolve('carriers.csv'))
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
      @central_producers ||= CSVDocument.read(path_resolver.resolve('central_producers.csv'))
    end

    # Public: A set of demands required for use inside ETlocal
    #
    # Returns a CSVDocument
    def parent_values
      @parent_values ||= CSVDocument.read(path_resolver.resolve('demands/parent_values.csv'))
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
      @primary_production ||= CSVDocument.read(path_resolver.resolve('primary_production.csv'))
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
        CSVDocument::OneDimensional.read(path_resolver.resolve("demands/#{key}.csv"))
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

    # Public: Returns an object which can resolve paths to files within the dataset. This serves
    # little purpose in Dataset itself, but is useful for Dataset::Derived where the lack of a file
    # means the file from the parent should be used instead.
    def path_resolver
      @path_resolver ||= PathResolver.create(*resolve_paths)
    end

    private

    # Internal: Paths used to look for CSV and other dataset-related files.
    def resolve_paths
      [dataset_dir]
    end
  end
end
