# 04_placebo_tests.R
# Run multiple placebo tests using fake intervention dates inside the
# pre-period. If our model+controls are well-specified, all four
# estimates should be near zero with credible intervals including zero.
# Variance across them tells us about model stability vs real events.
#
# All placebo dates are Sundays (matching Super Bowl Sunday's DOW).
# All use 23-day post-periods (matching the real analysis).
#
# Output:
#   output/plots/placebo_tests_combined.png
#   output/reports/placebo_tests_summary.txt

library(CausalImpact)
library(zoo)
library(ggplot2)

dir.create("output/plots",   recursive = TRUE, showWarnings = FALSE)
dir.create("output/reports", recursive = TRUE, showWarnings = FALSE)

# --- Load data -----------------------------------------------------------

df <- read.csv("data/raw/poppi_trends_daily.csv")
df$date <- as.Date(df$date)

model_data <- df[, c("date", "poppi", "olipop", "la_croix", "bubly")]
data_zoo <- zoo(model_data[, -1], order.by = model_data$date)

# Restrict to data BEFORE real intervention so no placebo can see it.
data_zoo_pretreat <- window(data_zoo, end = as.Date("2025-01-31"))

# --- Define placebo windows ----------------------------------------------

placebo_dates <- list(
  list(name = "Nov 17 2024",
       pre  = c("2024-11-01", "2024-11-16"),
       post = c("2024-11-17", "2024-12-09")),
  list(name = "Dec 1 2024",
       pre  = c("2024-11-01", "2024-11-30"),
       post = c("2024-12-01", "2024-12-23")),
  list(name = "Dec 15 2024",
       pre  = c("2024-11-01", "2024-12-14"),
       post = c("2024-12-15", "2025-01-06")),
  list(name = "Jan 5 2025",
       pre  = c("2024-11-01", "2025-01-04"),
       post = c("2025-01-05", "2025-01-27"))
)

# --- Run all placebos ----------------------------------------------------

results <- list()

for (p in placebo_dates) {
  cat("\nRunning placebo for", p$name, "...\n")
  
  pre  <- as.Date(p$pre)
  post <- as.Date(p$post)
  
  fit <- CausalImpact(
    data        = data_zoo_pretreat,
    pre.period  = pre,
    post.period = post,
    model.args  = list(niter = 5000, nseasons = 7, season.duration = 1)
  )
  
  s <- fit$summary
  results[[p$name]] <- data.frame(
    placebo_date = p$name,
    rel_effect   = s$RelEffect[1]    * 100,
    rel_lower    = s$RelEffect.lower[1] * 100,
    rel_upper    = s$RelEffect.upper[1] * 100,
    abs_effect   = s$AbsEffect[1],
    p_value      = s$p[1]
  )
}

# Combine into one table, plus add real result for visual comparison
results_df <- do.call(rbind, results)
real_result <- data.frame(
  placebo_date = "Feb 1 2025 (REAL)",
  rel_effect   = 44,
  rel_lower    = 34,
  rel_upper    = 54,
  abs_effect   = 8.53,
  p_value      = 0.0002
)
all_results <- rbind(results_df, real_result)
all_results$placebo_date <- factor(all_results$placebo_date,
                                   levels = all_results$placebo_date)
all_results$is_real <- all_results$placebo_date == "Feb 1 2025 (REAL)"

# --- Console output ------------------------------------------------------

cat("\n=== ALL PLACEBO RESULTS + REAL ===\n\n")
print(all_results, row.names = FALSE, digits = 3)

# --- Forest-style plot ---------------------------------------------------

p_plot <- ggplot(all_results,
                 aes(x = rel_effect, y = placebo_date, color = is_real)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = rel_lower, xmax = rel_upper), height = 0.2) +
  geom_point(size = 3) +
  scale_color_manual(values = c("FALSE" = "#888780", "TRUE" = "#534AB7"),
                     guide = "none") +
  labs(
    title    = "Placebo tests vs. real campaign estimate",
    subtitle = "Each row: relative effect estimate with 95% credible interval. Dashed line = no effect.",
    x = "Relative effect (%)",
    y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title    = element_text(face = "plain", size = 13),
        plot.subtitle = element_text(color = "gray40"),
        panel.grid.minor = element_blank())

print(p_plot)
ggsave("output/plots/placebo_tests_combined.png", p_plot,
       width = 9, height = 5, dpi = 150, bg = "white")

# --- Save report ---------------------------------------------------------

sink("output/reports/placebo_tests_summary.txt")
cat("PLACEBO TESTS: Multiple fake intervention dates\n")
cat("================================================\n\n")
cat("Purpose: assess whether the model produces consistent ~zero effects\n")
cat("on dates when no known intervention occurred. Variance across placebos\n")
cat("tells us about model bias vs. detection of unknown real events.\n\n")
cat("All placebo dates are Sundays inside the pre-period.\n")
cat("All use a 23-day post-period (matching real analysis).\n\n")
print(all_results, row.names = FALSE, digits = 3)
sink()

cat("\nSaved plot to output/plots/placebo_tests_combined.png\n")
cat("Saved report to output/reports/placebo_tests_summary.txt\n")