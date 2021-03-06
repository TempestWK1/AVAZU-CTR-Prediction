setwd('C:/Users/Ivan.Liuyanfeng/Desktop/Data_Mining_Work_Space/VAZU')
gc(); rm(list=ls());
require(data.table);require(RMOA); require(caret)

train_app <- data.frame(fread('data/train_df_app_smooth.csv'))
train_app <- train_app[,-1]
head(train_app)

for (i in seq(dim(train_app)[2])){   
    train_app[which(train_app[[i]]==''),i] <- NaN   
}
for (i in seq(dim(train_app)[2])){   
    train_app[[i]] <- as.factor(train_app[[i]])   
}

# index <- createFolds(y = train_app$click, k = 10, list = F, returnTrain = FALSE)
# index <- createDataPartition(y = train_app$click, p = 0.8, list = F)
# train_dt <- train_app[index,]
# test_dt <- train_app[-index,]
# dim(train_dt);dim(test_dt);dim(train_app)
# rm(train_app)

### Naive Bayes ###
## Define a stream - e.g. a stream based on a data.frame
# factorise(x=train_app)
train_app <- datastream_dataframe(data=train_app)
train_app$get_points(10)


## Train the HoeffdingTree on the iris dataset
# ctrl <- MOAoptions(model = "NaiveBayes")
# mymodel <- NaiveBayes(control=ctrl)
mymodel <- OzaBoost(baseLearner = "trees.HoeffdingTree", ensembleSize = 70)

gc()
mytrainedmodel <- trainMOA(model = mymodel, chunksize = 2583283, 
                           click ~ ., data = train_app, trace=T,reset=T)
train_app$reset()
mytrainedmodel$model
gc()
## Predict using the HoeffdingTree on the iris dataset
# save(mytrainedmodel, file='naivebayes_model_app.RData')
save(mytrainedmodel, file='ozaboost_model_app.RData')

test_app <- data.frame(fread('data/test_df_app_smooth.csv'))
test_app <- test_app[,-1]

for (i in seq(dim(test_app)[2])){   
    test_app[which(test_app[[i]]==''),i] <- NaN   
}
for (i in seq(dim(test_app)[2])){   
    test_app[[i]] <- as.factor(test_app[[i]])   
}

scores <- predict(mytrainedmodel, newdata=test_app, type="votes")

pred <- scores[,2]/(scores[,1]+scores[,2])
range(pred)
# save(scores, file='naivebayes_pred_app.RData')
# write.csv(pred,file='naive_bayes_app_pred.csv')

save(scores, file='ozaboost_pred_app.RData')
write.csv(pred,file='ozaboost_app_pred.csv')
LogLoss(as.numeric(scores[,2])/(as.numeric(scores[,1])+as.numeric(scores[,2])), as.numeric(test_dt[1:100,1]))

## logloss func
LogLoss <- function(predicted,actual, eps=0.00001) {
    predicted <- pmin(pmax(predicted, eps), 1-eps)
    -1/length(actual)*(sum(actual*log(predicted)+(1-actual)*log(1-predicted)))
}