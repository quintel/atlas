module Atlas
  module NodeAttributes
    # Contains information about energy storage within the node.
    class Storage
      include ValueObject

      values do
        # The total amount which may be stored, in Wh.
        attribute :volume, Float, writer: :public

        # The amount by which the stored amount decreases each hour, in W.
        attribute :decay, Float, default: 0.0, writer: :public

        # Cost per unit of volume installed.
        attribute :cost_per_mwh, Float, default: 0.0, writer: :public
      end
    end
  end
end
