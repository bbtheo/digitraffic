#' Vehicle classification codes used in LAM raw data
#'
#' Returns the lookup table mapping integer vehicle class codes (1-9) to
#' their English and Finnish labels, as used in the `vehicle_class` column
#' of [dt_history_raw()].
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{vehicle_class}{Integer. Class code (1-9).}
#'     \item{label_en}{Character. English label.}
#'     \item{label_fi}{Character. Finnish label (UTF-8).}
#'   }
#'
#' @export
#' @examples
#' dt_vehicle_classes()
dt_vehicle_classes <- function() {
  tibble::tibble(
    vehicle_class = 1L:9L,
    label_en = c(
      "Car / van",
      "Truck (no trailer)",
      "Bus",
      "Truck + semitrailer",
      "Truck + full trailer",
      "Car + trailer",
      "Car + caravan / motorhome",
      "Motorcycle / moped",
      "High Capacity Truck"
    ),
    label_fi = c(
      "Henkil\u00f6- tai pakettiauto",
      "Kuorma-auto ilman per\u00e4vaunua",
      "Linja-auto",
      "Kuorma-auto ja puoliper\u00e4vaunu",
      "Kuorma-auto ja t\u00e4ysper\u00e4vaunu",
      "Henkil\u00f6auto ja per\u00e4k\u00e4rry",
      "Henkil\u00f6auto ja asuntovaunu tai -auto",
      "Moottoripy\u00f6r\u00e4 tai mopo",
      "HCT-ajoneuvoyhdistelm\u00e4"
    )
  )
}
