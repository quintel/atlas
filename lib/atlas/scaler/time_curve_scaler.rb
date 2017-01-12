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
      @base_dataset.time_curves.each do |key, base_csv|
        row_keys = base_csv.row_keys
        column_keys = base_csv.column_keys

        scaled_csv = CSVDocument.new(@derived_dataset.time_curve_path(key), column_keys)
        row_keys.each do |row_key|
          column_keys.each do |column_key|
            base_value = base_csv.get(row_key, column_key)
            scaled_csv.set(row_key, column_key, base_value * @scaling_factor)
          end
        end
        scaled_csv.save!
      end
    end
  end # Scaler::TimeCurveScaler
end # Atlas
