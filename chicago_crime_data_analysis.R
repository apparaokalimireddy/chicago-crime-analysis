rm(list=ls())
library(ggplot2)
library(scales)
library(reshape2)
library(maps)
library(ggmap)
sql("use bighawk")

# Get all crime data from partition by year table
allcrimes<-sql("select c.*, month(crime_date) as month, date_format(crime_date, 'u') as day, a.community as community from chicago_crimes_part_year c left join chicago_communities a on (c.community_area = a.community_area)")

##
## Function: trendOverYears
## Chicago crime trend over the years
##
trendOverYears <- function() {
  # Get the crime counts by year as R dataframe
  crimesByYear<-as.data.frame(count(groupBy(allcrimes, allcrimes$part_year)))
  crimesByYear<-crimesByYear[order(crimesByYear[1]),]

  # Draw a line chart of the total crimes by year - 2017
  png("trend_all_crimes.png", width=720, height=720, units="px")
  ggplot(data=crimesByYear, aes(x=part_year, y=count, group=1)) +
      geom_line(colour="red", size=1.5) +
      geom_point(colour="red", size=4, shape=21, fill="white") +
      xlab("Year") + ylab("Total crimes") +
      ggtitle("Trend of crimes over the years") +
      theme(plot.title = element_text(hjust = 0.5, face="bold")) +
      scale_y_continuous(labels = comma)
  dev.off()
}

##
## Function: top5ByYear
## Histogram of top 5 crimes for a given year
##
top5ByYear <- function(yr) {
  crimesByType<-as.data.frame(count(groupBy(where(allcrimes,allcrimes$part_year==yr),"primary_type")))
  crimesByType<-crimesByType[order(crimesByType[2], decreasing=TRUE),]
  # Draw a bar chart of the crime types
  png(paste("top5_crimes_", yr, ".png", sep=""), width=720, height=720, units="px")
  print({
      barplot(crimesByType[5:1,2], main=paste("Top 5 Crimes in ", yr, sep=""), horiz=TRUE, names.arg=crimesByType[5:1,1], cex.names=0.8, col=topo.colors(5))
  })
  dev.off()
}


##
## Function: trendByCrime
## For a given crime type - Shows trend over the years
##
trendByCrime <- function(crimeType) {
  # Get the crime counts by year as R dataframe
  crimeTrend<-as.data.frame(count(groupBy(where(allcrimes,allcrimes$primary_type==crimeType), "part_year")))
  crimeTrend<-crimeTrend[order(crimeTrend[1]),]
  # Draw a line chart of a crime
  ggplot(data=crimeTrend, aes(x=part_year, y=count, group=1)) +
    geom_line(colour="red", size=1.5) +
    geom_point(colour="red", size=4, shape=21, fill="white") +
    xlab("Year") + ylab(crimeType) +
    ggtitle("Crime Trend Over the Years") +
    theme(plot.title = element_text(hjust = 0.5, face="bold")) +
    scale_y_continuous(labels = comma)
  ggsave(file=paste("trend_", crimeType, ".png", sep=""))
}

##
## Function: trendOfCrimes
## For a given vector of crime types - Shows trend(s) over the years
##
trendOfCrimes <- function(crimeTypes) {
  # Get the crime counts by crime types as R dataframe
  crimesByType<-as.data.frame(count(groupBy(allcrimes,"part_year", "primary_type")))
  crimesByType<-crimesByType[crimesByType$primary_type %in% crimeTypes, ]
  colnames(crimesByType) <- c("Year","Crime","Count")

  # Draw a line chart of a crime
  p<-ggplot()
  p<-p+xlab("Year") + ylab("Crimes")
  p<-p+ggtitle("Trend of Crimes Over the Years")
  p<-p+theme(plot.title = element_text(hjust = 0.5, face="bold"))
  p<-p+scale_y_continuous(labels = comma)
  p<-p+expand_limits(y=0, x=2001)
  for (c in crimeTypes) {
    df<-crimesByType[which(crimesByType$Crime==c),]
    df<-df[order(df[1]),]
    p<-p+geom_line(data=df, aes(group=Crime, colour=Crime, x=Year,y=Count))
  }
  ggsave(file=paste("trend_of_crimes", ".png", sep=""), plot=p)
}

##
## Function: crimeTrendByMonth(years)
##
crimeTrendByMonth<-function(years) {
  # Draw a line chart of a crime
  p<-ggplot()
  p<-p+xlab("Month") + ylab("Crimes")
  p<-p+ggtitle("Trend of Crimes By Month")
  p<-p+theme(plot.title = element_text(hjust = 0.5, face="bold"))
  p<-p+scale_y_continuous(labels = comma)
  p<-p+scale_x_continuous(breaks=seq(1,12,by=1))
  for (y in years) {
    df<-as.data.frame(count(groupBy(where(allcrimes,allcrimes$part_year==y),"part_year", "month")))
    colnames(df) <- c("Year","Month","Count")
    p<-p+geom_line(data=df, aes(color=factor(Year), group=factor(Year), x=Month,y=Count), size=1.5)
    p<-p+labs(color = "Year")
  }
  ggsave(file=paste("crime_trend_by_month", ".png", sep=""), plot=p)
}

##
## Function: crimeTrendByDay(years)
##
crimeTrendByDay<-function(years) {
  # Draw a line chart of a crime
  p<-ggplot()
  p<-p+xlab("Day") + ylab("Crimes")
  p<-p+ggtitle("Trend of Crimes By Day of a Week")
  p<-p+theme(plot.title = element_text(hjust = 0.5, face="bold"))
  p<-p+scale_y_continuous(labels = comma)
  #p<-p+scale_x_continuous(breaks=seq(1,7,by=1))
  for (y in years) {
    df<-as.data.frame(count(groupBy(where(allcrimes,allcrimes$part_year==y),"part_year", "day")))
    colnames(df) <- c("Year","Day","Count")
    p<-p+geom_line(data=df, aes(color=factor(Year), group=factor(Year), x=Day,y=Count), size=1.5)
    p<-p+labs(color = "Year")
  }
  ggsave(file=paste("crime_trend_by_day", ".png", sep=""), plot=p)
}

##
## Function: generateHeatmap
##
generateHeatmap <- function(year="") {
  if (year == "") {
    df<-as.data.frame(count(groupBy(allcrimes, "community", "primary_type")))
  } else {
    df<-as.data.frame(count(groupBy(where(allcrimes, paste("year == ", year, sep="")), "community", "primary_type")))
  }
  df<-dcast(df, community~primary_type,value.var="count") # Pivot the data
  df$community[which(is.na(df$community))]<-"NA"
  row.names(df)<-df$community # change the row names to community
  df<-df[,2:ncol(df)] # remove first column with community
  pm<-data.matrix(df)
  #pm[is.na(pm)]<-0
  png(file=paste("heatmap",year,".png", sep=""), width=3.5, height=3.5, units="in", res=1200, pointsize=4)
  hm<-heatmap(pm, Rowv=NA, Colv=NA, col=cm.colors(256), scale="column", margins=c(5,10), main=paste("Heatmap of Crimes in Communities", year))
  dev.off()
}

##
## Function: Top Unsafe Communities
##
topUnsafeCommunities<-function(n=5, year="") {
  if (year == "") {
    df<-as.data.frame(count(groupBy(allcrimes, "community")))
  } else {
    df<-as.data.frame(count(groupBy(where(allcrimes, paste("year == ", year, sep="")), "community")))
  }
  df<-df[which(!is.na(df$community)),]
  df<-df[order(df[2], decreasing=TRUE),]
  # Draw a bar chart of the crime types
  png(paste("communities_unsafe", year, ".png", sep=""), width=720, height=720, units="px")
  print({
      barplot(df[n:1,2], main=paste("Top Unsafe Communities", year, sep=" "), horiz=TRUE, names.arg=df[n:1,1], cex.names=0.8, col=topo.colors(5))
  })
  dev.off()
}

##
## Function: Top Safe Communities
##
topSafeCommunities<-function(n=5, year="") {
  if (year == "") {
    df<-as.data.frame(count(groupBy(allcrimes, "community")))
  } else {
    df<-as.data.frame(count(groupBy(where(allcrimes, paste("year == ", year, sep="")), "community")))
  }
  df<-df[which(!is.na(df$community)),]
  df<-df[order(df[2], decreasing=FALSE),]
  # Draw a bar chart of the crime types
  png(paste("communities_safe", year, ".png", sep=""), width=720, height=720, units="px")
  print({
      barplot(df[n:1,2], main=paste("Top Safe Communities", year, sep=" "), horiz=TRUE, names.arg=df[n:1,1], cex.names=0.8, col=topo.colors(5))
  })
  dev.off()
}

##
## Function: crimeMap
##
crimeMap<-function(year=2017) {
  df<-sql(paste("select crime_date, primary_type, latitude, longitude from chicago_crimes_part_year where year='", year, "'", sep=""))
  write.csv(as.data.frame(df), paste("/home/akalimir/chicago_crimes_ll_", year, ".csv", sep=""))
  df<-read.csv(paste("chicago_crimes_ll_", year, ".csv", sep=""))
  latLonCounts <- as.data.frame(table(round(df$longitude,2), round(df$latitude,2)))
  latLonCounts$long <- as.numeric(as.character(latLonCounts$Var1))
  latLonCounts$lat <- as.numeric(as.character(latLonCounts$Var2))
  latLonCounts2 <- subset(latLonCounts, Freq > 0)
  chicago1 <- get_map(location = "chicago", zoom = 11)
  p<-ggmap(chicago1) + geom_tile(data = latLonCounts2, aes(x = long, y = lat, alpha = Freq), fill = "red")
  ggsave(file=paste("crimemap1-", year, ".png", sep=""), plot=p)
  chicago2 <- get_map(location = "chicago", zoom = 11)
  p<-ggmap(chicago2) + geom_point(data = latLonCounts2, aes(x = long, y = lat, color = Freq, size=Freq)) + scale_color_gradient(low = "yellow", high = "red")
  ggsave(file=paste("crimemap2-", year, ".png", sep=""), plot=p)
}

##
## Function: crimeRateMap
## Function to create map of crime rates in 77 communities in Chicago
crimeRateMap<-function(year=2017) {
  df<-as.data.frame(sql(paste("select d.community, d.total_population, d.latitude, d.longitude, count(*) as crime_count from chicago_crimes_part_year c join chicago_communities d on (d.community_area = c.community_area) where c.year = '", year, "' group by d.community, d.total_population, d.latitude, d.longitude", sep="")))
  df$longitude<-as.numeric(as.character(df$longitude))
  df$latitude<-as.numeric(as.character(df$latitude))
  df$crime_count<-as.numeric(as.character(df$crime_count))
  df$total_population<-as.numeric(gsub(as.character(df$total_population), pattern=",", replacement = "", fixed = TRUE))
  df$crime_rate<-(df$crime_count/df$total_population)*1000
  chicago <- get_map(location = "chicago", zoom = 12)
  p<-ggmap(chicago) + geom_point(data = df, aes(x = longitude, y = latitude, color=crime_rate, size=crime_rate)) + labs(size="Crime Rate", color="Crime Rate") +scale_color_gradient(low = "yellow", high = "red")
  ggsave(file=paste("map-crime-rate-",year,".png",sep=""), plot=p)
}

##
## Function: crimeRateMapByType
## Function to create map of crime rates in 77 communities in Chicago by crime type, THEFT etc.
crimeRateMapByType<-function(crimeType='THEFT', year=2017) {
  df<-as.data.frame(sql(paste("select d.community, d.total_population, d.latitude, d.longitude, count(*) as crime_count from chicago_crimes_part_year c join chicago_communities d on (d.community_area = c.community_area) where c.year = '", year, "' and primary_type = '", crimeType, "' group by d.community, d.total_population, d.latitude, d.longitude", sep="")))
  df$longitude<-as.numeric(as.character(df$longitude))
  df$latitude<-as.numeric(as.character(df$latitude))
  df$crime_count<-as.numeric(as.character(df$crime_count))
  df$total_population<-as.numeric(gsub(as.character(df$total_population), pattern=",", replacement = "", fixed = TRUE))
  df$crime_rate<-(df$crime_count/df$total_population)*1000
  chicago <- get_map(location = "chicago", zoom = 12)
  p<-ggmap(chicago) + geom_point(data = df, aes(x = longitude, y = latitude, color=crime_rate, size=crime_rate)) + labs(size="Crime Rate", color="Crime Rate") +scale_color_gradient(low = "yellow", high = "red")
  ggsave(file=paste("map-crime-rate-",crimeType,"-",year,".png",sep=""), plot=p)
}

##
## Function: crimeAndPerCapitaIncome
## Relation between a crime type and Per Capita income
crimeAndPerCapitaIncome<-function(crimeType="THEFT", year="2017", title="Relation between Thefts and Per Capita Income") {
  df<-as.data.frame(sql(paste("select d.community, d.total_population, d.per_capita_income, count(*) as crime_count from chicago_crimes_part_year c join chicago_communities d on (c.community_area=d.community_area) where c.year='", year, "' and c.primary_type='", crimeType, "' group by d.community, d.total_population, d.per_capita_income",sep="")))
  df$total_population<-as.numeric(gsub(as.character(df$total_population), pattern=",", replacement = "", fixed = TRUE))
  df$crime_count<-as.numeric(as.character(df$crime_count))
  df$crime_rate<-(df$crime_count/df$total_population)*1000

  p<-ggplot(df, aes(x=per_capita_income, y=crime_rate)) +
  xlab("Per Capita Income") + ylab("Crime Rate per 1000 Residents") +
  geom_point(shape=1) +
  geom_text(data=subset(df[order(df$crime_rate,decreasing=T)[1:5],]), aes(label=community, colour="red"),show.legend = FALSE,size=2) +
  geom_smooth(method=lm, se=FALSE) + ggtitle(title)

  ggsave(file=paste("crime-percapita-",crimeType,"-",year,".png",sep=""), plot=p)
}


## Analysis/Chart generation start here
##
#Generate Trend over years
trendOverYears()

#Generate top 5 crimes in 2016 and 2017
top5ByYear(2016)
top5ByYear(2017)

#Generate a line chart of thefts and homicides over the years
trendByCrime("THEFT")
trendByCrime("HOMICIDE")

#Generate trend of THEFT and BATTERY on one chart
trendOfCrimes(c("THEFT", "BATTERY", "HOMICIDE", "ROBBERY"))

# Trends by Month of the year and day of the weel
crimeTrendByMonth(c(2014,2015,2016))
crimeTrendByDay(c(2014,2015,2016))

#Generate heatmap for all years, 2016 and 2017
generateHeatmap()
generateHeatmap(2016)
generateHeatmap(2017)

# Community charts
topUnsafeCommunities()
topUnsafeCommunities(year=2016)
topUnsafeCommunities(year=2017)
topSafeCommunities()
topSafeCommunities(year=2016)
topSafeCommunities(year=2017)

# Crime Map for 2016-2017
crimeMap(2016)
crimeMap(2017)

# Create Crime rate maps for 2007-2017
crimeRateMap(2007)
crimeRateMap(2008)
crimeRateMap(2009)
crimeRateMap(2010)
crimeRateMap(2011)
crimeRateMap(2012)
crimeRateMap(2013)
crimeRateMap(2014)
crimeRateMap(2015)
crimeRateMap(2016)
crimeRateMap(2017)

# Create Crime rate map for THEFTs
crimeRateMapByType(crimeType='THEFT', year=2016)
crimeRateMapByType(crimeType='THEFT', year=2017)
crimeRateMapByType(crimeType='ROBBERY', year=2016)
crimeRateMapByType(crimeType='ROBBERY', year=2017)
crimeRateMapByType(crimeType='BATTERY', year=2016)
crimeRateMapByType(crimeType='BATTERY', year=2017)
crimeRateMapByType(crimeType='NARCOTICS', year=2016)
crimeRateMapByType(crimeType='NARCOTICS', year=2017)
crimeRateMapByType(crimeType='HOMICIDE', year=2016)
crimeRateMapByType(crimeType='HOMICIDE', year=2017)

# Create chart to show relation between thefts and per capita income
crimeAndPerCapitaIncome(crimeType="THEFT", year="2017", title="Relation between Thefts and Per Capita Income")
crimeAndPerCapitaIncome(crimeType="ROBBERY", year="2017", title="Relation between Robberies and Per Capita Income")
crimeAndPerCapitaIncome(crimeType="BATTERY", year="2017", title="Relation between Battery and Per Capita Income")
crimeAndPerCapitaIncome(crimeType="NARCOTICS", year="2017", title="Relation between Narcotics and Per Capita Income")
crimeAndPerCapitaIncome(crimeType="HOMICIDE", year="2017", title="Relation between Homicides and Per Capita Income")
