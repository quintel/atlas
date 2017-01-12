module Atlas
  # Scales (a copy of) the time curves of a base dataset and
  # saves them to a derived dataset
  #
  # @base_dataset    - An Atlas::Dataset, whose time curves will be used as base
  # @scaling_factor  - The time curves will be scaled down by this factor
  # @derived_dataset - An Atlas::Dataset, into whose directory the new scaled
  #                    time curves will be saved as csv files
  class Scaler::TimeCurveScaler
    # Public: Scales the curves and saves them to new csv files
    #
    # Returns nil
    def self.call(*args)
      new(*args).scale
    end

    def initialize(base_dataset, scaling_factor, derived_dataset)
      @base_dataset = base_dataset
      @scaling_factor = scaling_factor
      @derived_dataset = derived_dataset
    end

    # Public: Scales the curves and saves them to new csv files
    #
    # Returns nil
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
      nil
    end
  end # Scaler::TimeCurveScaler
end # Atlas
