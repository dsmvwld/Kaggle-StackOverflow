library(randomForest)
ts <- read.csv("train-sample-f.csv")
response <- ts$Status; ts$Status <- NULL
ids <- ts$PostId; ts$PostId <- NULL
priors <- c(0.00913, 0.00465, 0.00520, 0.979, 0.00183)
set.seed(4711)
rf <- randomForest(ts, response, ntree=71, classwt=priors, do.trace=TRUE)
# n.b. rf$importance
#repred <- predict(rf, ts, type="prob")
#reclassified <- predict(rf, ts, type="response")
lead <- read.csv("public_leaderboard-f.csv")
id <- lead$PostId; lead$PostId <- NULL
lead$Status <- NULL
pred <- predict(rf, lead, type="prob")
result <- cbind(id, pred)
write.csv(result, "submission.csv", quote=FALSE, row.names=FALSE)
