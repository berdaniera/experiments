library(httr)
library(tibble)
library(dplyr)
library(purrr)
library(readr)

token <- read_rds("token.rds")

u_url <- "https://slack.com/api/users.list"
user_request <- POST(u_url, body=list(token=token))

if(user_request$status_code == 200){
  user_data <- content(user_request)[[2]]
  users <- map_df(user_data, magrittr::extract, c("name", "is_bot", "deleted")) %>% 
    filter(!is_bot, !deleted, name!="slackbot") %>% .$name
}

# load all users
all_names <- read_rds("all_names.rds")

# check new users, if new ones, add to master list
if(exists("users")){
  if(!all(users %in% all_names)){
    new_names <- users[!users %in% all_names]
    all_names <- c(all_names, new_names)
    write_rds(all_names, "all_names.rds")
  }
}

# Get subset of names that are not used yet
used_names <- read_rds("used_names.rds")
if(all(all_names %in% used_names)){
  # we've used them all up
  # erase used names
  used_names <- c()
  # eligible names is all names
  eligible_names <- all_names
}else{
  eligible_names <- all_names[!all_names %in% used_names]
}

# draw new user
kitchen_cleaner <- sample(eligible_names, 1)

# send message to rasi
p_url <- "https://slack.com/api/chat.postMessage"
channel <- "@rasi"
intext <- paste0("New kitchen cleanup (", Sys.Date(), "): ", kitchen_cleaner)
send_info <- POST(p_url, body=list(token=token, channel=channel, text=intext))

if(send_info$status_code==200){
  # success, update used names list
  # add new name to names that are used
  used_names <- c(used_names, kitchen_cleaner)
  # save used_names
  write_rds(used_names, "used_names.rds")
}else{
  #fail, save error data
  error_data <- tibble(date=Sys.Date(), user=kitchen_cleaner)
  write_csv(error_data, "error_data.csv", append=TRUE)
}
