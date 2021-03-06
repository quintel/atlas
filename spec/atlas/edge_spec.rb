require 'spec_helper'

module Atlas
  describe Edge do
    let(:node_class) do
      Class.new do
        include Atlas::Node

        def self.name
          'TestNode'
        end
      end
    end

    let(:klass) do
      Class.new do
        include Atlas::Edge

        def self.graph_config
          GraphConfig::Config.new(:test, self, TestNode)
        end

        def self.name
          'TestEdge'
        end
      end
    end

    before { stub_const('TestNode', node_class) }

    it 'must have a consumer' do
      expect(klass.new(key: 'a-b@gas').errors_on(:consumer)).to include('does not exist')
    end

    it 'must have a supplier' do
      expect(klass.new(key: 'a-b@gas').errors_on(:supplier)).to include('does not exist')
    end

    describe 'type' do
      valid_types = [ :share, :flexible, :constant,
                      :inversed_flexible, :dependent ]

      valid_types.each do |type|
        it "is permitted to be #{ type.inspect }" do
          edge = klass.new(key: 'a-b@gas', type: type)
          expect(edge.errors_on(:type).length).to eq(0)
        end
      end

      it 'may not be blank' do
        edge = klass.new(key: 'a-b@gas', type: nil)
        expect(edge.errors_on(:type).length).to eq(1)
      end

      it 'may not be any other value' do
        edge = klass.new(key: 'a-b@gas', type: :nope)
        expect(edge.errors_on(:type).length).to eq(1)
      end
    end

    describe 'when creating a new Edge' do
      let(:edge) { klass.new(path: 'left-right@gas.ad') }

      it 'sets the consumer from the filename' do
        expect(edge.consumer).to eq(:right)
      end

      it 'sets the supplier from the filename' do
        expect(edge.supplier).to eq(:left)
      end

      it 'sets the carrier from the filename' do
        expect(edge.carrier).to eq(:gas)
      end

      it 'sets the edge key' do
        expect(edge.key).to eq(:'left-right@gas')
      end

      it 'sets the filename' do
        expect(edge.path.to_s).to match(%r{left-right@gas\.ad$})
      end
    end

    context 'creating an edge with supplier, consumer, and carrier' do
      let(:edge) do
        klass.new(supplier: 'here', consumer: 'there',
                  carrier: 'talk', ns: 'listen')
      end

      it 'sets the supplier' do
        expect(edge.supplier).to eq(:here)
      end

      it 'sets the consumer' do
        expect(edge.consumer).to eq(:there)
      end

      it 'sets the carrier' do
        expect(edge.carrier).to eq(:talk)
      end

      it 'sets the key' do
        expect(edge.key).to eq(:'here-there@talk')
      end

      it 'sets the path' do
        expect(edge.path.to_s).to match(%r{/listen/here-there@talk\.ad$})
      end
    end

    context 'validation of associated documents' do
      it 'has an error when the carrier does not exist' do
        edge = klass.new(key: 'a-b@nope').tap(&:valid?)
        expect(edge.errors[:carrier]).to include('does not exist')
      end

      it 'has an error when the supplier does not exist' do
        edge = klass.new(key: 'a-b@nope').tap(&:valid?)
        expect(edge.errors[:supplier]).to include('does not exist')
      end

      it 'has an error when the consumer does not exist' do
        edge = klass.new(key: 'a-b@nope').tap(&:valid?)
        expect(edge.errors[:consumer]).to include('does not exist')
      end
    end

    describe 'creating an Edge with an invalid key' do
      it 'does not raise an error when the key is nil' do
        expect { klass.new(key: nil) }.not_to raise_error
      end

      it 'raises an error when the key is blank' do
        expect { klass.new(key: '') }.to raise_error(InvalidKeyError)
      end

      it 'raises an error when the key has only one edge' do
        expect { klass.new(key: 'left@gas') }.to raise_error(InvalidKeyError)
      end

      it 'raises an error when one edge key is blank' do
        expect { klass.new(key: 'left-@gas') }.to raise_error(InvalidKeyError)
      end

      it 'raises an error when omitting the carrier' do
        expect { klass.new(key: 'one-two') }.to raise_error(InvalidKeyError)
      end

      it 'raises an error when providing only the carrier' do
        expect { klass.new(key: '@gas') }.to raise_error(InvalidKeyError)
      end
    end

    describe 'changing the key on an Edge' do
      let(:edge) { klass.new(key: 'left-right@gas') }

      context 'changing the supplier node only' do
        before { edge.key = 'left-other@gas' }

        it { expect(edge.key).to eq(:'left-other@gas') }
        it { expect(edge.supplier).to eq(:left) }
        it { expect(edge.consumer).to eq(:other) }
        it { expect(edge.carrier).to eq(:gas) }
        it { expect(edge.path.to_s).
               to match(%{left-other@gas\.ad$}) }
      end

      context 'changing the consumer node only' do
        before { edge.key = 'other-right@gas' }

        it { expect(edge.key).to eq(:'other-right@gas') }
        it { expect(edge.supplier).to eq(:other) }
        it { expect(edge.consumer).to eq(:right) }
        it { expect(edge.path.to_s).to match(%{other-right@gas\.ad$}) }
      end

      context 'changing the carrier only' do
        before { edge.key = 'left-right@electricity' }

        it { expect(edge.key).to eq(:'left-right@electricity') }
        it { expect(edge.supplier).to eq(:left) }
        it { expect(edge.consumer).to eq(:right) }
        it { expect(edge.carrier).to eq(:electricity) }
        it { expect(edge.path.to_s).
               to match(%{left-right@electricity\.ad$}) }
      end

      context 'changing both nodes with a string' do
        before { edge.key = 'one-two@electricity' }

        it { expect(edge.key).to eq(:'one-two@electricity') }
        it { expect(edge.supplier).to eq(:one) }
        it { expect(edge.consumer).to eq(:two) }
        it { expect(edge.carrier).to eq(:electricity) }
        it { expect(edge.path.to_s).
               to match(%{one-two@electricity\.ad$}) }
      end

      context 'changing both nodes using a symbol' do
        before { edge.key = :'one-two@gas' }

        it { expect(edge.key).to eq(:'one-two@gas') }
        it { expect(edge.supplier).to eq(:one) }
        it { expect(edge.consumer).to eq(:two) }
        it { expect(edge.carrier).to eq(:gas) }
        it { expect(edge.path.to_s).to match(%{one-two@gas\.ad$}) }
      end

      context 'changing one of the key components' do
        before { edge.supplier = :nine }

        it { expect(edge.key).to eq(:'nine-right@gas') }
        it { expect(edge.supplier).to eq(:nine) }
        it { expect(edge.path.to_s).to match(%{nine-right@gas\.ad$}) }
      end

      it 'raises an error when omitting the supplier key' do
        expect { edge.key = 'left-@gas' }.to raise_error(InvalidKeyError)
      end

      it 'raises an error when omitting the producer key' do
        expect { edge.key = '-right@gas' }.to raise_error(InvalidKeyError)
      end

      it 'raises an error when providing only one node key' do
        expect { edge.key = 'one@gas' }.to raise_error(InvalidKeyError)
      end

      it 'raises an error when omitting the carrier' do
        expect { edge.key = 'one-two' }.to raise_error(InvalidKeyError)
      end

      it 'raises an error when providing only the carrier' do
        expect { edge.key = '@gas' }.to raise_error(InvalidKeyError)
      end

      it 'raises an error if the key is blank' do
        expect { edge.key = '' }.to raise_error(InvalidKeyError)
      end

      it 'raises an error if the key is nil' do
        expect { edge.key = nil }.to raise_error(InvalidKeyError)
      end
    end

    describe 'changing the filename' do
      let(:edge) { klass.new(key: 'left-right@gas') }

      before { edge.path = 'no-yes@electricity.ad' }

      it 'updates the file path' do
        expect(edge.path.to_s).to match(/no-yes@electricity\.ad$/)
      end

      it 'updates the supplier node' do
        expect(edge.supplier).to eq(:no)
      end

      it 'updates the consumer node' do
        expect(edge.consumer).to eq(:yes)
      end

      it 'updates the carrier' do
        expect(edge.carrier).to eq(:electricity)
      end

      it 'updates the key' do
        expect(edge.key).to eq(:'no-yes@electricity')
      end
    end

    describe 'parsing an AD file' do
      before do
        FileUtils.mkdir_p(klass.directory)
        File.write(klass.directory.join('a-b@c.ad'), content)
      end

      let(:content) do
        <<~DOC
          - type = share
          - parent_share = 0.5
        DOC
      end

      let(:edge) { klass.find('a-b@c') }

      it 'sets the supplier' do
        expect(edge.supplier).to eq(:a)
      end

      it 'sets the consumer' do
        expect(edge.consumer).to eq(:b)
      end

      it 'sets the carrier' do
        expect(edge.carrier).to eq(:c)
      end

      it 'sets the type' do
        expect(edge.type).to eq(:share)
      end

      it 'sets attributes' do
        expect(edge.parent_share).to eq(0.5)
      end

      context 'when a query is present' do
        let(:content) do
          <<~DOC
            - type = share
            ~ parent_share = SHARE(cars, gasoline)
          DOC
        end

        it 'sets the query when one is present' do
          expect(klass.find('a-b@c').queries[:parent_share]).to eq('SHARE(cars, gasoline)')
        end
      end
    end
  end
end
