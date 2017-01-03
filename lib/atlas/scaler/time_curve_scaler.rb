module Atlas
  class Scaler::TimeCurveScaler
    def self.call(*args)
      new(*args).scale
    end

    def initialize(base_dataset, scaling_factor, derived_dataset)
      @base_dataset = base_dataset
      @scaling_factor = scaling_factor
      @derived_dataset = derived_dataset
    end

    def scale
      FileUtils.mkdir_p(@derived_dataset.time_curves_dir)
      @base_dataset.time_curves.each do |key, base_csv|
        CSV.open(@derived_dataset.time_curve_path(key), 'w', headers: true, write_headers: true) do |scaled_csv|
          headers = base_csv.table.headers
          scaled_csv << headers

          base_csv.table.each do |row|
            scaled_csv << row.map do |header, value|
              header == :year ?
                value :
                value * @scaling_factor
            end
          end
        end
      end
    end
  end # Scaler::TimeCurveScaler
end # Atlas
