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
    attribute :from_molecules,       NodeAttributes::MoleculesToEnergy

    # Numeric attributes.
    %i[
      electricity_output_capacity
      forecasting_error
      free_co2_factor
      ccs_capture_rate
      heat_output_capacity
      households_supplied_per_unit
      land_use_per_unit
      part_load_efficiency_penalty
      part_load_operating_point
      sustainability_share
      takes_part_in_ets
      max_consumption_price
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
    validate :validate_primary_demand_sustainable

    private

    # Internal: Asserts that primary_energy_demand nodes have enough information - either on the
    # output carriers or the node itself - to calculate sustainability_share in ETEngine.
    def validate_primary_demand_sustainable
      return unless groups.include?(:primary_energy_demand)
      return unless sustainability_share.nil?

      out_edges = Atlas::EnergyEdge.all.select { |edge| edge.supplier == key }
      carriers = out_edges.map(&:carrier).uniq - [:loss]

      blank_slots = carriers.any? { |carrier| Atlas::Carrier.find(carrier).sustainable.nil? }

      # blank_slots = out_slots.any? do |slot|
      #   slot.carrier != loss && Atlas::Carrier.find(slot.carrier).sustainable.nil?
      # end

      return unless blank_slots

      errors.add(
        :sustainability_share,
        'must not be blank on a primary_energy_demand node when one or more output carriers do ' \
        'not define a `sustainable` value'
      )
    end
  end
end
