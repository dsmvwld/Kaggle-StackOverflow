# Makefile for Kaggle competition
# hh 24aug12

# location of training and leaderboard files
DATA=./data

# leaderboard selector
PREFIX=public
#PREFIX=private

# needs Ruby 1.9
RUBY=ruby

# uses R 2.14.1 with rf 4.6-6
R=R

all: submission.csv.gz model.zip

model.zip: Makefile fex.rb priors.rb predicto.R
	zip $@ $^

submission.csv.gz: submission.csv
	cp $< x.csv
	gzip -9 -f $<

submission.csv: train-sample-f.csv $(PREFIX)_leaderboard-f.csv priors.R sample-priors.R predicto.R
	$(R) -q --no-restore --no-save --args $(PREFIX)_leaderboard-f.csv <predicto.R

%-f.csv: $(DATA)/%.csv fex.rb
	$(RUBY) fex.rb $< $@

priors.R: #priors.rb
	$(RUBY) $< $(DATA)/train.csv priors >$@

sample-priors.R: priors.rb
	$(RUBY) $< $(DATA)/train-sample.csv sample.priors >$@

clean:
	rm -f *-f.csv *.xdr submission.* model.zip

.PHONY: clean
