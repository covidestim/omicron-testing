  # master
  set0 <- data.frame(
    group               = "master",
    dateoffset          = seq(0, -40, by = -2),
    "nspl_rt_knotwidth" = 5,
    "sd_omicron_delay"  = 1,
    "reinfection"       = FALSE,
    "nRt"               = 0, 
    "omicron_adjust"    = FALSE
  )

  # only knotwidth
  set1 <- expand.grid(
    group               = "knotwidth",
    dateoffset          = seq(0, -40, by = -2),
    "nspl_rt_knotwidth" = 10,
    "sd_omicron_delay"  = 1,
    "reinfection"       = FALSE,
    "nRt"               = 0, 
    "omicron_adjust"    = FALSE
  ) 

### setup for testing
nspl_rt_knotwidth = 10
nRt = c(0,1)
sd_omicron_delay = c(10,20)
reinfection = c(TRUE, FALSE)
omicron_adjust = TRUE

# # omicron and reinfection tests
# set2 <- expand.grid(
#   group               = "omicron/reinfection",
#   dateoffset          = 0,
#   "nspl_rt_knotwidth" = 10,
#   "sd_omicron_delay"  = sd_omicron_delay,
#   "reinfection"       = reinfection,
#   "nRt"               = nRt, 
#   "omicron_adjust"    = onicron_adjust
# ) 

# omicron and reinfection tests, with sliding dates
set3 <- expand.grid(
  group               = "omicron/reinfection/slidingdates",
  dateoffset          = seq(0, -40, by = -2),
  "nspl_rt_knotwidth" = 10,
  "sd_omicron_delay"  = 20,#sd_omicron_delay,
  "reinfection"       = TRUE,#reinfection,
  "nRt"               = 1,#nRt, 
  "omicron_adjust"    = TRUE#omicron_adjust
) 
# omicron and reinfection tests, with sliding dates
set4 <- expand.grid(
  group               = "reinfection/slidingdates",
  dateoffset          = seq(0, -40, by = -2),
  "nspl_rt_knotwidth" = 10,
  "sd_omicron_delay"  = 1,
  "reinfection"       = TRUE,#reinfection,
  "nRt"               = 1,#nRt, 
  "omicron_adjust"    = FALSE
) 

testset <- rbind(set0, set1, set3, set4)


