#!/usr/bin/env ruby
# fex.rb -- feature extractor for Kaggle competition
# hh 24aug12

require 'csv'
require 'date'

# column indices within train-sample.csv
POST_ID = 0
POST_CREATED = 1
USER_CREATED = 3
USER_REPUTATION = 4
USER_ANSWERS = 5
TITLE = 6
BODY = 7
TAG1 = 8
POST_CLOSED = 13
STATUS = 14

def to_datetime(s)
  begin
    DateTime.strptime(s, '%m/%d/%Y %H:%M:%S')
  rescue ArgumentError
    p s
    DateTime.strptime(s, '%Y-%m-%d')
  end
end

def sunday7(wday)
  (wday-1) % 7 + 1
end

def roundh(datetime)
  (datetime.hour + (datetime.minute > 29 ? 1 : 0)) % 24
end

def fex(ifn, ofn)
  order = nil
  n = 0
  CSV.open(ofn, "w") {|out|
    CSV.foreach(ifn) {|row|
      if order
        n += 1
        posted = to_datetime(row[POST_CREATED])
        joined = to_datetime(row[USER_CREATED])
        title = row[TITLE]
        body = row[BODY]
        tags = row[TAG1, 5].reject {|t| t.nil? }
        #
        user_age = (posted-joined).floor  # in whole days
        user_age = 180 if user_age < 0    # migrated users, assume half year
        codish = body.count(';<>()[]{}')
        body_lines = body.count("\n")
        #
        out << [row[POST_ID], row[USER_REPUTATION], row[USER_ANSWERS],
          posted.mday, posted.month, sunday7(posted.wday), roundh(posted),
          joined.mday, joined.month, sunday7(joined.wday), roundh(joined),
          title.length, body.length, body_lines, tags.size, codish,
          user_age, row[STATUS]]
      else
        order = Hash.new
        row.each_with_index {|col,i| order[col] = i }
        out << %w(PostId UserRep UserAnswers
          PostDay PostMonth PostWeekday PostHour 
          JoinDay JoinMonth JoinWeekday JoinHour 
          TitleChars BodyChars BodyLines NumTags Codish
          UserAge Status)
      end
    }
  }
  return n
end

if $0 == __FILE__
  if ARGV.size != 2
    $stderr.puts "usage: ruby #{File.basename $0} training.csv features.csv"
    exit 1
  end
  start = Time.now
  n = fex(*ARGV.shift(2))
  elapsed = Time.now-start
  printf "features extracted for %d entries, in %6.1f seconds\n", n, elapsed
  printf "(%d entries per minute, %8.6f seconds per entry)\n", n/(elapsed/60), elapsed/n
  printf "(3.5M entries would take %d minutes)\n", (elapsed/n)*3_500_000/60
end
