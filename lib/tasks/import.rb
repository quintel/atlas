# frozen_string_literal: true

desc <<-DESC
  Import ETDataset CSVs from ../etdataset

  This is an alias for the :import task in ETSource, and requires that Atlas,
  ETDataset, and ETSource all have a common parent directory:

  - Code
    - atlas
    - etdataset
    - etsource

  Defaults to importing all datasets. Provide an optional DATASET environment
  variable to only import one:

  DATASET=de rake import
DESC
task :import do
  cd '../etsource'
  exec 'bundle exec rake import'
end
