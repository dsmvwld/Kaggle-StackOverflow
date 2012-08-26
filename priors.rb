#!/usr/bin/env ruby
# priors.rb -- extract priors from full training file
# hh 26aug12

require 'csv'

# column indices within train.csv
STATUS = 14

def priors(ifn, var)
  counts = Hash.new(0)
  CSV.foreach(ifn) {|row|
    counts[row[STATUS]] += 1
  }
  counts.delete('OpenStatus')
  n = counts.values.inject(0) {|a,b| a+b }
  labels = counts.keys.sort
  puts '# ' + labels.join(',')
  puts '# ' +
    labels.collect {|label| counts[label].to_s }.join(',')
  puts var + ' <- c(' +
    labels.collect {|label| (counts[label].to_f/n).to_s }.join(',') +
    ')'
  return n
end

if $0 == __FILE__
  if ARGV.size != 2
    $stderr.puts "usage: ruby #{File.basename $0} training.csv variable"
    exit 1
  end
  start = Time.now
  n = priors(*ARGV.shift(2))
  elapsed = Time.now-start
  $stderr.printf "priors extracted for %d entries, in %6.1f seconds\n", n, elapsed
end
