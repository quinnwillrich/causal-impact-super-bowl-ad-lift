# 02_explore.R
# Visualize all five Trends series with key event annotations.
# Output: output/plots/all_series.png

# Run once if not yet installed:
# install.packages(c("tidyr"), type = "binary")

library(ggplot2)
library(tidyr)

dir.create("output/plots", recursive = TRUE, showWarnings = FALSE)

# Load data
df <- read.csv("data/raw/poppi_trends_daily.csv")
df$date <- as.Date(df$date)

# Reshape to long format
df_long <- pivot_longer(df, -date, names_to = "brand", values_to = "hits")
df_long$brand <- factor(df_long$brand,
                        levels = c("poppi", "olipop", "spindrift", "la_croix", "bubly"))

# Key event dates
super_bowl  <- as.Date("2025-02-09")
acquisition <- as.Date("2025-03-17")
pre_end     <- as.Date("2025-01-31")

# Color palette: treated brand prominent, contaminated controls warm,
# clean controls cool
brand_colors <- c(
  poppi     = "#534AB7",  # treated
  olipop    = "#D85A30",  # contaminated by SB spillover
  spindrift = "#BA7517",  # contaminated by own product launch
  la_croix  = "#0F6E56",  # clean
  bubly     = "#185FA5"   # clean
)

p <- ggplot(df_long, aes(x = date, y = hits, color = brand)) +
  geom_vline(xintercept = pre_end,     linetype = "dotted", color = "gray60") +
  geom_vline(xintercept = super_bowl,  linetype = "dashed", color = "gray40") +
  geom_vline(xintercept = acquisition, linetype = "dashed", color = "gray40") +
  geom_line(aes(linewidth = brand == "poppi"), alpha = 0.85) +
  scale_linewidth_manual(values = c("FALSE" = 0.4, "TRUE" = 0.9), guide = "none") +
  scale_color_manual(values = brand_colors) +
  annotate("text", x = super_bowl,  y = 102, label = "Super Bowl",
           hjust = -0.05, size = 3, color = "gray30") +
  annotate("text", x = acquisition, y = 102, label = "PepsiCo deal",
           hjust = -0.05, size = 3, color = "gray30") +
  annotate("text", x = pre_end,     y = 102, label = "Pre-period ends",
           hjust = 1.05, size = 3, color = "gray50") +
  scale_y_continuous(limits = c(0, 110), breaks = c(0, 25, 50, 75, 100)) +
  labs(
    title    = "Daily Google Trends search interest, US",
    subtitle = "Poppi (treated) vs four peer brand controls, Nov 2024 – Apr 2025",
    x = NULL,
    y = "Search interest (0–100, per brand)",
    color = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title    = element_text(face = "plain", size = 13),
    plot.subtitle = element_text(color = "gray40"),
    panel.grid.minor = element_blank()
  )

print(p)

ggsave("output/plots/all_series.png", p,
       width = 10, height = 5.5, dpi = 150, bg = "white")
cat("Saved plot to output/plots/all_series.png\n")