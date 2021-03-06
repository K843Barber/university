# Load libraries
library(tidyverse)
library(lubridate)
library(plotly)

# Load timesdata file
timesData <- read.csv("timesData.csv", T, ",", stringsAsFactors = F)


# check format of all variables
str(timesData)
View(timesData)

# convert them to the correct format
timesData$world_rank <- as.numeric(timesData$world_rank)
timesData$international <- as.numeric(timesData$international)  
timesData$income <- as.numeric(timesData$income)
timesData$total_score <- as.numeric(timesData$total_score)

# converting num_students is a little more involved
timesData$num_students <- as.factor(timesData$num_students)
timesData <- timesData %>%
  separate(num_students, c("thou", "hun"), sep = ",") %>%
  unite(student_num, thou, hun, sep = "")
timesData$student_num <- as.numeric(timesData$student_num)

# Now, we look at the student count by gender:
student_count_by_gender <- timesData %>%
    separate(female_male_ratio, c("female", "male"), sep = ":")

student_count_by_gender$female <- as.numeric(student_count_by_gender$female)
student_count_by_gender$male <- as.numeric(student_count_by_gender$male)

student_count_by_gender %>%
  mutate(total_female_students = (female / (female + male)) * student_num,
         total_male_students = (male / (female + male)) * student_num, 
         total_students = total_female_students + total_male_students) %>%
  group_by(year) %>%
  summarise(total_female = sum(total_female_students, na.rm = T),
            total_male = sum(total_male_students, na.rm = T),
            total_total = sum(total_students, na.rm = T)) %>%
  gather(total_female:total_total, key = "key", value = "Students") %>%
  ggplot(aes(key, Students, fill = key)) + 
  geom_bar(stat = "identity", position = position_dodge()) + facet_wrap(~year) +
  labs(x = "Gender/total", y = "Number of Students", title = "Student count by Gender") +
  theme(plot.title = element_text(hjust = 0.5))


# Now, we look at the number of international students, so we need to convert the number 
# of International students from a percentage to a fraction:
student_count_by_gender$international_students <- as.factor(
  student_count_by_gender$international_students)

internationals <- student_count_by_gender %>%
  separate(international_students, c("numerator", "percent"), sep = 2) %>%
  filter(numerator > 10)

internationals %>%
  mutate(total_internationals = (as.numeric(numerator) / 100) * student_num) %>%
  group_by(country, year) %>%
  summarise(total_internationals_by_country = sum(total_internationals, na.rm = T)) %>%
  filter(total_internationals_by_country != 0, total_internationals_by_country > 15000) %>%
  ggplot(aes(reorder(country, total_internationals_by_country), 
             total_internationals_by_country, fill = country)) +
  geom_bar(stat = "identity") + coord_flip() + facet_wrap(~year) +
  geom_text(aes(label = total_internationals_by_country), hjust = -0.2) +
  labs(x = "Country", y = "Number of Students", 
       title = "International Student by Country")


# We now look to see if there is a correlation between teaching and income

timesData %>%
  filter(income != 100) %>%
  ggplot(aes(teaching, income)) + geom_point() + facet_wrap(~year) +
  labs(title = "Relationship between teaching levels and income levels") +
  theme(plot.title = element_text(hjust = 0.5))

# The data appears to show a very small positive correlation. 
# Now, colouring it per country:

timesData %>%
  filter(income != 100) %>%
  ggplot(aes(teaching, income, colour = country)) + geom_point() +
  facet_wrap(~year) + guides(colour = F) +
  labs(x = "Teacher Rating", y = "University Income", 
       title = "Relationship between Teaching and Income") +
  theme(plot.title = element_text(hjust = 0.5))

# Still unclear, and far too many countries to focus on, so perhaps a look at big names

timesData %>%
  filter(income != 100, 
         country == "United States of America" | country == "United Kingdom") %>%
  ggplot(aes(teaching, income, colour = country)) + geom_point() + 
  facet_wrap(~country) + geom_smooth() +
  labs(x = "Teacher Rating", y = "Income",
     title = "Relationship between teaching and income") +
  theme(plot.title = element_text(hjust = 0.5))

# There appears to be a stronger relationship between teaching and income with
# the UK over the US, however, US appear to have more Universities, which we shall 
# now check. P.S - Noting that these values plotted may represent the same universities 
# but in different years, and that the UK has a lot of universities with high income
# and a huge range of incomes at that level

timesData %>%
  group_by(year, country) %>%
  summarise(count = n()) %>%
  filter(country == "United States of America" | country == "United Kingdom") %>%
  ggplot(aes(country, count, fill = country)) + geom_bar(stat = "identity") +
  facet_wrap(~year) + geom_text(aes(label = count), vjust = -0.2) + 
  labs(title = "Number of Universities in UK and US", y = "Number of Universities") +
  theme(plot.title = element_text(hjust = 0.5))

# As expected, the number of Universities is always double in US apart from 2016 where it 
# is still close to double

# Now focussing on UK highest performers, we can see which universities have the varying
# incomes

timesData %>%
  filter(income != 100, teaching > 75, country == "United Kingdom") %>%
  ggplot(aes(teaching, income, colour = university_name)) + 
  geom_point(size = 3) + facet_wrap(~year) + 
  labs(title = "Relationship between teaching and income of UK's top universities") +
  theme(plot.title = element_text(hjust = 0.5))

# It appears that ICL, UOC and UOO appear each year, whereas UCL appears every now and again.
# The first 5 years give off a slightly negative correlation, which shows that there appears 
# to be a peak in the amount of income a university requires in order to provide top quality 
# teaching. However, in the final year, it appears that we have now shifted to a positive
# correlation between teaching and income for the very top universities, suggesting that the
# income is being distributed in a more effective way

# Personal look at Universities in Sweden
timesData %>%
  filter(country == "Sweden") %>%
  filter(university_name == "Uppsala University" | university_name == "Stockholm University" |
           university_name == "University of Gothenburg") %>%
  ggplot(aes(teaching, income, colour = university_name)) + 
  geom_point(size = 3) + 
  facet_wrap(~year) + geom_text(aes(label = student_num), vjust = 1.5) +
  labs(x = "Teacher rating", y = "Income", 
       title = "Relationship between teaching and income in the three 
       biggest Swedish Universities") +
  theme(plot.title = element_text(hjust = 0.5))

# Uppsala have the best teaching and most income every year, whereas from 2013 to 2016, 
# Stockholm appears to be outperforming Gothenburg with a smaller budget apart from in 2016
str(timesData)
str(student_count_by_gender)

teacher_count <- timesData %>%
  mutate(teachers = student_num / student_staff_ratio)

teacher_count %>%
  ggplot(aes(teachers, student_num)) + 
  geom_point(aes(colour = country)) + facet_wrap(~year) +
  labs(x = "Teachers", y = "Students", 
       title = "Relationship between number of teachers and students") +
  theme(plot.title = element_text(hjust = 0.5)) + guides(colour = F)

# Difficult to see a relationship between staff and students here, we will now focus on
# removing the highest number of teachers and students first

teacher_count %>%
  filter(teachers < 6000, student_num < 150000) %>%
  ggplot(aes(teachers, student_num)) + 
  geom_point(aes(colour = country)) + 
  facet_wrap(~year) + 
  guides(colour = F) +
  labs(x = "Number of Teachers", y = "Number of Students", 
       title = "Relationship between number of teachers and students") +
  theme(plot.title = element_text(hjust = 0.5))

# There now appears to be a positive correlation between teachers and students, suggesting that
# class size is fairly constant throughout each university

# Look at median income levels in richest countries

timesData %>%
  filter(income > 90, income != 100) %>%
  ggplot(aes(country, income)) + 
  geom_boxplot(aes(fill = country)) + coord_flip() +
  labs(title = "Spread of Incomes for top Universities by Country") +
  theme(plot.title = element_text(hjust = 0.5))

# There appears to be a few NULL values here, with a mix of big spread of the middle 50% 
# quantile, while some are very small in spread, suggesting that either the count of
# universities is small, or there are several universities in this bracket that all 
# receive similar levels of funding, or that it is in fact the same university year on
# year. We can check this with some facetting.

timesData %>%
  filter(income > 90, income != 100) %>%
  ggplot(aes(country, income)) + 
  geom_boxplot(aes(fill = country)) + coord_flip() +
  labs(title = "Spread of Incomes for top Universities by Country") +
  theme(plot.title = element_text(hjust = 0.5)) + facet_wrap(~year)

# We can now count how many universities there are for the above parameters and place them 
# on the graphic

country_labels <- timesData %>%
  filter(income > 90, income != 100) %>%
  group_by(year, country) %>%
  summarise(count = n())

country_labels %>%
  ggplot(aes(country, count)) + 
  geom_bar(stat = "identity", aes(fill = country)) + 
  coord_flip() +
  geom_text(aes(label = count), hjust = -0.2) +
facet_wrap(~year) + labs(title = "Number of top universities in terms of income",
                         y = "Number of universities") +
  theme(plot.title = element_text(hjust = 0.5))



# A look at the number of students each year

student_count_by_gender %>%
  group_by(year) %>%
  ggplot(aes(student_num)) + 
  geom_density(fill = "green", colour = "black", size = 0.9) +
  facet_wrap(~year)

# There doesn't appear to be too much difference year on year. However, there appears 
# to be a very small amount of large values. We now eliminate these:

student_count_by_gender %>%
  group_by(year) %>%
  filter(student_num < 50000) %>%
  ggplot(aes(student_num)) + 
  geom_density(fill = "green", colour = "black", size = 0.9) +
  facet_wrap(~year) +
  labs(title = "Proportion of students at each university") + 
  theme(plot.title = element_text(hjust = 0.5))

# Relationship between teaching and income within the most populated universities

student_count_by_gender %>%
  group_by(year) %>%
  filter(student_num > 100000) %>%
  ggplot(aes(teaching, income, colour = university_name, size = 3)) + 
  geom_point() + facet_wrap(~year) +
  labs(title = "Relationship between teaching and income 
       for the most populated universities") +
  theme(plot.title = element_text(hjust = 0.5))

# Distribution of top universities in 2015 and 2016
top_university_dist <- timesData %>%
  filter(year == 2016, world_rank < 11) %>%
  group_by(country) %>%
  summarise(count = n())

top_university_dist <- as.data.frame(top_university_dist)

plot_ly(top_university_dist, labels = ~country, values = ~count, type = "pie",
        marker = list(colors = c("#FF0000", "#330099", "#333300"),
                      line = list(color = "#FFFFFF", width = 1)),
        textinfo = "country + percent",
        textposition = "inside",
        insidetextfont = list(color = "#FFFFFF"),
        showlegend = T) %>%
  layout(title = "Allocation of top 10  universities in 2016")

tud_2015 <- timesData %>%
  filter(year == 2015, world_rank < 11) %>%
  group_by(country) %>%
  summarise(count = n())

plot_ly(tud_2015, labels = ~country, values = ~count, type = "pie",
        marker = list(colors = c("#FF0000", "#330099"),
                      line = list(color = "#FFFFFF", width = 1)),
        textinfo = "country + percent",
        textposition = "inside", 
        insidetextfont = list(color = "#FFFFFF"),
        showlegend = T) %>%
  layout(title = "Allocation of top universities in 2015")


