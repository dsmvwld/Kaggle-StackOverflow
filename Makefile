# Makefile for Kaggle competition
# hh 24aug12

# location of training and leaderboard files
DATA=data

# needs Ruby 1.9
RUBY=ruby

# uses R 2.14.1 with rf 4.6-6
R=R

all: submission.csv

submission.csv: train-sample-f.csv public_leaderboard-f.csv predicto.R
	$(R) -q --no-restore --no-save <predicto.R

%-f.csv: $(DATA)/%.csv fex.rb
	$(RUBY) fex.rb $< $@

clean:
	rm -f *-f.csv submission.csv

.PHONY: clean
