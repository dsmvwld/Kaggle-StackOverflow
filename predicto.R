library(randomForest)
epsilon <- 0.001
source("priors.R")
source("sample-priors.R")

normalize <- function(probs, eps=epsilon) {
  neps <- 1-eps
  probs[probs > neps] <- neps
  probs[probs < eps] <- eps
  return(probs/rowSums(probs))
}

rescale <- function(old.priors, old.posteriors, new.priors, eps=epsilon) {
  old.posteriors <- normalize(old.posteriors, eps)
  # reshape priors after posteriors:
  n <- nrow(old.posteriors)
  old.priors <- t(array(old.priors, dim=c(5, n)))
  new.priors <- t(array(new.priors, dim=c(5, n)))
  # descale and rescale:
  evidence.ratio <- (old.priors * (1-old.posteriors)) / ((1-old.priors) * old.posteriors)
  new.posteriors <- new.priors / (new.priors + (1-new.priors)*evidence.ratio)
  new.posteriors <- normalize(new.posteriors, eps)
  return(new.posteriors)
}

args <- commandArgs(trailingOnly=TRUE)

ts <- read.csv("train-sample_October_9_2012_v2-f.csv")
response <- ts$Status
ts$Status <- NULL
ts$PostId <- NULL
set.seed(4711)
rf <- randomForest(ts, response, ntree=111, importance=TRUE, do.trace=TRUE)
importance <- rf$importance
save(importance, file="importance.xdr")
save(rf, file="rf.xdr")

lead <- read.csv(args[1]) # read feature CSV
id <- lead$PostId
lead$PostId <- NULL
lead$Status <- NULL
pred <- predict(rf, lead, type="prob")
pred <- rescale(sample.priors, pred, priors)

result <- cbind(id, pred)
write.csv(result, "submission.csv", quote=FALSE, row.names=FALSE)
