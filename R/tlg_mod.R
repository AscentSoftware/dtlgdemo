#' TLG Module
#'
#' @description
#' A module that compares the generation time using thedtlg package with
#' equivalent functoinality that exists using tidyverse/pharmaverse functionality.
#'
#' The aim of this module is to show the speed improvement of using
#' dtlg over the other packages.
#'
#' @param id An ID string list identifies the namespace of the UI and server components.
#' @param params A named vector of function arguments that are set in the UI to allow
#' interactivity of creating the table. By default none are selected.
#'
#' @rdname tlg_mod
tlgModUI <- function(id, params = NULL) {
  ns <- NS(id)

  tagList(
    if (length(params) > 0L)
      bslib::card(
        bslib::card_header("Table Parameters"),
        bslib::card_body(
          div(
            class = "row g-4",
            purrr::imap(params, \(param_info, id) {
              selectizeInput(
                inputId = ns(id),
                label = param_info$label,
                choices = NULL,
                multiple = param_info$multiple,
                options = list(dropdownParent = "body")
              )
            })
          )
        )
      ),
    bslib::card(
      bslib::card_header("Runtime Comparison"),
      bslib::card_body(
        div(
          class = "d-flex align-items-center gap-3 mb-3",
          actionButton(ns("run"), "Run comparison", class = "btn-primary"),
          tags$span(
            class = "text-muted",
            "Choose your parameters, then run the comparison."
          )
        ),
        reactable::reactableOutput(ns("runtime_output"))
      )
    ),
    div(
      class = "card-group",
      bslib::card(
        bslib::card_header("{dtlg}"),
        reactable::reactableOutput(ns("dtlg_output"))
      ),
      bslib::card(
        bslib::card_header("Comparison"),
        uiOutput(ns("comparison_output"))
      )
    )
  )
}

#' @param dtlg_fn Function body of the function to use from the dtlg pcakage
#' @param other_fn Function body of the function to use as a comparison output
#' @param n_iter (Reactive) Number of iterations to run the comparison over
#' @param datasets List of datasets to use as part of the comparison. Must be named
#' in the same way that they are arguments in `dtlg_fn` and `other_fn`
#' @param filter_params A named list of arguments in `dtlg_fn` that can be updated
#' in the UI for different tables
#' @param other_params A named list of additional arguments passed to `dtlg_fn`
#'
#' @rdname tlg_mod
tlgModServer <- function(id, dtlg_fn, other_fn, n_iter, datasets, filter_params, other_params) {
  moduleServer(id, function(input, output, session) {
    #### Parameters ####
    observe({
      req(length(filter_params) > 0L)

      purrr::iwalk(filter_params, \(param_info, id) {
        adam <- datasets()[[param_info$dataset]]
        if (param_info$selection == "grep") {
          choices <- grepv(param_info$grep, names(adam))
        } else {
          choices <- adam |>
            purrr::keep(inherits, what = param_info$class) |>
            names()
        }

        updateSelectizeInput(
          session = session,
          inputId = id,
          choices = choices,
          selected = param_info$default %||% choices[1L]
        )
      })
    })

    selected_params <- reactive({
      if (length(filter_params) == 0L) return(NULL)

      filter_params |>
        names() |>
        purrr::set_names() |>
        purrr::map(\(id) input[[id]])
    })

    #### Comparison ####
    run_info <- reactive({
      req(length(filter_params) == 0L || all(lengths(selected_params()) > 0L))

      bench::mark(
        iterations = n_iter(),
        check = FALSE,
        memory = FALSE,
        dtlg = do.call(
          dtlg_fn,
          c(
            datasets(),
            other_params,
            selected_params()
          )
        ),
        comparison = do.call(
          other_fn,
          c(
            datasets(),
            other_params,
            selected_params()
          )
        )
      )
    }) |>
      bindEvent(input$run)

    output$runtime_output <- reactable::renderReactable({
      req(run_info())

      tbl <- dplyr::mutate(
        run_info(),
        expression = as.character(.data$expression),
        min = format(.data$min),
        median = format(.data$median),
        total_time = format(.data$total_time)
      )

      reactable::reactable(
        tbl,
        columns = list(
          expression = reactable::colDef(name = "Package"),
          min = reactable::colDef(name = "Minimum Execution Time"),
          median = reactable::colDef(name = "Median Execution Time"),
          "itr/sec" = reactable::colDef(
            name = "Executions per Second",
            cell = function(x) sprintf("%.2f", x)
          ),
          mem_alloc = reactable::colDef(show = FALSE),
          "gc/sec" = reactable::colDef(
            name = "Garbage Collections per Second",
            cell = function(x) sprintf("%.2f", x)
          ),
          n_itr = reactable::colDef(name = "Number of Iterations"),
          n_gc = reactable::colDef(name = "Number of Garbage Collections"),
          total_time = reactable::colDef(name = "Total Execution Time"),
          result = reactable::colDef(show = FALSE),
          memory = reactable::colDef(show = FALSE),
          time = reactable::colDef(show = FALSE),
          gc = reactable::colDef(show = FALSE)
        )
      )
    })

    #### dtlg ####
    dtlg_info <- reactive({
      req(length(filter_params) == 0L || all(lengths(selected_params()) > 0L))

      do.call(
        dtlg_fn,
        c(
          datasets(),
          other_params,
          selected_params()
        )
      )
    }) |>
      bindEvent(input$run)

    output$dtlg_output <- reactable::renderReactable(reactable::reactable(dtlg_info()))

    #### Comparison ####
    comparison_info <- reactive({
      req(length(filter_params) == 0L || all(lengths(selected_params()) > 0L))

      do.call(
        other_fn,
        c(
          datasets(),
          other_params,
          selected_params()
        )
      )
    }) |>
      bindEvent(input$run)

    output$comparison_output <- shiny::renderUI(rtables::as_html(comparison_info()))
  })
}
