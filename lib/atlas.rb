require 'yaml'
require 'csv'
require 'pathname'
require 'delegate'

require 'bundler'
Bundler.setup(:default)

require 'refinery'

require 'active_model'
require 'rubel'
require 'turbine'
require 'virtus'

require 'active_support/core_ext/string/strip'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/except'

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
require_relative 'atlas/active_document/query_validator'
require_relative 'atlas/active_document'
require_relative 'atlas/collection'
require_relative 'atlas/value_object'

require_relative 'atlas/edge'
require_relative 'atlas/input'
require_relative 'atlas/gquery'
require_relative 'atlas/energy_balance'
require_relative 'atlas/carrier'
require_relative 'atlas/graph_builder'
require_relative 'atlas/runner'
require_relative 'atlas/runner/set_slot_shares_from_efficiency'
require_relative 'atlas/runner/zero_disabled_sectors'
require_relative 'atlas/debug_runner'
require_relative 'atlas/preset/scaling'
require_relative 'atlas/preset'
require_relative 'atlas/scaler'
require_relative 'atlas/scaler/graph_exporter'
require_relative 'atlas/scaler/graph_persistor'

require_relative 'atlas/dataset'
require_relative 'atlas/dataset/derived_dataset'
require_relative 'atlas/dataset/full_dataset'

require_relative 'atlas/merit_order_details'
require_relative 'atlas/storage_details'

require_relative 'atlas/node/capacity_distribution_validator'
require_relative 'atlas/node'
require_relative 'atlas/node/converter'
require_relative 'atlas/node/demand'
require_relative 'atlas/node/central_producer'
require_relative 'atlas/node/final_demand'
require_relative 'atlas/node/stat'

require_relative 'atlas/slot'
require_relative 'atlas/slot/elastic'
require_relative 'atlas/slot/carrier_efficient'

require_relative 'atlas/runtime'
require_relative 'atlas/exporter'

require_relative 'atlas/term/reporter'

require_relative 'atlas/production_mode'
require_relative 'atlas/scenario_reconciler'

ActiveSupport::Inflector.inflections do |inflect|
  # Otherwise "loss".classify => "Los"
  inflect.singular 'loss', 'loss'
end
