rm(list=ls())
library(ggplot2)
library(scales)
library(reshape2)
library(maps)
library(ggmap)
sql("use bighawk")

# Get all crime data from partition by year and communities tables
allcrimes<-sql("select c.*, month(crime_date) as month, date_format(crime_date, 'u') as day, hour(crime_date) as hour, a.community as community from chicago_crimes_part_year c left join chicago_communities a on (c.community_area = a.community_area)")

##
## Function: predictCrimesByDay
## Given Community, Crime Type, Month, Day -> Predit number crimes that might occur
## We will take data from 2015-16 as training data, 2017 data as testing data.
## We will be using Linear regression model for this analysis.
predictCrimesByDay<-function() {
  # Build prediction model using GLM algorithm and training data.
  years<-c(2015, 2016)
  training_data<-as.data.frame(count(groupBy(where(allcrimes,allcrimes$part_year %in% years),"community", "primary_type","month", "day")))
  colnames(training_data) <- c("community", "crime_type", "month", "day","crime_count")
  training_data<-na.omit(training_data)
  # Create the model
  training_data_df<-as.DataFrame(training_data)
  model<-spark.glm(training_data_df,crime_count~.,family="gaussian")

  # Predict crime counts 2017 data
  testing_data<-as.data.frame(count(groupBy(where(allcrimes,allcrimes$part_year==2017),"community", "primary_type","month", "day")))
  colnames(testing_data) <- c("community", "crime_type", "month", "day","crime_count")
  testing_data<-na.omit(testing_data)
  output<-predict(model, as.DataFrame(testing_data))

  # Calculate MSE
  mse_df<-as.data.frame(select(output, avg((output$crime_count-output$prediction)^2)))
  mse<-mse_df[1,1] # 49.4% without rounding (prediction are fractional, which is not realistic)

  mse_df<-as.data.frame(select(output, avg((output$crime_count-round(output$prediction))^2)))
  mse2<-mse_df[1,1] # 49.5% with rounding (predictions are integer)

  # Print the summary of the model and MSE to a file
  sink("predict_crimes_model_output_day.txt")
  print(paste("MSE: ", mse, sep=""))
  print(paste("MSE(rounded prediction): ", mse2, sep=""))
  showDF(output, 25)
  print(summary(model))
  sink()
}

##
## Function: predictCrimesByHour
## Given Community, Crime Type, Month, Day, Hour -> Predit number crimes that might occur
## We will take data from 2015-16 as training data, 2017 data as testing data.
## We will be using Linear regression model for this analysis.
predictCrimesByHour<-function() {
  # Build prediction model using GLM algorithm and training data.
  years<-c(2015, 2016)
  training_data<-as.data.frame(count(groupBy(where(allcrimes,allcrimes$part_year %in% years),"community", "primary_type","month", "day", "hour")))
  colnames(training_data) <- c("community", "crime_type", "month", "day", "hour","crime_count")
  training_data<-na.omit(training_data)
  # Create the model
  model<-spark.glm(as.DataFrame(training_data),crime_count~.,family="gaussian")

  # Predict crime counts 2017 data
  testing_data<-as.data.frame(count(groupBy(where(allcrimes,allcrimes$part_year==2017),"community", "primary_type","month", "day", "hour")))
  colnames(testing_data) <- c("community", "crime_type", "month", "day", "hour","crime_count")
  testing_data<-na.omit(testing_data)
  output<-predict(model, as.DataFrame(testing_data))

  # Calculate MSE
  mse_df<-as.data.frame(select(output, avg((output$crime_count-output$prediction)^2)))
  mse<-mse_df[1,1] # 64.7% without rounding (prediction are fractional, which is not realistic)

  mse_df<-as.data.frame(select(output, avg((output$crime_count-round(output$prediction))^2)))
  mse2<-mse_df[1,1] # 73.28% with rounding (predictions are integer)

  # Print the summary of the model and MSE to a file
  sink("predict_crimes_model_output_hour.txt")
  print(paste("MSE: ", mse, sep=""))
  print(paste("MSE(rounded prediction): ", mse2, sep=""))
  showDF(output, 25)
  print(summary(model))
  sink()
}

# Run predictCrimes function to generate model using 2015-16 data and predict
# crimes per day in 2017
# Output is stored to predict_crimes_model_output_day.txt file
# Model is stored to predict_crimes_model_day.rda file
predictCrimesByDay()

# Run predictCrimes function to generate model using 2015-16 data and predict
# crimes per hour in 2017
# Output is stored to predict_crimes_model_output.txt file
# Model is stored to predict_crimes_model.rda file
predictCrimesByHour()
