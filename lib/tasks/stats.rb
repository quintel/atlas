# frozen_string_literal: true

namespace :stats do
  namespace :queries do
    desc <<-DESC
      Get statistics on how many times a gquery is used in other gqueries.

      It creates a report in Markdown to the STDOUT, so you might

      rake stats:queries:unused LIST=/tmp/my_list.txt > ~/Downloads/report.md
    DESC

    task :unused do
      include Atlas
      Atlas.data_dir = '../etsource'

      (file_path = ENV['LIST']) || raise("Please provide LIST='path/to/file'")
      (list      = IO.readlines(file_path).map { |x| x.chomp }) || raise("Cannot read file #{file_path}")
      queries = Atlas::Gquery.all.map(&:query)

      matches = []

      list.each_with_index do |line, _idx|
        queries.each do |q|
          matches << line if q.match(line)
        end
      end

      puts "# Used queries found (##{matches.uniq.size})\n"

      puts matches.uniq.map { |m| "* #{m}\n" }

      puts

      puts "# Unused queries found (##{(list - matches.uniq).size})\n"

      puts (list - matches.uniq).map { |m| "* #{m}\n" }
    end
  end
end
