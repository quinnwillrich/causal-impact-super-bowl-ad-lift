# 03_causal_impact.R
# Run CausalImpact on the Poppi Super Bowl 2025 campaign.
#
# Treated:    poppi (Google Trends search interest, US national)
# Controls:   olipop, la_croix, bubly
# Pre-period: 2024-11-01 to 2025-01-31 (92 days)
# Post-period: 2025-02-01 to 2025-03-16 (44 days, ends day before acquisition)
#
# Outputs:
#   output/plots/causal_impact_main.png  - standard 3-panel plot
#   output/reports/causal_impact_summary.txt  - numeric summary + narrative

library(CausalImpact)
library(zoo)
library(ggplot2)

dir.create("output/plots",   recursive = TRUE, showWarnings = FALSE)
dir.create("output/reports", recursive = TRUE, showWarnings = FALSE)

# --- Load and prepare data -----------------------------------------------

df <- read.csv("data/raw/poppi_trends_daily.csv")
df$date <- as.Date(df$date)

# CausalImpact wants column 1 = treated series, columns 2+ = controls.
# Drop spindrift (contaminated by Spindrift Soda product launch).
model_data <- df[, c("date", "poppi", "olipop", "la_croix", "bubly")]

# Convert to zoo object with dates as the time index
data_zoo <- zoo(model_data[, -1], order.by = model_data$date)

# --- Define analysis windows ---------------------------------------------

pre_period  <- as.Date(c("2024-11-01", "2025-01-31"))
post_period <- as.Date(c("2025-02-01", "2025-02-23"))

# --- Fit the model -------------------------------------------------------
# nseasons = 7 captures day-of-week seasonality. season.duration = 1 means
# each "season" is one observation (one day), so the cycle repeats weekly.

impact <- CausalImpact(
  data        = data_zoo,
  pre.period  = pre_period,
  post.period = post_period,
  model.args  = list(niter = 5000, nseasons = 7, season.duration = 1)
)

# --- Console output ------------------------------------------------------

cat("\n=== Numeric summary ===\n\n")
print(summary(impact))

cat("\n=== Narrative report ===\n\n")
print(summary(impact, "report"))

# --- Save the standard CausalImpact plot ---------------------------------

p <- plot(impact) +
  ggtitle("Poppi Super Bowl 2025 campaign — search interest lift",
          subtitle = "Pre-period: Nov 1 2024 – Jan 31 2025  |  Post-period: Feb 1 – Mar 16 2025") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "plain", size = 13),
        plot.subtitle = element_text(color = "gray40"))

ggsave("output/plots/causal_impact_main.png", p,
       width = 10, height = 8, dpi = 150, bg = "white")

# --- Save the narrative report to disk -----------------------------------

sink("output/reports/causal_impact_summary.txt")
cat("CausalImpact analysis: Poppi Super Bowl 2025 campaign\n")
cat("=====================================================\n\n")
cat("Pre-period:  ", format(pre_period[1]),  "to", format(pre_period[2]),  "\n")
cat("Post-period: ", format(post_period[1]), "to", format(post_period[2]), "\n")
cat("Controls:    olipop, la_croix, bubly (spindrift dropped: own product launch confound)\n\n")
cat("--- Numeric summary ---\n\n")
print(summary(impact))
cat("\n--- Narrative report ---\n\n")
print(summary(impact, "report"))
sink()

cat("\nSaved plot to output/plots/causal_impact_main.png\n")
cat("Saved report to output/reports/causal_impact_summary.txt\n")