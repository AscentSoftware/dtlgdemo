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
    datasets = reactive({
      list(
        adsl = adsl(),
        adae = adae() |>
          purrr::map_if(
            \(x) is.factor(x) && setequal(levels(x), c("N", "Y")),
            \(x) structure(x == "Y", label = attr(x, "label"))
          ) |>
          dplyr::bind_cols()
      )
    }),
    other_params = list(
      patient = "USUBJID"
    )
  )

  tlgModServer(
    "aet02",
    dtlg_fn = dtlg::AET02_table,
    other_fn = dtlg::tern_AET02_table,
    n_iter = filters$n_iter,
    filter_params = list(
      treat = list(
        dataset = "adsl",
        type = "col_names",
        selection = "grep",
        grep = "ARM|TRT"
      ),
      target = list(
        dataset = "adae",
        type = "col_names",
        selection = "class",
        class = "factor",
        default = "AEDECOD"
      ),
      rows_by = list(
        dataset = "adae",
        type = "col_names",
        selection = "class",
        class = "factor",
        default = "AEBODSYS"
      )
    ),
    datasets = reactive({
      list(
        adsl = adsl(),
        adae = adae()
      )
    }),
    other_params = list(
      patient = "USUBJID"
    )
  )
}
