# 01_pull_data.R
# Pulls Google Trends search interest for Poppi and peer brands
# (US national, daily) for the 2025 Super Bowl analysis.
#
# Output: data/raw/poppi_trends_daily.csv

# Run once if gtrendsR is not yet installed:
# install.packages("gtrendsR", type = "binary")

library(gtrendsR)

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)

keywords <- c("poppi", "olipop", "spindrift", "la croix", "bubly")
time_range <- "2024-11-01 2025-04-30"  # 181 days — under the 270-day daily threshold

pull_one <- function(kw) {
  cat("Fetching", kw, "...\n")
  res <- gtrends(keyword = kw, geo = "US", time = time_range, onlyInterest = TRUE)
  df <- res$interest_over_time[, c("date", "hits")]
  df$hits <- as.numeric(df$hits)
  names(df)[2] <- gsub(" ", "_", kw)
  Sys.sleep(2)
  df
}

all_data <- pull_one(keywords[1])
for (kw in keywords[-1]) {
  all_data <- merge(all_data, pull_one(kw), by = "date", all = TRUE)
}

all_data$date <- as.Date(all_data$date)

write.csv(all_data, "data/raw/poppi_trends_daily.csv", row.names = FALSE)

cat("\nSaved", nrow(all_data), "rows to data/raw/poppi_trends_daily.csv\n\n")
print(head(all_data, 20))
print(tail(all_data, 20))