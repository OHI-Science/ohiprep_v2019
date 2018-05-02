## correcting the GenEsc gapfilling 
## (had 1 and 0 values reversed)

library(dplyr)

esc <- read.csv("globalprep/mar/v2017/output/GenEsc_gf.csv")
esc <- esc %>%
  mutate(pressures.score = 1-pressures.score)
write.csv(esc, "globalprep/mar/v2017/output/GenEsc_gf.csv", row.names=FALSE)
