require 'spec_helper'

module Atlas

  describe Carrier do

    it 'loads some fixtures' do
      expect(Carrier.all.length).not_to eq(0)
    end

    describe '#fce' do
      it 'loads FCE data when present' do
        expect(Carrier.find(:coal).fce(:nl)).not_to be_empty
      end

      it 'does not load FCE data for a region with no data' do
        expect(Carrier.find(:coal).fce(:uk)).not_to be
      end

      it 'does not load FCE data for a carrier with no data' do
        expect(Carrier.find(:corn).fce(:nl)).not_to be
      end
    end

  end

end
