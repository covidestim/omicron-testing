library(magrittr)
library(readr)
library(dplyr)

d_ <- read_csv(
  "case-death-rr-state.csv",
  col_types = cols_only(
    date = col_date(),
    state = col_character(),
    cases = col_number(),
    deaths = col_number(),
    RR = col_number()
  )
)

# State input data current as of 2022-01-11. Returned as a list for 
# ease-of-use with Covidestim package
getStateInputs <- function(stateName) {

  d1 <- filter(d_, state == stateName)

  list(
    cases = select(d1, date, observation = cases),
    deaths = select(d1, date, observation = deaths),
    RR = select(d1, date, observation = RR),
    ndays = nrow(d1)
  )
}
