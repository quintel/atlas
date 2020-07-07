# frozen_string_literal: true

require_relative 'node'

module Atlas
  # Describes a Node in the energy graph.
  class EnergyNode
    include Node

    directory_name 'graphs/energy/nodes'

    def self.graph_config
      GraphConfig.energy
    end

    attribute :has_loss,             Boolean
    attribute :energy_balance_group, String

    attribute :fever,                NodeAttributes::Fever
    attribute :heat_network,         NodeAttributes::MeritOrder
    attribute :hydrogen,             NodeAttributes::Reconciliation
    attribute :merit_order,          NodeAttributes::ElectricityMeritOrder
    attribute :network_gas,          NodeAttributes::Reconciliation
    attribute :storage,              NodeAttributes::Storage

    # Numeric attributes.
    %i[
      electricity_output_capacity
      forecasting_error
      free_co2_factor
      heat_output_capacity
      households_supplied_per_unit
      land_use_per_unit
      part_load_efficiency_penalty
      part_load_operating_point
      sustainability_share
      takes_part_in_ets
    ].each do |name|
      attribute name, Float
    end

    # (Numeric) attributes for costs
    %i[
      ccs_investment
      construction_time
      cost_of_installing
      decommissioning_costs
      fixed_operation_and_maintenance_costs_per_year
      initial_investment
      technical_lifetime
      variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour
      variable_operation_and_maintenance_costs_per_full_load_hour
      wacc
    ].each do |name|
      attribute name, Float
    end

    # (Numeric) attributes for employment
    %i[
      hours_maint_nl
      hours_place_nl
      hours_prep_nl
      hours_prod_nl
      hours_remov_nl
    ].each do |name|
      attribute name, Float
    end

    # Deprecated: Since a few months ago, electrical efficiency arrives as
    # separate attributes from the CSVs, but is converted into a hash by the
    # xls2yml script.
    attribute :electrical_efficiency_when_using_coal, Float
    attribute :electrical_efficiency_when_using_wood_pellets, Float

    validates_with Atlas::Node::FeverValidator
  end
end
