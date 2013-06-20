require 'yaml'
require 'csv'
require 'pathname'
require 'delegate'

require 'active_model'
require 'rubel'
require 'turbine'
require 'virtus'

require_relative 'tome/base'
require_relative 'tome/parser/hash_to_text_parser'
require_relative 'tome/parser/text_to_hash_parser'
require_relative 'tome/errors'
require_relative 'tome/energy_unit'
require_relative 'tome/util'

require_relative 'tome/csv_document'

require_relative 'tome/active_document/persistence'
require_relative 'tome/active_document/finders'
require_relative 'tome/active_document/naming'
require_relative 'tome/active_document/subclassing'
require_relative 'tome/active_document/manager'
require_relative 'tome/active_document'
require_relative 'tome/collection'

require_relative 'tome/edge'
require_relative 'tome/input'
require_relative 'tome/gquery'
require_relative 'tome/dataset'
require_relative 'tome/energy_balance'
require_relative 'tome/carrier'
require_relative 'tome/graph_builder'
require_relative 'tome/runner'
require_relative 'tome/preset'

require_relative 'tome/node'
require_relative 'tome/node/converter'
require_relative 'tome/node/demand'
require_relative 'tome/node/final_demand'
require_relative 'tome/node/stat'

require_relative 'tome/slot'
require_relative 'tome/slot/elastic'
require_relative 'tome/slot/carrier_efficient'

require_relative 'tome/runtime'
require_relative 'tome/exporter'

require_relative 'tome/term/reporter'

ActiveSupport::Inflector.inflections do |inflect|
  # Otherwise "loss".classify => "Los"
  inflect.singular 'loss', 'loss'
end
