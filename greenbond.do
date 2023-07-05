clear all 
set more off

* CHANGE THE FILEPATH
cd "/Users/viviannguyen/Downloads/sugardaddydata"

* Loop to merge all the green bonds data
import delimited "bonds2015.csv", varnames(1) rowrange(4) case(lower) clear

rename climatebondsinitiativeregion country
rename country2015green2015amountissued bondsval2015
label variable country "country"
label variable bondsval2015 "bonds value in USD"
save bonds2015, replace
save bonds_mass, replace


local years 2016 2017 2018 2019 2020 2021

foreach year in `years' {

  import delimited "bonds`year'.csv", varnames(1) rowrange(4) case(lower) clear

  rename climatebondsinitiativeregion country
  rename country`year'green`year'amountissued bondsval`year'
  label variable country "country"
  label variable bondsval`year' "bonds value in USD"
  save bonds`year', replace

  use bonds_mass
  merge 1:1 country using bonds`year'
  drop _merge
  save bonds_mass, replace

}

* Drop countries with missing data of green bonds
drop if missing(bondsval2016) | missing(bondsval2017) | missing(bondsval2018) | missing(bondsval2019) |  missing(bondsval2020) | missing(bondsval2021)
drop bondsval2015
destring bondsval2016-bondsval2021, replace
save bonds_mass, replace


* Summarize the data
encode country, generate(country_num)
egen mean_val = rowmean(bondsval2016-bondsval2021)
egen max_val = rowmax(bondsval2016-bondsval2021)
egen min_val = rowmin(bondsval2016-bondsval2021)
egen median_val = rowmedian(bondsval2016-bondsval2021)

list country min_val max_val mean_val median_val 
drop min_val max_val mean_val median_val


* Import and clean data of co2
import delimited "/Users/viviannguyen/Downloads/sugardaddydata/emissions.csv", varnames(1) clear
drop substance edgarcountrycode
drop v4-v29 
rename v30 co2_2016
rename v31 co2_2017
rename v32 co2_2018
rename v33 co2_2019
rename v34 co2_2020
rename v35 co2_2021
replace country = upper(country)
replace country = "ITALY" if country == "ITALY, SAN MARINO AND THE HOLY SEE"
replace country = "SPAIN" if country == "SPAIN AND ANDORRA"
replace country = "SWITZERLAND" if country == "SWITZERLAND AND LIECHTENSTEIN"
replace country = "USA" if country == "UNITED STATES"

* Keep only countries that exist in bonds_mass
merge 1:1 country using bonds_mass, keep(match)
drop _merge
save bonds_co2, replace

* Run regression on bondsval and co2 emission of each year, without accounting for GDP
local years 2016 2017 2018 2019 2020 2021

foreach year in `years' {
	regress bondsval`year' co2_`year'
    }
	
/*  Statistical significance == p-value of 0.05 or lower

In some years (e.g., 2016, 2017, and 2018), there is a statistically significant positive relationship between CO2 emissions and the amount invested in green bonds. 

However, in other years (e.g., 2019, 2020, and 2021), the relationship is not statistically significant. */


* Run regression on bondsval and co2 emission of each year, this time accounting for GDP
import excel "/Users/viviannguyen/Downloads/sugardaddydata/gdp.xls", sheet("Data") cellrange(A4:BO270) firstrow clear
rename CountryName country
replace country = upper(country)
rename BI gdp_2016
rename BJ gdp_2017
rename BK gdp_2018
rename BL gdp_2019
rename BM gdp_2020
rename BN gdp_2021
replace country = "USA" if country == "UNITED STATES"

drop E-BH BO CountryCode IndicatorCode IndicatorName
merge 1:1 country using bonds_co2, keep(match)
drop _merge
save bonds_co2_gdp, replace

reshape long bondsval gdp_ co2_, i(country) j(year) string

destring year, replace

encode country, generate(country_num)


twoway scatter bondsval co2_, xtitle("CO2 Emission") ytitle("Bonds value") || lfit bondsval co2_, title("Scatterplot") subtitle("Bonds value vs. CO2") note("1") caption("Source: Climate Bonds Initiative")

twoway scatter bondsval co2_ [w=gdp_], mcolor(%30) xtitle("CO2 Emission") ytitle("Bonds value") || lfit bondsval co2_, title("Bonds value vs. CO2, sized by GDP")

regress bondsval co2_ i.country_num

regress bondsval co2_ i.country_num gdp_

regress bondsval co2_



