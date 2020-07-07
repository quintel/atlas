MANIP_CLASS_NAMES = %w[Carrier EnergyEdge EnergyNode Input Gquery]

namespace :manip do
  # Given an Atlas document class, returns the properties which a user may set
  # on it using environment variables.
  def property_names(klass)
    props = klass.public_instance_methods.select do |name|
      name.to_s.match(/^[a-z]/) && name.to_s[-1] == '='
    end

    props.map { |name| name.to_s[0..-2] }
  end

  # Given a short class name ("EnergyEdge", "EnergyNode", etc), returns the corresponding
  # class.
  def klass(class_name)
    Atlas.const_get(class_name)
  end

  # ----------------------------------------------------------------------------

  MANIP_CLASS_NAMES.each do |class_name|
    namespace class_name.downcase do
      task create: :environment do
        klass = klass(class_name)
        keys  = property_names(klass)
        attrs = ENV.to_h.slice(*keys)

        # Temporary workaround for the custom edge key format.
        if klass == Atlas::EnergyEdge && ! attrs.key?('key')
          attrs[:key] = Atlas::Edge.key(ENV['from'], ENV['to'], ENV['carrier'])
        end

        doc = klass.create!(attrs)

        puts "Saved to #{ doc.path.relative_path_from(Atlas.data_dir) }"
      end

      task delete: :environment do
        klass(class_name).find(ENV['key']).destroy!
      end
    end
  end
end

# Top-level tasks for each class.
MANIP_CLASS_NAMES.each do |class_name|
  namespace class_name.downcase do
    desc "Create a new #{ class_name.downcase }"
    task create: ["manip:#{ class_name.downcase }:create"]

    desc "Delete a #{ class_name.downcase }"
    task destroy: ["manip:#{ class_name.downcase }:destroy"]
  end
end
