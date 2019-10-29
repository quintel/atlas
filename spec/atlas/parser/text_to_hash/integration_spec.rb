require 'spec_helper'

module Atlas::Parser::TextToHash; describe '(integration)' do
  let(:hash) { Base.new(content.strip_heredoc).to_hash }

  describe 'with a document containing only static attributes' do
    let(:content) do
      <<-EOF
        - up     = down
        - leet   = 1337
        - answer = 42.0
        - goal   = 3.5e2
        - who    = [ troy, abed ]
        - a.b    = testing
        - a.c    = considered harmful
      EOF
    end

    it 'parses strings' do
      expect(hash).to include(up: 'down')
    end

    it 'parses integers' do
      expect(hash).to include(leet: 1337)
    end

    it 'parses floats' do
      expect(hash).to include(answer: 42.0)
    end

    it 'parses scientific notation floats' do
      expect(hash).to include(goal: 350.0) # ppm
    end

    it 'parses arrays' do
      expect(hash).to include(who: %w( troy abed )) # in the morning
    end

    it 'parses hashes' do
      expect(hash).to include(a: { b: 'testing', c: 'considered harmful' })
    end

    it 'has no queries' do
      expect(hash).to include(queries: {})
    end

    it 'has no comments' do
      expect(hash).to include(comments: nil)
    end
  end

  # --------------------------------------------------------------------------

  context 'with a document containing a comment' do
    let(:content) do
      <<-EOF
        # This is the first line of the comment.
        # This is the second line of the comment.
        #
        #   a should be b
        #
        # This is the final line of the comment.

        - a = b
      EOF
    end

    it 'parses the comment' do
      expect(hash).to include(comments: <<-EOF.strip_heredoc.chomp("\n"))
        This is the first line of the comment.
        This is the second line of the comment.

          a should be b

        This is the final line of the comment.
      EOF
    end

    it 'parses the sole attribute' do
      expect(hash).to include(a: 'b')
    end

    it 'does not have any queries' do
      expect(hash).to include(queries: {})
    end
  end

  # --------------------------------------------------------------------------

  context 'with a document containing a multi-line attribute' do
    let(:content) do
      <<-EOF
        - prologue = start

        - ode =
            Felis catus is your taxonomic nomenclature,
            An endothermic quadruped, carnivorous by nature;
            Your visual, olfactory, and auditory senses
            Contribute to your hunting skills and natural defenses.

        - epilogue = finish
      EOF
    end

    it 'parses the first one-line attribute' do
      expect(hash).to  include(prologue: 'start')
    end

    it 'parses the second one-line attribute' do
      expect(hash).to include(epilogue: 'finish')
    end

    it 'parses the multi-line attribute' do
      expect(hash).to include(ode: <<-EOF.strip_heredoc.chomp("\n"))
        Felis catus is your taxonomic nomenclature,
        An endothermic quadruped, carnivorous by nature;
        Your visual, olfactory, and auditory senses
        Contribute to your hunting skills and natural defenses.
      EOF
    end
  end

  # --------------------------------------------------------------------------

  context 'with a document containing a single-line query' do
    let(:content) do
      <<-EOF
        - load   = tape
        ~ update = SUM(1, 2)
      EOF
    end

    it 'parses the static attribute' do
      expect(hash).to include(load: 'tape')
    end

    it 'parses the query' do
      expect(hash).to include(queries: { update: 'SUM(1, 2)' })
    end
  end

  # --------------------------------------------------------------------------

  context 'with a document containing a multi-line query' do
    let(:content) do
      <<-EOF
        - load   = tape
        ~ update =
            SUM(
              SUM(1, 2)
              MAX(3, 4))
      EOF
    end

    it 'parses the static attribute' do
      expect(hash).to include(load: 'tape')
    end

    it 'parses the query' do
      query = "SUM(\n  SUM(1, 2)\n  MAX(3, 4))"
      expect(hash).to include(queries: { update: query })
    end
  end

  # --------------------------------------------------------------------------

  context 'with a document containing a multi-line, multi-spaced query' do
    let(:content) do
      <<-EOF
        ~ update =
            SUM(


              SUM(1, 2)
              MAX(3, 4))
      EOF
    end

    it 'parses the query' do
      query = "SUM(\n\n\n  SUM(1, 2)\n  MAX(3, 4))"
      expect(hash).to include(queries: { update: query })
    end
  end

end ; end
