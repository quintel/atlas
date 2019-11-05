module Atlas
  module ActiveDocument
    # Asserts that an attribute refererencing another document contains the key
    # of a document which exists.
    class DocumentReferenceValidator < ActiveModel::Validator
      def validate(record)
        key = record.public_send(options[:attribute])

        validate_presence(record, key, options)
        validate_reference(record, key, options)
      end

      private

      def validate_presence(record, key, options)
        return if key.to_s.length.positive?

        record.errors.add(
          options[:attribute],
          "must contain a reference to a #{ref_name(options[:class_name])}"
        )
      end

      def validate_reference(record, key, options)
        return unless key # Already caught by presence validator.

        klass = options[:class_name].constantize

        return if klass.exists?(key)

        record.errors.add(
          options[:attribute],
          "references a #{ref_name(options[:class_name])} which does not exist"
        )
      end

      def ref_name(class_name)
        class_name.demodulize.underscore.humanize.downcase
      end
    end
  end
end
