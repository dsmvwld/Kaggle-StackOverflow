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
  s.downcase.gsub(/[^a-z0-9 ]/, '').squeeze.split.each {|w| answer[w] += 1 }
  answer
end

def avg_key_len(h)
  return 0 if h.empty?
  h.keys.collect {|k| k.length * h[k] }.sum / h.size
end

def word_lengths(h)
  s, m, l = 0, 0, 0
  x = nil
  h.keys.each {|k|
    x = k.length
    if x <= 4
      s += 1
    elsif x <= 8
      m += 1
    else
      l += 1
    end
  }
  return s, m, l
end

def analyze(title, body, tags)
  answer = Hash.new
  n = body.length
  answer[:whiteish] = body.count(" \t") * 100.0 / n
  answer[:codish] = body.count(';<>()[]{}=') * 100.0 / n
  answer[:upperish] = body.count('A-Z') * 100.0 / n
  answer[:lowerish] = body.count('a-z') * 100.0 / n
  answer[:digitish] = body.count('0-9') * 100.0 / n
  answer[:punctish] = body.count('.,:!?') * 100.0 / n
  answer[:markupish] = body.count('<>/') * 100.0 / n
  body_d = tally(body)
  title_d = tally(title)
  tags_d = tally(tags.join(' '))
  answer[:body_words] = body_d.values.sum
  answer[:tags_vocab] = tags_d.keys.size
  answer[:title_vocab] = title_d.keys.size
  answer[:body_vocab] = body_d.keys.size
  answer[:co_tags_body] = (tags_d.keys & body_d.keys).size  #.collect {|k| body_d[k] }.sum
  answer[:co_tags_title] = (tags_d.keys & title_d.keys).size
  answer[:co_title_body] = (title_d.keys & body_d.keys).size
  answer[:avg_body_word_len] = avg_key_len(body_d)
  answer[:avg_title_word_len] = avg_key_len(title_d)
  answer[:avg_tags_word_len] = avg_key_len(tags_d)
  s, m, l = word_lengths(body_d)
  answer[:words_s_body] = s
  answer[:words_m_body] = m
  answer[:words_l_body] = l
  s, m, l = word_lengths(title_d)
  answer[:words_s_title] = s
  answer[:words_m_title] = m
  answer[:words_l_title] = l
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
        # FIXME body is still in Markdown format, should convert or strip
        textish = analyze(title, body, tags)
        #
        out << [row[POST_ID], row[USER_REPUTATION], row[USER_ANSWERS],
          posted.mday, posted.month, sunday7(posted.wday), roundh(posted),
          joined.mday, joined.month, sunday7(joined.wday), roundh(joined),
          title.length, body.length, body_lines, tags.size,
          textish[:whiteish], textish[:codish], textish[:upperish],
          textish[:lowerish], textish[:digitish], textish[:punctish],
          textish[:markupish],
          textish[:body_words],
          textish[:body_vocab], textish[:title_vocab], textish[:tags_vocab],
          textish[:co_tags_body], textish[:co_tags_title], textish[:co_title_body],
          textish[:avg_body_word_len], textish[:avg_title_word_len], textish[:avg_tags_word_len],
          textish[:words_s_body], textish[:words_m_body], textish[:words_l_body],
          textish[:words_s_title], textish[:words_m_title], textish[:words_l_title],
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
          BodyWords
          BodyVocab TitleVocab TagsVocab
          CoTagsBody CoTagsTitle CoTitleBody
          AvgBodyWordLen AvgTitleWordLen AvgTagsWordLen
          WordsSBody WordsMBody WordsLBody
          WordsSTitle WordsMTitle WordsLTitle
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
