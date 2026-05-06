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
#'     \item{category_en}{Character. Broad vehicle category in English:
#'       `"Car"` (classes 1, 6, 7), `"Truck"` (classes 2, 4, 5, 9),
#'       `"Bus"` (class 3), `"Motorcycle"` (class 8).}
#'     \item{category_fi}{Character. Broad vehicle category in Finnish (UTF-8).}
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
    ),
    category_en = c(
      "Car",        # 1  Car / van
      "Truck",      # 2  Truck (no trailer)
      "Bus",        # 3  Bus
      "Truck",      # 4  Truck + semitrailer
      "Truck",      # 5  Truck + full trailer
      "Car",        # 6  Car + trailer
      "Car",        # 7  Car + caravan / motorhome
      "Motorcycle", # 8  Motorcycle / moped
      "Truck"       # 9  High Capacity Truck
    ),
    category_fi = c(
      "Henkil\u00f6auto", # 1
      "Kuorma-auto",      # 2
      "Linja-auto",       # 3
      "Kuorma-auto",      # 4
      "Kuorma-auto",      # 5
      "Henkil\u00f6auto", # 6
      "Henkil\u00f6auto", # 7
      "Moottoripy\u00f6r\u00e4", # 8
      "Kuorma-auto"       # 9
    )
  )
}
