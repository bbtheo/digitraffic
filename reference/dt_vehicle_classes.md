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

## Examples

``` r
dt_vehicle_classes()
#> # A tibble: 9 × 3
#>   vehicle_class label_en                  label_fi                            
#>           <int> <chr>                     <chr>                               
#> 1             1 Car / van                 Henkilö- tai pakettiauto            
#> 2             2 Truck (no trailer)        Kuorma-auto ilman perävaunua        
#> 3             3 Bus                       Linja-auto                          
#> 4             4 Truck + semitrailer       Kuorma-auto ja puoliperävaunu       
#> 5             5 Truck + full trailer      Kuorma-auto ja täysperävaunu        
#> 6             6 Car + trailer             Henkilöauto ja peräkärry            
#> 7             7 Car + caravan / motorhome Henkilöauto ja asuntovaunu tai -auto
#> 8             8 Motorcycle / moped        Moottoripyörä tai mopo              
#> 9             9 High Capacity Truck       HCT-ajoneuvoyhdistelmä              
```
