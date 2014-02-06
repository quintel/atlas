require 'spec_helper'

module Atlas

  describe Carrier do

    it 'loads some fixtures' do
      expect(Carrier.all).to have_at_least(1).item
    end

    describe '#fce' do
      it 'loads FCE data when present' do
        expect(Carrier.find(:coal).fce(:nl)).to_not be_empty
      end

      it 'does not load FCE data for a region with no data' do
        expect(Carrier.find(:coal).fce(:uk)).to_not be
      end

      it 'does not load FCE data for a carrier with no data' do
        expect(Carrier.find(:corn).fce(:nl)).to_not be
      end
    end # fce

  end

end
