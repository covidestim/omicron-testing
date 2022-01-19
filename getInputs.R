library(magrittr)
library(readr)
library(dplyr)

ds_ <- read_csv(
  "case-death-rr-state.csv",
  col_types = cols_only(
    date = col_date(),
    state = col_character(),
    cases = col_number(),
    deaths = col_number(),
    RR = col_number()
  )
)

dc_ <- read_csv(
  "case-death-rr.csv",
  col_types = cols_only(
    date = col_date(),
    fips = col_character(),
    cases = col_number(),
    deaths = col_number(),
    RR = col_number()
  )
)

# State input data current as of 2022-01-11. Returned as a list for 
# ease-of-use with Covidestim package
getStateInputs <- function(stateName) {

  d1 <- filter(ds_, state == stateName)

  list(
    cases = select(d1, date, observation = cases),
    deaths = select(d1, date, observation = deaths),
    RR = select(d1, date, observation = RR),
    ndays = nrow(d1)
  )
}


# County input data current as of 2022-01-11. Returned as a list for 
# ease-of-use with Covidestim package
getCountyInputs <- function(fipsCode) {

  d1 <- filter(dc_, fips == fipsCode)

  list(
    cases = select(d1, date, observation = cases),
    deaths = select(d1, date, observation = deaths),
    RR = select(d1, date, observation = RR),
    ndays = nrow(d1)
  )
}

getInputs <- function(geoName) {
  if (str_detect(geoName, '[0-9]{5}'))
    return(getCountyInputs(geoName))
  else
    return(getStateInputs(geoName))
}
