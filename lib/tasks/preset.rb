namespace :preset do

  desc <<-DESC
    Take a scenario_id from a server and convert it to an
    ActiveDocument Preset.

    Required parameters:
      * SERVER = et-engine.com/beta-engine.com/etengine.dev
      * ID = the scenario id that was used

    Optional parameters
      * KEY = key for the scenario to be saved

    Example:

       rake preset:create SERVER=et-engine.com ID=347837
  DESC

  task :create do
    include Atlas
    require 'httparty'
    require 'active_support/core_ext/hash/indifferent_access'

    Atlas.data_dir = '../etsource/data'

    data = retrieve_preset_data!(ENV['SERVER'], ENV['ID']).with_indifferent_access

    data[:key] = ENV['KEY'] || data[:id].to_s

    preset = Atlas::Preset.new(data)
    preset.save!
  end

  def retrieve_preset_data!(server_path, scenario_id)
    url = "http://#{ server_path }/api/v3/scenarios/#{ scenario_id }?detailed=true"
    HTTParty.get(url)
  end

end
