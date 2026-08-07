#' Filters Module
#'
#' @description
#' Common filters that will be used across the various tabs
#'
#' @param id An ID string that identifies the namespace of the UI and server components.
#'
#' @rdname filter_mod
filterModUI <- function(id) {
  ns <- NS(id)

  bslib::card(
    bslib::card_header("Parameters"),
    bslib::card_body(
      div(
        class = "row g-4",
        numericInput(
          ns("n"),
          "Sample size",
          value = 300,
          min = 20,
          max = 100000
        ),
        numericInput(
          ns("n_iter"),
          "Number of benchmark iterations",
          value = 5,
          min = 1,
          max = 1000
        ),
        numericInput(
          ns("seed"),
          "Select seed (0 = no seed)",
          value = 0,
          min = 0,
          max = 1000000
        )
      )
    )
  )
}

#' @rdname filter_mod
filterModServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    list(
      N = reactive(input$n),
      n_iter = reactive(input$n_iter),
      seed = reactive(if (input$seed > 0L) input$seed else NULL)
    )
  })
}
