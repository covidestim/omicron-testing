library(covidestim) # Careful! Be sure this is the right version of the package
library(purrr)

# Generate a vanilla Covidestim configuration and extract out of it the data
# which needs to be passed to RStan.
getConfig <- function(d, region, dateoffset = 0, ...) {
  ndays <- d$ndays - abs(dateoffset)

  cfg <- covidestim(ndays = ndays, region = region, ...) +
    input_cases(d$cases[1:ndays,]) +
    input_deaths(d$deaths[1:ndays,]) +
    input_vaccines(d$RR[1:ndays,])

  cfg$config
}

getConfigs <- function(df)
  pmap_dfr(
    df,
    function(group, d, region, ...)
      list(
        group = group,
        d = list(d),
        region = region,
        ...,
        config = list(getConfig(d, region, ...))
      )
  )

