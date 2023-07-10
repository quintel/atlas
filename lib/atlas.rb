require 'yaml'
require 'pathname'
require 'delegate'

require 'bundler'
Bundler.setup(:default)

require 'refinery'

require 'active_model'
require 'csv'
require 'gpgme'
require 'rubel'
require 'turbine'
require 'virtus'

require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/string/strip'

require_relative 'atlas/base'
require_relative 'atlas/parser/hash_to_text_parser'

require_relative 'atlas/parser/text_to_hash/line'
require_relative 'atlas/parser/text_to_hash/line_grouper'
require_relative 'atlas/parser/text_to_hash/block'
require_relative 'atlas/parser/text_to_hash/block/comment_block'
require_relative 'atlas/parser/text_to_hash/block/multi_line_block'
require_relative 'atlas/parser/text_to_hash/block/single_line_block'
require_relative 'atlas/parser/text_to_hash/base'
require_relative 'atlas/parser/identifier'

require_relative 'atlas/errors'
require_relative 'atlas/energy_unit'
require_relative 'atlas/util'

require_relative 'atlas/csv_document'

require_relative 'atlas/active_document/persistence'
require_relative 'atlas/active_document/finders'
require_relative 'atlas/active_document/naming'
require_relative 'atlas/active_document/subclassing'
require_relative 'atlas/active_document/manager'
require_relative 'atlas/active_document/production_manager'
require_relative 'atlas/active_document/associated_validator'
require_relative 'atlas/active_document/document_reference_validator'
require_relative 'atlas/active_document/query_validator'
require_relative 'atlas/active_document/residences_validator'
require_relative 'atlas/active_document/share_attribute_validator'
require_relative 'atlas/active_document/share_group_validator'
require_relative 'atlas/active_document/share_group_total_validator'
require_relative 'atlas/active_document/preset_share_group_total_validator'
require_relative 'atlas/active_document'
require_relative 'atlas/collection'
require_relative 'atlas/value_object'

require_relative 'atlas/config'
require_relative 'atlas/edge'
require_relative 'atlas/energy_edge'
require_relative 'atlas/molecule_edge'
require_relative 'atlas/input_helper'
require_relative 'atlas/input'
require_relative 'atlas/initializer_input'
require_relative 'atlas/gquery'
require_relative 'atlas/energy_balance'
require_relative 'atlas/carrier'
require_relative 'atlas/graph_builder'
require_relative 'atlas/graph_config'
require_relative 'atlas/graph_values'
require_relative 'atlas/runner'
require_relative 'atlas/runner/scale_attributes'
require_relative 'atlas/runner/set_attributes_from_graph_values'
require_relative 'atlas/runner/set_rubel_attributes'
require_relative 'atlas/runner/set_slot_shares_from_efficiency'
require_relative 'atlas/runner/zero_disabled_sectors'
require_relative 'atlas/runner/zero_molecule_leaves'
require_relative 'atlas/runner/zero_molecule_nodes'
require_relative 'atlas/debug_runner'
require_relative 'atlas/user_sortable_validator'
require_relative 'atlas/path_resolver'
require_relative 'atlas/preset/scaling'
require_relative 'atlas/preset'

require_relative 'atlas/dataset'
require_relative 'atlas/dataset/curve_set'
require_relative 'atlas/dataset/curve_set_collection'
require_relative 'atlas/dataset/derived'
require_relative 'atlas/dataset/full'
require_relative 'atlas/dataset/insulation_cost_csv'

require_relative 'atlas/scaler'
require_relative 'atlas/scaler/area_attributes_scaler'

require_relative 'atlas/node_attributes/electricity_merit_order'
require_relative 'atlas/node_attributes/graph_connection'
require_relative 'atlas/node_attributes/fever'
require_relative 'atlas/node_attributes/merit_order'
require_relative 'atlas/node_attributes/reconciliation'
require_relative 'atlas/node_attributes/storage'

require_relative 'atlas/node'
require_relative 'atlas/energy_node/fever_validator'
require_relative 'atlas/energy_node'
require_relative 'atlas/energy_node/converter'
require_relative 'atlas/energy_node/demand'
require_relative 'atlas/energy_node/final_demand'
require_relative 'atlas/molecule_node'

require_relative 'atlas/slot'
require_relative 'atlas/slot/dynamic'
require_relative 'atlas/slot/elastic'
require_relative 'atlas/slot/carrier_efficient'

require_relative 'atlas/runtime'

require_relative 'atlas/exporter'
require_relative 'atlas/exporter/carrier_exporter'
require_relative 'atlas/exporter/graph_exporter'

require_relative 'atlas/term/reporter'

require_relative 'atlas/production_mode'
require_relative 'atlas/scenario_reconciler'
require_relative 'atlas/sparse_graph_query'

ActiveSupport::Inflector.inflections do |inflect|
  # Otherwise "loss".classify => "Los"
  inflect.singular 'loss', 'loss'
end
