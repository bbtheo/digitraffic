# Vehicle classification codes used in LAM raw data

Returns the lookup table mapping integer vehicle class codes (1-9) to
their English and Finnish labels, as used in the `vehicle_class` column
of
[`dt_history_raw()`](https://bbtheo.github.io/digitraffic/reference/dt_history_raw.md).

## Usage

``` r
dt_vehicle_classes()
```

## Value

A tibble with columns:

- vehicle_class:

  Integer. Class code (1-9).

- label_en:

  Character. English label.

- label_fi:

  Character. Finnish label (UTF-8).

- category_en:

  Character. Broad vehicle category in English: `"Car"` (classes 1, 6,
  7), `"Truck"` (classes 2, 4, 5, 9), `"Bus"` (class 3), `"Motorcycle"`
  (class 8).

- category_fi:

  Character. Broad vehicle category in Finnish (UTF-8).

## Examples

``` r
dt_vehicle_classes()
#> # A tibble: 9 × 5
#>   vehicle_class label_en                  label_fi       category_en category_fi
#>           <int> <chr>                     <chr>          <chr>       <chr>      
#> 1             1 Car / van                 Henkilö- tai … Car         Henkilöauto
#> 2             2 Truck (no trailer)        Kuorma-auto i… Truck       Kuorma-auto
#> 3             3 Bus                       Linja-auto     Bus         Linja-auto 
#> 4             4 Truck + semitrailer       Kuorma-auto j… Truck       Kuorma-auto
#> 5             5 Truck + full trailer      Kuorma-auto j… Truck       Kuorma-auto
#> 6             6 Car + trailer             Henkilöauto j… Car         Henkilöauto
#> 7             7 Car + caravan / motorhome Henkilöauto j… Car         Henkilöauto
#> 8             8 Motorcycle / moped        Moottoripyörä… Motorcycle  Moottoripy…
#> 9             9 High Capacity Truck       HCT-ajoneuvoy… Truck       Kuorma-auto
```
