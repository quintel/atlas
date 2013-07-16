namespace :import do
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
    FileUtils.rm_rf(Atlas::Node.directory)

    runner = ImportRun.new('carriers')

    path = $from_dir.join('datasets/_defaults/carriers/defaults.yml')
    data = YAML.load_file(path)

    data.each do |key, cdata|
      runner.item do
        cdata ||= Hash.new

        cdata[:key]         = key
        cdata[:infinite]    = cdata[:infinite] == 1.0
        cdata[:sustainable] = cdata[:sustainable] == 1.0

        Carrier.new(cdata)
      end
    end

    runner.finish

    Rake::Task['validate:carriers'].invoke(args.to)
  end # :carriers
end # :import
