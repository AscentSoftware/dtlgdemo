#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'
#' @import data.table
#' @import shiny
#'
#' @noRd
app_ui <- function(request) {
  tagList(
    add_external_resources(),
    bslib::page_fluid(
      title = "dtlg Explorer",
      class = "min-vh-100 bg-body p-4 p-lg-5",
      div(
        class = "mb-3 mb-lg-3",
        h1("dtlg Explorer"),
        tags$p(
          class = "text-muted",
          "Interactive demonstration of modular Shiny application design patterns."
        )
      ),
      filterModUI("filters"),
      bslib::navset_pill(
        bslib::nav_panel(
          "AET01",
          tlgModUI(
            "aet01",
            params = list(
              treat_var = list(label = "Treatment Variable", multiple = FALSE),
              aesi_vars = list(label = "Binary AESI Flags", multiple = TRUE)
            )
          )
        ),
        bslib::nav_panel(
          "AET02",
          tlgModUI(
            "aet02",
            params = list(
              treat = list(label = "Treatment Variable", multiple = FALSE),
              target = list(label = "Preferred Term Variable", multiple = FALSE),
              rows_by = list(label = "Higher-Level Nesting Term", multiple = FALSE)
            )
          )
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @noRd
add_external_resources <- function() {
  addResourcePath("www", app_sys("app/www"))

  tags$head(
    golem::bundle_resources(
      path = app_sys("app/www"),
      app_title = "dtlg Example"
    ),
    tags$link(rel = "shortcut icon", href = "www/favicon.ico")
  )
}
