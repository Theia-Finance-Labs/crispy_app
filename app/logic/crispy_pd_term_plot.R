#' Visualize PD Values by Term and Business Unit
#'
#' Orchestrates the creation of a plot visualizing the probability of default (PD) values across different terms and sectors or business units. This function facilitates an understanding of how PD values vary by term under baseline and shock scenarios, enabling stakeholders to assess risk exposure.
#'
#' @param crispy_data_agg Aggregated dataset containing PD values for various terms and scenarios across different sectors or business units.
#' @param facet_var The variable by which to facet the plot, typically representing different sectors or business units, defaulting to "ald_sector".
#'
#' @return A ggplot object showing PD values by term, differentiated by scenario, across the specified business units, aiding in strategic risk management.
#' @export
pipeline_crispy_pd_term_plot <- function(crispy_data_agg, facet_var = "ald_sector") {
  data_pd_term <- prepare_for_pd_term_plot(
    crispy_data_agg = crispy_data_agg,
    facet_var = facet_var
  )
  pd_term_plot <- draw_pd_term_plot(
    data_pd_term = data_pd_term,
    facet_var = facet_var
  )

  return(pd_term_plot)
}



#' Prepare Data for PD Term Visualization
#'
#' Prepares the aggregated crispy data for visualization, focusing on PD values by term. It transforms the dataset to a long format suitable for plotting, allowing for a comparative view of PD values under different scenarios.
#'
#' @param crispy_data_agg Dataset containing aggregated PD values across terms and scenarios.
#' @param facet_var Faceting variable representing sectors or business units for detailed comparative analysis.
#'
#' @return A dataframe in long format, ready for plotting PD values by term and scenario.
prepare_for_pd_term_plot <- function(crispy_data_agg, facet_var) {
  data_pd_term <- crispy_data_agg |>
    tidyr::pivot_longer(
      cols = tidyr::starts_with("pd_"),
      names_to = "pd_type",
      values_to = "pd_value",
      names_prefix = "pd_"
    ) |>
    dplyr::mutate(
      pd_type = factor(.data$pd_type, levels = c("baseline", "shock", "difference"))
    ) |>
    dplyr::filter(.data$pd_type != "difference") |>
    dplyr::select_at(c(facet_var, "term", "pd_type", "pd_value")) |>
    dplyr::group_by_at(c(facet_var, "term", "pd_type")) |>
    dplyr::summarise(
      pd_value = stats::median(pd_value)
    )

  return(data_pd_term)
}



#' Generate Plot of PD Values by Term and Scenario
#'
#' Creates a bar plot to visualize the variation of PD values across different terms, under baseline and shock scenarios, segmented by business unit. Utilizes a color gradient to distinguish between PD value magnitudes, facilitating a clear and intuitive comparison of risk profiles.
#'
#' @param data_pd_term Prepared data for plotting, containing term-wise PD values and scenarios.
#' @param facet_var Variable used to segment data into different business units for faceted visualization.
#'
#' @return A ggplot object depicting the comparative analysis of PD values by term and scenario, crucial for evaluating financial risk and strategic planning.
draw_pd_term_plot <- function(data_pd_term, facet_var) {
  red_hex_color <- r2dii.colours::palette_1in1000_plot |>
    dplyr::filter(.data$label == "red") |>
    dplyr::pull(.data$hex)
  green_hex_color <- r2dii.colours::palette_1in1000_plot |>
    dplyr::filter(.data$label == "green") |>
    dplyr::pull(.data$hex)
  grey_hex_color <- r2dii.colours::palette_1in1000_plot |>
    dplyr::filter(.data$label == "grey") |>
    dplyr::pull(.data$hex)


  pd_term_plot <- ggplot2::ggplot(data_pd_term, ggplot2::aes(x = as.factor(term), y = pd_value, fill = pd_value)) +
    ggplot2::geom_bar(stat = "identity", position = ggplot2::position_dodge()) +
    ggplot2::facet_grid(stats::as.formula(paste(paste(facet_var, collapse = "+"), "~ pd_type")), scales = "free_y") +
    ggplot2::scale_fill_gradient2(
      low = green_hex_color,
      high = red_hex_color,
      mid = grey_hex_color,
      midpoint = 0,
      limit = c(min(data_pd_term$pd_value), max(data_pd_term$pd_value)),
      space = "Lab"
    ) +
    r2dii.plot::theme_2dii() +
    ggplot2::scale_y_continuous(labels = scales::percent_format(scale = 100)) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(x = "Term", y = "PD Value", fill = "PD Type", title = "PD Values by Term, Type, and Business Unit")

  return(pd_term_plot)
}
