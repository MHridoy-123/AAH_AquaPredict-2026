# AAH-AquaPredict RStudio pipeline
required <- c("tidyverse","readr","janitor","caret","recipes","ranger","e1071","nnet","kknn","kernlab","gbm","glmnet","doParallel","vip","pROC")
missing <- required[!sapply(required, requireNamespace, quietly=TRUE)]
if(length(missing)>0) install.packages(missing, dependencies=TRUE)
lapply(required, library, character.only=TRUE)
`%||%` <- function(x,y) if(is.null(x)) y else x
set.seed(2026)
dat <- readr::read_csv("data/aah_aquapredict_cleaned_water_quality.csv", show_col_types=FALSE) |> janitor::clean_names()
dat$water_quality <- as.factor(dat$water_quality)
ctrl <- trainControl(method="repeatedcv", number=5, repeats=3, classProbs=TRUE, savePredictions="final", summaryFunction=multiClassSummary, allowParallel=TRUE)
cl <- parallel::makePSOCKcluster(max(1, parallel::detectCores()-1)); doParallel::registerDoParallel(cl)
rec <- recipe(water_quality ~ ., data=dat) |> step_impute_median(all_numeric_predictors()) |> step_zv(all_predictors()) |> step_normalize(all_numeric_predictors())
models <- list(multinom=list(method="multinom", tuneLength=5, trace=FALSE), glmnet=list(method="glmnet", tuneLength=10), lda=list(method="lda"), qda=list(method="qda"), knn=list(method="kknn", tuneLength=8), svm_radial=list(method="svmRadial", tuneLength=8), random_forest=list(method="ranger", tuneLength=8, importance="permutation"), gbm=list(method="gbm", tuneLength=6, verbose=FALSE), mlp=list(method="nnet", tuneLength=6, trace=FALSE, MaxNWts=10000, maxit=500))
fits <- list()
for(nm in names(models)){ spec <- models[[nm]]; message("Training: ", nm); fits[[nm]] <- tryCatch(train(rec, data=dat, method=spec$method, trControl=ctrl, tuneLength=spec$tuneLength %||% 1, metric="logLoss", trace=spec$trace %||% FALSE, verbose=spec$verbose %||% FALSE, MaxNWts=spec$MaxNWts %||% NULL, maxit=spec$maxit %||% NULL, importance=spec$importance %||% NULL), error=function(e) e) }
valid <- fits[!sapply(fits, inherits, what="error")]
perf <- purrr::map_dfr(names(valid), function(nm){ p <- valid[[nm]]$pred; bt <- valid[[nm]]$bestTune; if(!is.null(bt)) for(v in names(bt)) p <- p[p[[v]]==bt[[v]],]; cm <- confusionMatrix(p$pred,p$obs); tibble(Model=nm, Accuracy=cm$overall[["Accuracy"]], Kappa=cm$overall[["Kappa"]], Macro_F1=mean(cm$byClass[,"F1"],na.rm=TRUE), Balanced_Accuracy=mean(cm$byClass[,"Balanced Accuracy"],na.rm=TRUE)) }) |> arrange(desc(Macro_F1))
write.csv(perf,"outputs/tables/r_repeated_cv_model_performance.csv",row.names=FALSE)
ggsave("outputs/figures/r_repeated_cv_performance.png", ggplot(perf,aes(reorder(Model,Macro_F1),Macro_F1))+geom_col(fill="#7C3AED")+coord_flip()+theme_minimal()+labs(x="Model",y="Macro-F1"), width=8,height=6,dpi=300)
parallel::stopCluster(cl)
