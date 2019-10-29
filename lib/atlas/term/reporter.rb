module Atlas
  module Term
    class Reporter
      # Public: An all-in-one reporting method for lazy developers.
      #
      # For example
      #
      #   Reporter.report('Sorting', good: :green, bad: :red) do |reporter|
      #     100.times { reporter.inc(:good) }
      #     20.times  { reporter.inc(:bad)  }
      #   end
      #
      #   # => "Sorting: 100 good, 20 bad"
      #
      # Returns the result as a coloured string for the terminal.
      def self.report(title, groups, &block)
        new(title, groups).report(&block)
      end

      # Public: Creates a new reporter. Provide a title which will preceed the
      # information about each group.
      #
      # For example
      #
      #   Reporter.new('Import progress', passed: :green, failed: :red)
      #
      # Returns the reporter.
      def initialize(title, groups)
        @title    = title
        @groups   = groups
        @counters = Hash.new { |hash, key| hash[key.to_sym] = 0 }
      end

      # Public: Wrap the "thing" being reported in the block, and #report will
      # handle set-up and teardown of the output.
      #
      # Returns the result as a coloured string.
      def report
        refresh!
        yield self
        refresh!(true)

        result
      rescue Exception => ex
        refresh!(true) # Clear any output.
        fail ex
      end

      # Public: Increments the counter for the given +group_name+ and updates
      # the display in the terminal.
      #
      # Returns nothing.
      def inc(group_name)
        @counters[group_name.to_sym] += 1
        refresh!
      end

      # Public: Contains the results of the report, formatted with colours for
      # the terminal.
      #
      # Returns a string.
      def result
        visible_groups.map do |name, color|
          ::Term::ANSIColor.public_send(color) do
            "#{ @counters[name] } #{ name }"
          end
        end.join(', ')
      end

      private

      # Internal: Refreshes the report to the user by erasing the previous
      # report line and showing the latest counters. Outputs to $stdout.
      #
      # Returns nothing.
      def refresh!(final = false)
        $stdout.print "#{ @title }: #{ result }"

        # If this is not the final report, a carriage return will tell the
        # terminal to overwrite the line we just printed the next time a
        # refresh happens.
        $stdout.print "\r" unless final
        $stdout.puts       if     final

        $stdout.flush
      end

      # Internal: The groups to be shown to the user; groups whose count is
      # zero are not shown.
      #
      # Returns a hash of group names and the colour to use.
      def visible_groups
        @groups.reject { |name, *| @counters[name].zero? }
      end
    end
  end
end
