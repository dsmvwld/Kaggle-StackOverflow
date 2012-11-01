# Makefile for Kaggle competition
# hh 24aug12
# hh 31oct12 tweaks for actual public/private switch

# location of training and leaderboard files
DATA=./data

# leaderboard selector
#PREFIX=public
#TRAIN=train
#TRAINS=train-sample
PREFIX=private
TRAIN=train_October_9_2012
TRAINS=train-sample_October_9_2012_v2

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

submission.csv: $(TRAINS)-f.csv $(PREFIX)_leaderboard-f.csv priors.R sample-priors.R predicto.R
	$(R) -q --no-restore --no-save --args $(PREFIX)_leaderboard-f.csv <predicto.R

%-f.csv: $(DATA)/%.csv fex.rb
	$(RUBY) fex.rb $< $@

priors.R: priors.rb
	$(RUBY) $< $(DATA)/$(TRAIN).csv priors >$@

sample-priors.R: priors.rb
	$(RUBY) $< $(DATA)/$(TRAINS).csv sample.priors >$@

clean:
	rm -f *-f.csv *.xdr submission.* model.zip

.PHONY: clean
