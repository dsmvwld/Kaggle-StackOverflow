# partition.rb
# hh 09oct12

require 'csv'

# column indices within train.csv
STATUS = 14
PARTITIONS = 'not a real question,not constructive,off topic,open,too localized'.split(',')

$count = Hash.new(0)

def written(status)
  $count[status] += 1
  s = PARTITIONS.collect {|p| "%5d" % $count[p] }.join("   ")
  $stderr.printf("\r" + s)
end

def partition(fn)
  first = true
  i = 0   # counts open entries
  CSV.foreach(fn) {|row|
    if first
      $files.values.each {|csv| csv << row }
      first = false
    else
      status = row[STATUS]
      if status == 'open'
        if (i % 10) == 0
          $files[status] << row
          written(status)
        end
        i += 1
      else
        $files[status] << row
        written(status)
      end
    end
  }
end

if $0 == __FILE__
  if ARGV.size != 1
    $stderr.puts "usage: ruby #{File.basename $0} training.csv"
    exit 1
  end
  $files = Hash.new
  PARTITIONS.each {|p| $files[p] = CSV.open(p.gsub(/ /, '-')+'.par', 'wb') }
    start = Time.now
      partition(ARGV.shift)
    elapsed = Time.now-start
  $files.values.each {|csv| csv.close }
  $stderr.printf "partitioned in %6.1f seconds\n", elapsed
end
