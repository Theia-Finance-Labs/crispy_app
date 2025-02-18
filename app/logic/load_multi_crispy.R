

#' Title
#'
#' @param multi_crispy_data multi_crispy_data
#' @param granularity granularity
#' @param param_cols param_cols
#' @param filter_outliers filter_outliers
#'
#'
#' @export
main_load_multi_crispy_data <-
  function(multi_crispy_data,
           granularity, param_cols = c(
             "term", "run_id", "scenario_geography", "baseline_scenario",
             "target_scenario", "risk_free_rate", "discount_rate", "div_netprofit_prop_coef",
             "carbon_price_model", "market_passthrough",
             "growth_rate", "shock_year"
           ),
           filter_outliers = FALSE) {
    group_cols <- unique(c(granularity, param_cols))

    multi_crispy_data <- multi_crispy_data |>
      aggregate_crispy_facts(group_cols = group_cols)

    # Conditionally apply remove_outliers_per_group based on the filter_outliers parameter
    multi_crispy_data <- if (filter_outliers) {
      multi_crispy_data |>
        remove_outliers_per_group(
          group_cols = group_cols,
          column_filtered = "crispy_perc_value_change"
        )
    } else {
      multi_crispy_data
    }
    return(multi_crispy_data)
  }





#' Title
#'
#' TODO FIND CLOSEST COMPANY IF group_cols=NULL
#'
#' @param multi_crispy multi_crispy
#' @param group_cols group_cols
#'
aggregate_crispy_facts <- function(multi_crispy, group_cols) {
  multi_crispy <- multi_crispy |>
    dplyr::group_by_at(group_cols) |>
    dplyr::summarise(
      net_present_value_baseline = sum(net_present_value_baseline, na.rm = T),
      net_present_value_shock = sum(net_present_value_shock, na.rm = T),
      pd_baseline = stats::median(pd_baseline, na.rm = T),
      pd_shock = stats::median(pd_shock, na.rm = T),
      .groups = "drop"
    )
  return(multi_crispy)
}



#' Title
#'
#' @description
#' Function to remove outliers based on z-score
#'
#'
#' @param df df
#' @param column_filtered column name
#' @param index_columns index_columns
#' @param min_obs min_obs
#' @param max_zscore max_zscore
#'
remove_outliers <- function(df, column_filtered, index_columns, max_zscore = 3, min_obs = 30) {
  if (nrow(df) >= min_obs) {
    # Compute the mean and standard deviation of the column
    mean_value <- mean(df[[column_filtered]], na.rm = TRUE)
    sd_value <- sd(df[[column_filtered]], na.rm = TRUE)

    # Calculate the Z-scores for the column
    df$z_scores <- (df[[column_filtered]] - mean_value) / sd_value

    outlier_indexes <- df |>
      dplyr::filter(abs(.data$z_scores) > max_zscore) |>
      dplyr::distinct_at(index_columns)

    # Filter out rows where the absolute z-score is greater than 3
    df <- df |>
      dplyr::anti_join(outlier_indexes, by = index_columns) |>
      dplyr::select(-c(.data$z_scores))
  }
  return(df)
}

#' Title
#'
#' @param multi_crispy multi_crispy
#' @param group_cols group_cols
#' @param column_filtered column_filtered
#' @param index_column index_column
#'
remove_outliers_per_group <- function(multi_crispy, group_cols, column_filtered) {
  multi_crispy <- multi_crispy |>
    dplyr::group_by_at(group_cols) |>
    dplyr::group_modify(
      ~ remove_outliers(
        df = .x,
        column_filtered = column_filtered,
        index_columns = group_cols
      ) |>
        # must remove group columns because of .keep
        dplyr::select(-dplyr::all_of(group_cols)),
      .keep = TRUE
    ) |>
    dplyr::ungroup()
  return(multi_crispy)
}
