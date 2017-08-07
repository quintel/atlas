module Atlas
  module ValueObject
    def self.included(base)
      base.class_eval do
        include Virtus.value_object
        include Last
      end
    end

    # Methods which should override those added by Virtus.value_object.
    module Last
      # Public: The storage details as a hash, with any nil attributes not
      # present.
      #
      # Returns a hash.
      def to_hash
        attrs = attributes
        attrs.delete_if { |_, value| value.nil? }

        attrs
      end
    end
  end # ValueObject
end # Atlas
