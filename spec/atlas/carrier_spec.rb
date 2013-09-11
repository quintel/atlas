require 'spec_helper'

module Atlas

  describe Carrier do

    it 'loads some fixtures' do
      expect(Carrier.all).to have_at_least(1).item
    end

  end

end
