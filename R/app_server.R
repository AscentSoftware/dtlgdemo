#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'
#' @noRd
app_server <- function(input, output, session) {
  filters <- filterModServer("filters")

  #### ADaM Datasets ####
  adsl <- reactive({
    random.cdisc.data::radsl(
      N = filters$N(),
      seed = filters$seed()
    )
  })

  adae <- reactive({
    random.cdisc.data::radae(
      seed = filters$seed(),
      adsl = adsl()
    )
  })

  #### Modules ####
  tlgModServer(
    "aet01",
    dtlg_fn = dtlg::AET01_table,
    other_fn = dtlg::tern_AET01_table,
    n_iter = filters$n_iter,
    filter_params = list(
      treat_var = list(
        dataset = "adsl",
        type = "col_names",
        selection = "grep",
        grep = "ARM|TRT"
      ),
      aesi_vars = list(
        dataset = "adae",
        type = "col_names",
        selection = "class",
        class = "logical"
      )
    ),
    datasets = list(
      adsl = adsl(),
      adae = adae() |>
        purrr::map_if(
          \(x) is.factor(x) && setequal(levels(x), c("N", "Y")),
          \(x) structure(x == "Y", label = attr(x, "label"))
        ) |>
        dplyr::bind_cols()
    ),
    other_params = list(
      patient_var = "USUBJID"
    )
  )
}
