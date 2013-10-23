namespace :yaml do
  desc <<-DESC
    Import presets from the old format to ActiveDocument.

    This starts by *deleting* everything in data/presets on the assumption
    that there are no hand-made changes.
  DESC
  task :presets, [:from, :to] => [:setup] do |_, args|
    include Atlas

    # Wipe out *everything* in the presets directory.
    FileUtils.rm_rf(Preset.directory)

    original_dir = $from_dir.join('presets')
    runner       = ImportRun.new('presets')

    Pathname.glob(original_dir.join('**/*.yml')) do |path|
      runner.item do
        relative = path.relative_path_from(original_dir)
        hash     = YAML.load_file(path)
        doc_path = relative.to_s.gsub(/\.yml$/, '')

        Preset.new(hash.merge(path: doc_path))
      end
    end

    runner.finish

    Rake::Task['validate:presets'].invoke(args.to)
  end # :presets
end # :yaml
