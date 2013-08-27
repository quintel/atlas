namespace :import do
  desc <<-DESC
    Import the region data from the old format to ActiveDocument.

    Currently restricted to NL, UK, and DE.
  DESC
  task :datasets, [:from, :to] => [:setup] do |_, args|
    include Atlas

    # Wipe out *everything* in the edges directory; rather than simply
    # overwriting existing files, since some may have new naming conventions
    # since the previous import.
    Dataset.all.each(&:destroy!)

    from     = Pathname.new(args.from)
    datasets = from.join('datasets')
    runner   = ImportRun.new('datasets')

    defaults = YAML.load_file(datasets.join('_defaults/area.yml'))

    %w( nl uk de ).each do |region|
      country_data = YAML.load_file(datasets.join("#{ region }/area.yml"))
      country_data = defaults.deep_merge(country_data)[:area][:area_data]

      runner.item do
        Dataset.new(country_data.merge(path: "#{ region }/#{ region }.ad"))
      end
    end

    runner.finish
  end # :datasets
end # :import
