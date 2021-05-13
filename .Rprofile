.First <- function() {

  # set TZ if unset
  if (is.na(Sys.getenv("TZ", unset = NA)))
    Sys.setenv(TZ = "America/New_York")

  # bail if revo R
  if (exists("Revo.version"))
    return()

  # only run in interactive mode
  if (!interactive())
    return()

  # bail in Docker environments
  if (!is.na(Sys.getenv("DOCKER", unset = NA)))
    return()

  # create .Rprofile env
  .__Rprofile.env__. <- attach(NULL, name = "local:rprofile")

  # helpers for setting things in .__Rprofile.env__.
  set <- function(name, value)
    assign(name, value, envir = .__Rprofile.env__.)

  set(".Start.time", as.numeric(Sys.time()))

  NAME <- intToUtf8(c( 71L, 97L, 114L, 114L, 101L, 116L, 116L, 32L,
                      77L, 111L, 111L, 110L, 101L, 121L ))
  EMAIL <- intToUtf8( c( 103L, 109L, 111L, 111L, 110L, 101L, 121L,
                        64L, 109L, 97L, 105L, 108L, 46L, 98L, 114L, 97L, 100L,
                        108L, 101L, 121L, 46L, 101L, 100L, 117L ) )

  options(
    # CRAN
    repos = c(CRAN='https://cloud.r-project.org'),

    # source packages for older R
    #pkgType = pkgType,

    # no tcltk
    menu.graphics = FALSE,

    # don't treate newlines as synonym to 'n' in browser
    browserNLdisabled = TRUE,

    # keep source code as-is for package installs
    keep.source = TRUE,
    keep.source.pkgs = TRUE,

    # no fancy quotes (makes copy + paste a pain)
    useFancyQuotes = FALSE,

    # warn on partial matches
    # warnPartialMatchArgs = TRUE ## too disruptive
    warnPartialMatchAttr = TRUE,
    warnPartialMatchDollar = TRUE,

    # warn right away
    warn = 1,
    warning.length = 8170,

    # devtools related options
    devtools.desc = list(
      Author = NAME,
      Maintainer = paste(NAME, " <", EMAIL, ">", sep = ""),
      License = "MIT + file LICENSE",
      Version = "0.0.1"
    ),

    devtools.name = NAME
  )

  # if using 'curl' with RStudio, ensure stderr redirected
  method <- getOption("download.file.method")
  if (is.null(method)) {
     if (getRversion() >= "3.4.0" && capabilities("libcurl")) {
        options(
           download.file.method = "libcurl",
           download.file.extra  = NULL
        )
     } else if (nzchar(Sys.which("curl"))) {
        options(
           download.file.method = "curl",
           download.file.extra = "-L -f -s --stderr -"
        )
     }
  }

  # always run Rcpp tests
  Sys.setenv(RunAllRcppTests = "yes")

  # auto-completion of package names in `require`, `library`
  utils::rc.settings(ipck = TRUE)

  # generate some useful aliases, for editing common files
  alias <- function(name, action) {
    placeholder <- structure(list(), class = sprintf("__%s__", name))
    assign(name, placeholder, envir = .__Rprofile.env__.)
    assign(sprintf("print.__%s__", name), action, envir = .__Rprofile.env__.)
  }

  # open .Rprofile for editing
  alias(".Rprofile", function(...) file.edit("~/.Rprofile"))
  alias(".Renviron", function(...) file.edit("~/.Renviron"))

  # open Makevars for editing
  alias("Makevars", function(...) {
    if (!utils::file_test("-d", "~/.R"))
      dir.create("~/.R")
    file.edit("~/.R/Makevars")
  })

  # simple CLI to git
  git <- new.env(parent = emptyenv())
  commands <- c("clone", "init", "add", "mv", "reset", "rm",
                "bisect", "grep", "log", "show", "status", "stash",
                "branch", "checkout", "commit", "diff", "merge",
                "rebase", "tag", "fetch", "pull", "push", "clean")

  for (command in commands) {

    code <- substitute(
      system(paste(path, "-c color.status=false", command, ...)),
      list(path = quote(shQuote(normalizePath(Sys.which("git")))),
           command = command)
    )

    fn <- eval(call("function", pairlist(... = quote(expr = )), code))

    assign(command, fn, envir = git)

  }

  assign("git", git, envir = .__Rprofile.env__.)

  # tools for munging the PATH
  PATH <- (function() {

    read <- function() {
      strsplit(Sys.getenv("PATH"), .Platform$path.sep, TRUE)[[1]]
    }

    write <- function(path) {
      Sys.setenv(PATH = paste(path, collapse = .Platform$path.sep))
      invisible(path)
    }

    prepend <- function(dir) {
      dir <- normalizePath(dir, mustWork = TRUE)
      path <- c(dir, setdiff(read(), dir))
      write(path)
    }

    append <- function(dir) {
      dir <- normalizePath(dir, mustWork = TRUE)
      path <- c(setdiff(read(), dir), dir)
      write(path)
    }

    remove <- function(dir) {
      path <- setdiff(read(), dir)
      write(path)
    }

    list(
      read = read,
      write = write,
      prepend = prepend,
      append = append,
      remove = remove
    )

  })()
  assign("PATH", PATH, envir = .__Rprofile.env__.)

  # ensure commonly-used packages are installed, loaded
  quietly <- function(expr) {
    status <- FALSE
    suppressWarnings(suppressMessages(
      utils::capture.output(status <- expr)
    ))
    status
  }

  install <- function(package) {

    code <- sprintf(
      "utils::install.packages(%s, lib = %s, repos = %s)",
      shQuote(package),
      shQuote(.libPaths()[[1]]),
      shQuote(getOption("repos")[["CRAN"]])
    )

    R <- file.path(
      R.home("bin"),
      if (Sys.info()[["sysname"]] == "Windows") "R.exe" else "R"
    )

    con <- tempfile(fileext = ".R")
    writeLines(code, con = con)
    on.exit(unlink(con), add = TRUE)

    cmd <- paste(shQuote(R), "-f", shQuote(con))
    system(cmd, ignore.stdout = TRUE, ignore.stderr = TRUE)
  }

  packages <- c(#"devtools", "roxygen2", "knitr", "rmarkdown", "testthat",
                "remotes", "glue", "fs", "moonmisc", "bplyr", "rlang")
  invisible(lapply(packages, function(package) {

    if (quietly(require(package, character.only = TRUE, quietly = TRUE)))
      return()

    message("Installing '", package, "' ... ", appendLF = FALSE)
    install(package)

    success <- quietly(require(package, character.only = TRUE, quietly = TRUE))
    message(if (success) "OK" else "FAIL")

  }))

if(interactive()){
  options(prompt = "\033[34m> \033[39m")
  options("Ncpus" = 8L)

  options(
    radian.color_scheme = "native",
    radian.auto_indentation = FALSE,
    radian.editing_mode = "vi")

  withOptions <- function(optlist, expr)
  {
    oldopt <- options(optlist)
    on.exit(options(oldopt))
    expr <- substitute(expr)
    eval.parent(expr)
  }

  less = function(x) {
    withOptions(list(pager='less', dplyr.print_min=.Machine$integer.max, width=10000, max.print=1e6), page(x, method='print'))
  }

  # Assign shortcuts to a hidden environment, so they don't show up in ls()
  # Idea from https://csgillespie.github.io/efficientR/set-up.html#creating-hidden-environments-with-.rprofile
  .env <- new.env()
  with(.env, {
      shortcut <- function(f) structure(f, class = "shortcut")
      print.shortcut <- function(f, ...) f(...)

      p <- shortcut(covr::package_coverage)

      rs <- shortcut(function(file = "script.R", echo = TRUE, ...) source(file, echo = echo, ...))

      li <- shortcut(library)
      l <- shortcut(devtools::load_all)

      #i <- shortcut(devtools::install)
      gh <- shortcut(devtools::install_github)

      id <- shortcut(function(dependencies = TRUE, ...) {
          devtools::install_deps(dependencies = dependencies, ...)
          })

      ch <- shortcut(function(document = FALSE, ...) {
          devtools::check(document = document, ...)
          })
      d <- shortcut(devtools::document)

      # gaborcsardi/tracer
      #tb <- shortcut(tracer::tb)
      si <- shortcut(devtools::session_info)
      up <- shortcut(function(Ncpus = 8, ...) {
        update.packages(Ncpus = Ncpus, ...)
      })

        # t <- shortcut(
        #   test <- function(filter = NULL, length = 5, pkg = ".", ..., reporter = "progress") {
        #     if (is.null(reporter)) {
        #     #reporter <- testthat::SummaryReporter$new()
        #     #reporter$max_reports = length
        #     #reporter <- testthat:::ProgressReporter$new()
        #     }
        #     devtools::test(pkg, filter, reporter = reporter, ...)
        #     })

      # jennybc/reprex
      re <- shortcut(reprex::reprex)

        qq <- shortcut(function() {
            #savehistory()
            base::q(save="no")
            })

      echo <- function(x) {
        cat(readLines(x), sep = "\n")
      }

      ggp <-shortcut(ggplot2::ggplot)
  })
  # We need to attach stats before .env to shadow qt
  library(stats)
  suppressMessages(attach(.env))
  # library(ggplot2)

  #use white backgrounds
  #theme_set(theme_bw())

  ##colorblind palette
  #cb_palette <-c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

  #use color brewer as default discrete colors
  #scale_colour_discrete <- function(...) scale_color_brewer(palette="Set1", ...)
  #scale_fill_discrete <- function(...) scale_fill_brewer(palette="Set1", ...)

  #log_ticks <- function(which="xy", ...){
    #require(scales)
    #object = list()
    #location = ''
    #if(grepl('x', which)){
      #object = list(object,
                    #scale_x_log10(breaks=trans_breaks("log10", function(x) 10^x),
                                  #labels=trans_format("log10",math_format(10^.x)),
                                  #minor_breaks=trans_breaks("log10", function(x) 10^x/2)
                                  #)
                    #)
      #location = paste(location, 'b', sep='')
    #}
    #if(grepl('y', which)){
      #object = list(object,
                    #scale_y_log10(breaks=trans_breaks("log10", function(x) 10^x),
                                  #labels=trans_format("log10",math_format(10^.x)),
                                  #minor_breaks=trans_breaks("log10", function(x) 10^x/2)
                                  #)
                    #)
      #location = paste(location, 'l', sep='')
    #}
    #list(annotation_logticks(..., sides=location), object)
  #}

  # library(devtools)

  # helper function to convert a data frame print output to an actual data frame
  .env$convert_data.frame <- function(x) {
    lines <- strsplit(x, "\n")[[1]]

    locs <- rex::re_matches(lines[1], rex::rex(non_spaces), global = TRUE, locations = TRUE)[[1]]

    rowname_size <- rex::re_matches(lines[length(lines)], rex::rex(non_spaces), locations = TRUE)

    starts <- c(rowname_size$end + 1, locs$end[-length(locs$end)] + 1)
    ends <- locs$end

    remove_whitespace <- function(x) {
      re_substitutes(x, rex::rex(list(start, any_spaces) %or% list(any_spaces, end)), '', global = TRUE)
    }

    fields <- lapply(lapply(lines, substring, starts, ends), remove_whitespace)

    df <- as.data.frame(matrix(unlist(fields[-1]), ncol = length(fields[[1]]), byrow = TRUE), stringsAsFactors = FALSE)
    df[] <- lapply(df, type.convert, as.is=TRUE)
    colnames(df) <- fields[[1]]
    df
  }

  .env$shuf <- function(x, n = 6) {
    if (is.null(dim(x))) {
      x[sample.int(length(x), min(n, length(x)))]
    } else {
      x[sample.int(NROW(x), min(n, NROW(x))), , drop = FALSE]
    }
  }

  .env$`%>%` <- magrittr::`%>%`
  .env$`%<>%` <- magrittr::`%<>%`

  # jimhest/lookup
  suppressPackageStartupMessages(library(lookup))

  # jimhest/autoinst
  options(error = autoinst::autoinst)
}

  # clean up extra attached envs
  addTaskCallback(function(...) {
    count <- sum(search() == "local:rprofile")
    if (count == 0)
      return(FALSE)

    for (i in seq_len(count - 1))
      detach("local:rprofile")

    return(FALSE)
  })

  # display startup message(s)
  msg <- if (length(.libPaths()) > 1)
    "Using libraries at paths:\n"
  else
    "Using library at path:\n"
  libs <- paste("-", .libPaths(), collapse = "\n")
  message(msg, libs, sep = "")
}
