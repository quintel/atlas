namespace :yaml do
  desc <<-DESC
    Import carriers from the old format to ActiveDocument.

    Reads the legacy carriers/defaults.yml file and creates new-style
    ActiveDocument files for each carrier. Regional variations are not yet
    included.
  DESC
  task :carriers, [:from, :to] => [:setup] do |_, args|
    include Atlas

    # Wipe out *everything* in the nodes directory; rather than simply
    # overwriting existing files, since some may have new naming conventions
    # since the previous import.
    FileUtils.rm_rf(Atlas::Carrier.directory)

    runner = ImportRun.new('carriers')
    ds     = $from_dir.join('datasets')

    defaults = YAML.load_file(ds.join('_defaults/carriers/defaults.yml'))
    colors   = YAML.load_file(ds.join('_defaults/carriers/graphviz.yml'))
    country  = YAML.load_file(ds.join('nl/carriers.yml'))[:carriers]

    data = [defaults, colors, country].reduce({}) do |hash, other|
      hash.deep_merge(other.reject { |_, v| v.nil? }.symbolize_keys)
    end

    data.each do |key, cdata|
      runner.item do
        cdata ||= Hash.new
        cdata.symbolize_keys!

        cdata[:key]      = key
        cdata[:infinite] = cdata[:infinite] == 1.0

        if cdata[:fce]
          new_fce = cdata[:fce].map do |fce|
            [ fce['origin_country'].to_sym,
              fce.except('origin_country').symbolize_keys ]
          end

          cdata[:fce] = Hash[new_fce]
        end

        Carrier.new(cdata)
      end
    end

    runner.finish

    Rake::Task['validate:carriers'].invoke(args.to)
  end # :carriers
end # :yaml
