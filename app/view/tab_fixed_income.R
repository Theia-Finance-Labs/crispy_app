# Load required packages
box::use(
  shiny[moduleServer, NS, div, h1, tags, reactiveVal, observeEvent, observe, eventReactive, HTML, updateTextInput],
  shiny.semantic[semanticPage, button, segment],
  semantic.dashboard[dashboardPage, dashboardBody, dashboardSidebar, dashboardHeader, box],
  DT[DTOutput, renderDT, datatable, JS, dataTableProxy, replaceData],
)

box::use(
  app/view/modules/portfolio_analysis,
  app/view/modules/plots_loans
)



####### UI

ui <- function(id, max_trisk_granularity, available_vars) {
  ns <- NS(id)

  shiny::div(
    class = "pusher container", style = "min-height: 100vh;",
    shiny::div(
      class = "ui segment", style = "min-height: 100vh;",
      shiny::tags$div(
        class = "ui stackable grid",
        portfolio_analysis$ui(ns("portfolio_analysis"), portfolio_class = "fixed_income"),
        plots_loans$ui(ns("plots_loans"))
      )
    )
  )
}

####### Server

server <- function(id, perimeter, backend_trisk_run_folder, possible_trisk_combinations, max_trisk_granularity, portfolio_uploaded_r) {
  moduleServer(id, function(input, output, session) {
    # SELECT PARAMETERS =========================
    trisk_granularity_r <- perimeter$trisk_granularity_r
    trisk_run_params_r <- perimeter$trisk_run_params_r
    crispy_data_r <- perimeter$crispy_data_r
    trajectories_data_r <- perimeter$trajectories_data_r

    # INIT PORTFOLIO ===============

    display_columns_loans <- c(
      names(max_trisk_granularity),
      "term",
      "exposure_value_usd",
      "loss_given_default",
      "pd_shock",
      "expected_loss_shock"
    )
    editable_columns_names_loans <- c("exposure_value_usd", "loss_given_default")
    colored_columns_names_loans <- c()

    analysis_data_r <- portfolio_analysis$server(
      "portfolio_analysis",
      portfolio_class = "fixed_income",
      portfolio_uploaded_r = portfolio_uploaded_r,
      crispy_data_r = crispy_data_r,
      trisk_granularity_r = trisk_granularity_r,
      max_trisk_granularity = max_trisk_granularity,
      display_columns = display_columns_loans,
      editable_columns_names = editable_columns_names_loans,
      colored_columns_names = colored_columns_names_loans,
      editable_rows = TRUE, # Allow adding and deleting rows, and gives access to the company granularity
      possible_trisk_combinations = possible_trisk_combinations
    )


    plots_loans$server("plots_loans",
      analysis_data_r = analysis_data_r,
      crispy_data_r = crispy_data_r,
      max_trisk_granularity = max_trisk_granularity
    )
  })
}
