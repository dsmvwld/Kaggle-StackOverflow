#!/usr/bin/env ruby
# fex.rb -- feature extractor for Kaggle competition
# hh 24aug12
# hh 31aug12 added content-based features (body/title)

require 'csv'
require 'date'

class Array
  def sum
    inject(0) {|a,b| a+b }
  end
end

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

def tally(s)
  answer = Hash.new(0)
  s.gsub(/[^A-Za-z0-9 ]/, '').squeeze.split.each {|w| answer[w] += 1 }
  answer
end

def avg_key_len(h)
  return 0 if h.empty?
  h.keys.collect {|k| k.length * h[k] }.sum / h.size
end

def analyze(title, body, tags)
  answer = Hash.new
  n = body.length
  answer[:whiteish] = body.count(" \t") / n
  answer[:codish] = body.count(';<>()[]{}=') / n
  answer[:upperish] = body.count('A-Z') / n
  answer[:lowerish] = body.count('a-z') / n
  answer[:digitish] = body.count('0-9') / n
  answer[:punctish] = body.count('.,:!?') / n
  answer[:markupish] = body.count('<>/') / n
  body_d = tally(body)
  title_d = tally(title)
  tags_d = tally(tags.join(' '))
  answer[:body_words] = body_d.values.sum
  answer[:co_tags_body] = (tags_d.keys & body_d.keys).collect {|k| body_d[k] }.sum
  answer[:co_tags_title] = (tags_d.keys & title_d.keys).collect {|k| body_d[k] }.sum
  answer[:avg_body_word_len] = avg_key_len(body_d)
  answer[:avg_title_word_len] = avg_key_len(title_d)
  answer[:avg_tags_word_len] = avg_key_len(tags_d)
  answer
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
        user_age_d = (posted-joined).floor  # in whole days
        user_age_d = 180 if user_age_d < 0  # migrated users, assume half year
        user_age_h = ((posted-joined)*24).floor
        user_age_h = 180*24 if user_age_h < 0
        body_lines = body.count("\n")
        textish = analyze(title, body, tags)
        #
        out << [row[POST_ID], row[USER_REPUTATION], row[USER_ANSWERS],
          posted.mday, posted.month, sunday7(posted.wday), roundh(posted),
          joined.mday, joined.month, sunday7(joined.wday), roundh(joined),
          title.length, body.length, body_lines, tags.size,
          textish[:whiteish], textish[:codish], textish[:upperish],
          textish[:lowerish], textish[:digitish], textish[:punctish],
          textish[:markupish],
          textish[:body_words], textish[:co_tags_body], textish[:co_tags_title],
          textish[:avg_body_word_len], textish[:avg_title_word_len], textish[:avg_tags_word_len],
          user_age_d, user_age_h, row[STATUS]]
      else
        order = Hash.new
        row.each_with_index {|col,i| order[col] = i }
        out << %w(PostId UserRep UserAnswers
          PostDay PostMonth PostWeekday PostHour 
          JoinDay JoinMonth JoinWeekday JoinHour 
          TitleChars BodyChars BodyLines NumTags
          Whiteish Codeish Upperish
          Lowerish Digitish Punctish
          Markupish
          BodyWords CoTagsBody CoTagsTitle
          AvgBodyWordLen AvgTitleWordLen AvgTagsWordLen
          UserAgeDays UserAgeHours Status)
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
