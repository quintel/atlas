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

    server = ENV['SERVER'] || 'et-engine.com'
    id     = ENV['ID']     || 'please provide which (scenario) ID!'

    puts "Retrieving data from #{ server } for scenario_id=#{ id }"

    data = retrieve_preset_data!(server, id).with_indifferent_access

    data[:key] = ENV['KEY'] || data[:id].to_s

    data[:user_values] = prune_user_values(data[:user_values])

    preset = Atlas::Preset.new(data)
    preset.save!

    puts "Scenario saved in #{ preset.path }"
    puts "Done!"
  end

  def retrieve_preset_data!(server_path, scenario_id)
    url = "http://#{ server_path }/api/v3/scenarios/#{ scenario_id }?detailed=true"
    HTTParty.get(url)
  end

  def prune_user_values(user_values)
    user_values.inject({}) do |memory, (key, value)|
      if Atlas::Input.manager.key?(key)
        memory[key] = value
      else
        puts "WARNING: #{ key } not found in Inputs and has been DROPPED!!!"
      end
      memory
    end
  end

end
