#-------------------------------------------################--------------------------------------#
#-------------------------------------------#Group Activity#--------------------------------------#
#-------------------------------------------################--------------------------------------#

#loading the required library
library(tidyr)
library(dplyr)
library(stringr)

# loading data
#using check.names to ensure the names with special character like & are loaded properly
mapping <- read.csv("mapping.csv",stringsAsFactors = FALSE,check.names=FALSE)
rounds2 <- read.csv("rounds2.csv",stringsAsFactors = FALSE)
companies <- read.delim("companies.txt",stringsAsFactors = FALSE)


#1.1
#1
#How many unique companies are present in rounds2?
# round2.company_permalink is the refference key from companies.permalink
# Hence counting distinct of the field in the  round2 dataset  
length(unique(tolower(rounds2$company_permalink))) # 66368

#2
#How many unique companies are present in companies?
# Company permalink is the field uniquely identifying the companies dataset
# hence taking a count of that
length(unique(companies$permalink)) # 66368

#3
#In the companies data frame, which column can be used as the unique key for each company? Write the name of the column.
companies$permalink

#4
#Are there any companies in the rounds2 file which are not present in companies? Answer yes or no: Y/N
#values are in mixed cases hence comverting them to lower for comparison
rounds2$company_permalink<-tolower(rounds2$company_permalink)
companies$permalink<-tolower(companies$permalink)

#compring the tho permalink fields. The empty resultset indicates that both have same set of values
setdiff(companies$permalink,rounds2$company_permalink)

#5
#Merge the two data frames so that all variables (columns) in the companies frame are added to the rounds2 data frame. Name the merged frame master_frame. How many observations are present in master_frame?
master_frame<-merge(x=rounds2,y=companies,by.y="permalink",by.x="company_permalink",all=T)


#-----------------------------------####################-------------------------------------------#
# We are choosing not to delete any data
# Rather we are ignoring them whereever necessary
# We are following this strategy because the data set is small and filtering is not expensive
# If we had been dealing with a large data set, then we would have seperated the data into different datasets/frames for analysis


#Table 2.1

#1
#Calculate the average investment amount for each of the four funding types (venture, angel, seed, and private equity)
funding_round_types_to_analyze <- c("venture","angel","seed","private_equity")
master_data_subsetted_for_required_round_types <- master_frame[which(master_frame$funding_round_type %in% funding_round_types_to_analyze),]
grouped_by_required_round_types <- group_by(master_data_subsetted_for_required_round_types,funding_round_type)
funding_amt_avg_by_round_type <- summarise(grouped_by_required_round_types,avg_raised_funding=mean(raised_amount_usd,na.rm=T))
funding_amt_avg_by_round_type

#2
#Based on the average investment amount calculated above, which investment type do you think is the most suitable for Spark Funds
filter(funding_amt_avg_by_round_type,between(funding_amt_avg_by_round_type$avg_raised_funding,5000000,15000000))

#------------------------------------------###################------------------------------------#
#3.1
# 7 % of out data is misisng contry code
# since percentage is less than 10 hence choosing to ignore from the calcualtion
length(master_frame[which(master_frame$country_code==""),2])*100/length(master_frame[,2])
#1,2
#Spark Funds wants to see the top nine countries which have received the highest total funding 
# Ignoring missing raised_amount_usd,countires
# Filtering for invertemnt type venture
grp_country<-group_by(master_frame[which(master_frame$funding_round_type =="venture" & master_frame$country_code!="") ,],country_code)
grp_country_sum<-summarise(grp_country,sum_raised_funding=sum(raised_amount_usd,na.rm=T))
top9<-grp_country_sum[order(grp_country_sum$sum_raised_funding,decreasing=T),][1:9,]
top9 

#------------------------------------------###################------------------------------------#
4.1
#1
# Extract the primary sector of each category list from the category_list column

# 3% of data has blank value for category_list
#since the percenatge is small it doesn't impact our calcuaiton hence shoosing to ignore them
#there looked up walue will be blank as well which doesn't imapct any of our further calcualtions
length(master_frame[which(master_frame$category_list==""),2])*100/length(master_frame[,2])

# Using the split function to break the category_list at "|"
# Picking the first item from the list
master_frame$Primary_sector <- str_split_fixed(string = master_frame$category_list,fixed('|'),n = Inf)[,1]

#chaning the wide mapping data frame to long for easier loockup
mapping_long <- gather(mapping, key=main_sector, value=belongs_to, "Automotive & Sports":"Social, Finance, Analytics, Advertising" )
mapping_long <- mapping_long[-which(mapping_long$belongs_to == 0), ]
mapping_long <-mapping_long[,-3]

#correcting the spelling mistakes like 'Task Ma0gement,Social Media Ma0gement,Waste Ma0gement'
#by replacing O with na
mapping_long$category_list<- gsub("([A-z])?(0)", "\\1na", mapping_long$category_list)

#make the lookup keys case insensitive by changing them to lowercase
master_frame$Primary_sector <- tolower(master_frame$Primary_sector)
mapping_long$category_list <- tolower(mapping_long$category_list)
master_frame <- merge(x=master_frame,y=mapping_long,by.y="category_list",by.x="Primary_sector",all.x=T,all.y=FALSE)

#removing "Blanks" sector data as we need to analyze only rest of the 8 main sectors
master_frame <- filter(master_frame,master_frame$main_sector != "Blanks")

#------------------------------------------###################------------------------------------#
#5.1
#1
# Create three separate data frames D1, D2 and D3 for each of the three countries containing the observations of funding type FT falling within the 5-15 million USD range. The three data frames should contain:
# All the columns of the master_frame along with the primary sector and the main sector
D1 <- filter(master_frame,between(master_frame$raised_amount_usd,5000000,15000000) & master_frame$country_code=="USA"
             & master_frame$funding_round_type =="venture")

total_investment_usa <- sum(D1$raised_amount_usd,na.rm = T)

sector_wise_investment_count_USA <- D1 %>% group_by(main_sector) %>%
  summarise(investment_count_for_sector = n(),total_amount_invested_in_sector = sum(raised_amount_usd,na.rm = T))

D1 <- merge(D1,sector_wise_investment_count_USA,by=c("main_sector"),all.x=T)

D2 <- filter(master_frame,between(master_frame$raised_amount_usd,5000000,15000000) & master_frame$country_code=="GBR"
             & master_frame$funding_round_type =="venture")

total_investment_gbr <- sum(D2$raised_amount_usd,na.rm = T)

sector_wise_investment_count_GBR <- D2 %>% group_by(main_sector) %>%
  summarise(investment_count_for_sector = n(),total_amount_invested_in_sector = sum(raised_amount_usd,na.rm = T))

D2 <- merge(D2,sector_wise_investment_count_GBR,by=c("main_sector"),all.x=T)

D3 <- filter(master_frame,between(master_frame$raised_amount_usd,5000000,15000000) & master_frame$country_code=="IND"
             & master_frame$funding_round_type =="venture")

total_investment_ind <- sum(D3$raised_amount_usd,na.rm = T)

sector_wise_investment_count_IND <- D3 %>% group_by(main_sector) %>%
  summarise(investment_count_for_sector = n(),total_amount_invested_in_sector = sum(raised_amount_usd,na.rm = T))

D3 <- merge(D3,sector_wise_investment_count_IND,by=c("main_sector"),all.x=T)


#Analysis for D1 aka USA
#total number of investment
sum(unique(D1$investment_count_for_sector))
#sum total of all investment received
sum(D1$raised_amount_usd,na.rm = T)


#group by sector
D1_grp_by_main_sector<-group_by(D1,main_sector)
# count per sector
D1_sector_wise_investment_count<-summarise(D1_grp_by_main_sector,no_of_investment=n())
#print("Top 3 sector count wise")
D1_sector_wise_investment_count[order(D1_sector_wise_investment_count$no_of_investment,decreasing=T),][1:3,1:2]

# Calculation for top sector in D1 aka usa i.e others
# Grouping by company_permalink and then summation of raised_amount_usd 
D1_top_sector_grp_by_company <- group_by(D1[which(D1$main_sector == "Others"),],company_permalink)
D1_top_sector_company_wise_funding_sum <- summarise(D1_top_sector_grp_by_company,Sum_of_investment=sum(raised_amount_usd,na.rm=T))
# Taking the firm with max investment 
D1_top_sector_Top_funded <- D1_top_sector_company_wise_funding_sum[which(max(D1_top_sector_company_wise_funding_sum$Sum_of_investment)
                                                                         ==D1_top_sector_company_wise_funding_sum$Sum_of_investment),]
# Looking up the name
unique(inner_join(D1, D1_top_sector_Top_funded)[,9])


# calculation to 2nd best sector in D1 aka usa i.e Social, Finance, Analytics, Advertising
# Grouping by company_permalink and then summation of raised_amount_usd 
D1_2nd_sector_grp_by_company <- group_by(D1[which(D1$main_sector == "Social, Finance, Analytics, Advertising"),],company_permalink)
D1_2nd_sector_company_wise_funding_sum <- summarise(D1_2nd_sector_grp_by_company,Sum_of_investment=sum(raised_amount_usd,na.rm=T))
# Taking the firm with max investment 
D1_2nd_sector_Top_funded <- D1_2nd_sector_company_wise_funding_sum[which(max(D1_2nd_sector_company_wise_funding_sum$Sum_of_investment)
                                                                         ==D1_2nd_sector_company_wise_funding_sum$Sum_of_investment),]
# Looking up the name
unique(inner_join(D1, D1_2nd_sector_Top_funded)[,9])


#Analysis for D2 aka GBR
#total number of investment
sum(unique(D2$investment_count_for_sector))
#sum total of all investment received
sum(D2$raised_amount_usd,na.rm = T)


#group by sector
D2_grp_by_main_sector<-group_by(D2,main_sector)
# count per sector
D2_sector_wise_investment_count<-summarise(D2_grp_by_main_sector,no_of_investment=n())
#print("Top 3 sector count wise")
D2_sector_wise_investment_count[order(D2_sector_wise_investment_count$no_of_investment,decreasing=T),][1:3,1:2]

# Calculation for top sector in D2 aka GBR i.e others
# Grouping by company_permalink and then summation of raised_amount_usd 
D2_top_sector_grp_by_company <- group_by(D2[which(D2$main_sector == "Others"),],company_permalink)
D2_top_sector_company_wise_funding_sum <- summarise(D2_top_sector_grp_by_company,Sum_of_investment=sum(raised_amount_usd,na.rm=T))
# Taking the firm with max investment 
D2_top_sector_Top_funded <- D2_top_sector_company_wise_funding_sum[which(max(D2_top_sector_company_wise_funding_sum$Sum_of_investment)
                                                                         ==D2_top_sector_company_wise_funding_sum$Sum_of_investment),]
# Looking up the name
unique(inner_join(D2, D2_top_sector_Top_funded)[,9])


# calculation to 2nd best sector in D2 aka GBR i.e Social, Finance, Analytics, Advertising
# Grouping by company_permalink and then summation of raised_amount_usd 
D2_2nd_sector_grp_by_company <- group_by(D2[which(D2$main_sector == "Social, Finance, Analytics, Advertising"),],company_permalink)
D2_2nd_sector_company_wise_funding_sum <- summarise(D2_2nd_sector_grp_by_company,Sum_of_investment=sum(raised_amount_usd,na.rm=T))
# Taking the firm with max investment 
D2_2nd_sector_Top_funded <- D2_2nd_sector_company_wise_funding_sum[which(max(D2_2nd_sector_company_wise_funding_sum$Sum_of_investment)
                                                                         ==D2_2nd_sector_company_wise_funding_sum$Sum_of_investment),]
# Looking up the name
unique(inner_join(D2, D2_2nd_sector_Top_funded)[,9])

#Analysis for D3 aka IND
#total number of investment
sum(unique(D3$investment_count_for_sector))
#sum total of all investment received
sum(D3$raised_amount_usd,na.rm = T)


#group by sector
D3_grp_by_main_sector<-group_by(D3,main_sector)
# count per sector
D3_sector_wise_investment_count<-summarise(D3_grp_by_main_sector,no_of_investment=n())
#print("Top 3 sector count wise")
D3_sector_wise_investment_count[order(D3_sector_wise_investment_count$no_of_investment,decreasing=T),][1:3,1:2]

# Calculation for top sector in D3 aka IND i.e others
# Grouping by company_permalink and then summation of raised_amount_usd 
D3_top_sector_grp_by_company <- group_by(D3[which(D3$main_sector == "Others"),],company_permalink)
D3_top_sector_company_wise_funding_sum <- summarise(D3_top_sector_grp_by_company,Sum_of_investment=sum(raised_amount_usd,na.rm=T))
# Taking the firm with max investment 
D3_top_sector_Top_funded <- D3_top_sector_company_wise_funding_sum[which(max(D3_top_sector_company_wise_funding_sum$Sum_of_investment)
                                                                         ==D3_top_sector_company_wise_funding_sum$Sum_of_investment),]
# Looking up the name
unique(inner_join(D3, D3_top_sector_Top_funded)[,9])


# calculation to 2nd best sector in D3 aka IND i.e Social, Finance, Analytics, Advertising
# Grouping by company_permalink and then summation of raised_amount_usd 
D3_2nd_sector_grp_by_company <- group_by(D3[which(D3$main_sector == "Social, Finance, Analytics, Advertising"),],company_permalink)
D3_2nd_sector_company_wise_funding_sum <- summarise(D3_2nd_sector_grp_by_company,Sum_of_investment=sum(raised_amount_usd,na.rm=T))
# Taking the firm with max investment 
D3_2nd_sector_Top_funded <- D3_2nd_sector_company_wise_funding_sum[which(max(D3_2nd_sector_company_wise_funding_sum$Sum_of_investment)
                                                                         ==D3_2nd_sector_company_wise_funding_sum$Sum_of_investment),]
# Looking up the name
unique(inner_join(D3, D3_2nd_sector_Top_funded)[,9])


