#!/usr/bin/Rscript

library(clustermq)
library(cli)
library(docopt)
suppressPackageStartupMessages( library(dplyr) )
library(glue)
library(readr)

glue('covidestim runBatch utility

Usage:
  {name} -o <output_path> --tests <tests> --code <code> --time <time> --jobsperworker <jobsperworker> [--sampler]
  {name} (-h | --help)
  {name} --version

Options:
  -o <output_path>   Where to save the return value of the run() function (.RDS)
  --tests <tests>    Path to an RDS archive, a tibble of tests to run
  --code <code>      Path to the .stan model
  --time <time>      Timelimit, in minutes, per run
  --jobsperworker <jobsperworker>  How many jobs per worker
  --sampler          Run with the sampler
  -h --help          Show this screen.
  --version          Show version.
', name = "runBatch.R") -> doc

args <- docopt(doc, version = "0.1")
print(args)
ps <- cli_process_start
pd <- cli_process_done

ps("Reading tests from {.file {args$tests}}")
tests        <- readRDS(args$tests)
pd()

codePath     <- args$code
time_per_run <- as.numeric(args$time)
jobs_per_worker <- as.numeric(args$jobsperworker)
sampler <- args$sampler

fMultiple <- function(
  model_code,
  data,
  tries   = 10,
  iter    = 6e3,
  timeout = 5*60,
  sampler = FALSE
) {
  rstan_options(auto_write = T)
  model <- stan_model(model_code = model_code)
  
  if(sampler == TRUE) {
    
    rstan::sampling(
      object  = model,
      data    = data,
      cores   = 3,
      control = list(adapt_delta = .98, max_treedepth = 14),
      seed    = 42,
      chains  = 3,
      iter    = 2000,
      thin    = 1,
      warmup  = round((2/3)*2000)) -> result
    
    result   = rstan::summary(result)$summary
    
    return(result)
    
  }
  runOptimizerWithSeed <- function(i) {
    startTime <- Sys.time()

    rstan::optimizing(
      object    = model,
      data      = data,
      algorithm = "BFGS",
      iter      = iter,
      as_vector = FALSE # Otherwise you get a sloppy list structure
    ) -> result

    endTime <- Sys.time()

    message(glue::glue(
      'Finished try #{i} in {dt} with exit code {ec}',
      dt = prettyunits::pretty_dt(endTime - startTime),
      ec = result$return_code
    ));

    result
  }

  # This function will return NULL when there is a timeout
  runOptimizerWithSeedInTime <- function(i, timeout)
    tryCatch(
      R.utils::withTimeout(runOptimizerWithSeed(i), timeout = timeout),
      error = function(c) {
        message(glue::glue('Abandoned try #{i} due to timeout'))

        NULL
      }
    )

  results <- NULL

  
  # Return the first time we get a non-obviously-bad result from BFGS, to save
  # time.
  for (i in 1:tries) {
    r <- runOptimizerWithSeedInTime(i, timeout)
    # Return code of 0 indicates success for `rstan::optimizing`. This is just
    # a standard UNIX return code b/c `rstan::optimizing` calls into CmdStan.
    # 
    # Timed-out runs return NULL.
    #
    # In theory the log posterior could be infinite (likely, -Infinity), which
    # wouldn't be valid but would technically be the maximum value. Exclude
    # runs which have these values.
    # if (!is.null(r) && (r$return_code[1] == 0) && !is.infinite(r$value)) {
    #   message("[#{i}]: Good result!")
    #   result <- r # Commit the result as the final result
    #   break
    # }
    results[[i]] <- r
  }
  
  successful_results <-
    purrr::discard(results, is.null) %>% # Removes timed-out runs
    purrr::keep(., ~.$return_code == 0)  # Removes >0 return-val runs
  
  if (length(successful_results) == 0)
    stop("All BFGS runs timed out or failed!")
  
  # Extract the mode of the posterior from the results that didn't time out
  # and didn't return an error code of 70
  opt_vals <- purrr::map_dbl(successful_results, 'value') 
  
  # In theory the log posterior could be infinite (likely, -Infinity), which
  # wouldn't be valid but would technically be the maximum value. Throw an
  # error in this case.
  if (is.infinite(max(opt_vals)))
    stop(glue::glue(
      'The value of the log posterior was infinite for these runs:\n{runs}',
      runs = which(is.infinite(opt_vals) & opt_vals > 0)
    ))
  
  # The first successful result which has `opt_val` equal to the maximum
  # `opt_val` is the result that will be returned too the user. Note that it's
  # unlikely that there will be more that one trajectory with the same
  # `opt_val`. However, if this is the case, the first of these results will
  # be returned
  result <- successful_results[which(opt_vals == max(opt_vals))][[1]]
  # 
  # if (is.null(result)) # Branch only occurs if no good result was I.D.'d.
  #   stop("All BFGS runs timed out or failed or had Inf log-posteriors!")

  result
}
# Use ClusterMQ to connect to the cluster, compile the model, and run it.
# This function can easily be modified to perform various experiments. See
# the docs: `?clustermq::Q`. Worker logs will be found in `~/`.
run <- function(f, tests, codePath, jobs_per_worker = 4, time_per_run = 12, cores=1) {
  result <- Q(
    f,
    data          = tests$config,
    const         = list(model_code = read_file(codePath)),
    job_size      = jobs_per_worker,
    log_worker    = T,
    pkgs          = c('rstan', 'glue', 'prettyunits'),
    fail_on_error = F,
    template      = list(
      time = jobs_per_worker * time_per_run,
      cores = cores
    )
  )

  mutate(tests, result = result)
}

cli_alert_info("Starting {.val {nrow(tests)}} tests")
test_results <- run(
  f               = fMultiple,
  tests           = tests,
  codePath        = codePath,
  jobs_per_worker = jobs_per_worker,
  time_per_run    = time_per_run
  sampler         = sampler,
  cores           = ifelse(sampler, 3, 1)
)
cli_alert_info("Finished tests")

ps("Saving results to {.file {args$o}}")
saveRDS(test_results, args$o)
pd()
