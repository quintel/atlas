module Atlas
  # FinalDemandNode has access to the EnergyBalance through the
  # energy_balance_query.
  class Node::FinalDemand < Node::Demand
    validates_with QueryValidator, attributes: [:demand]
  end
end
