module Atlas
  class Dataset::FullDataset < Dataset
    def graph
      @graph ||= GraphBuilder.build
    end
  end # Dataset::FullDataset
end # Atlas
