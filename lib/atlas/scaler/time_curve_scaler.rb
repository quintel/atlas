module Atlas
  class Scaler::TimeCurveScaler
    # Public: Scales (a copy of) the time curves of a base dataset and
    # saves them to a derived dataset
    #
    # @base_dataset    - An Atlas::Dataset, whose time curves will be used as base
    # @derived_dataset - An Atlas::Dataset, into whose directory the new scaled
    #                    time curves will be saved as csv files
    #
    def self.call(*args)
      new(*args).scale
    end

    private_class_method :new

    def initialize(base_dataset, derived_dataset)
      @base_dataset    = base_dataset
      @derived_dataset = derived_dataset
      @scaling_factor  = derived_dataset.scaling.factor
    end

    # Public: Scales the curves and saves them to new csv files
    #
    # Returns an array of scaled time curves
    def scale
      @base_dataset.time_curves.map do |key, csv|
        scale_time_curve(key, csv)
      end
    end

    private

    def scale_time_curve(time_curve_key, csv)
      scaled_csv =
        CSVDocument.new(
          @derived_dataset.time_curve_path(time_curve_key),
          csv.column_keys
        )
      copy_csv_content(csv, scaled_csv) { |val| (val * @scaling_factor).to_f }
      scaled_csv.save!
    end

    def copy_csv_content(src, dest)
      row_keys = src.row_keys
      column_keys = src.column_keys[1..-1] # Omit the row key column

      row_keys.each do |row_key|
        column_keys.each do |column_key|
          value = yield src.get(row_key, column_key)
          dest.set(row_key, column_key, value)
        end
      end
    end
  end # Scaler::TimeCurveScaler
end # Atlas
