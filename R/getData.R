#### Script to get data from public google sheets link

library(tidyverse)
library(googlesheets4)
library(mapboxapi)
# Comment out for local push
#token = Sys.getenv("MAPBOX")

googlesheets4::gs4_deauth()

sheet_url = 'https://docs.google.com/spreadsheets/d/1JKI9l_WxcO2nl7wrJ5wRvAy_PcezXPXalZ8s6Ae5CQY/edit?usp=sharing'

collapse_locations = function(...) {
  locations = c(...)
  locations = stringr::str_squish(as.character(locations))
  locations = locations[!is.na(locations) & locations != ""]

  if (length(locations) == 0) {
    return(NA_character_)
  }

  paste(locations, collapse = "; ")
}

normalise_geocode_location = function(location) {
  location = stringr::str_squish(as.character(location))

  dplyr::case_when(
    stringr::str_detect(location, stringr::regex("^Hong Kong\\s+SAR,\\s*China$", ignore_case = TRUE)) ~ "Hong Kong, China",
    TRUE ~ location
  )
}

google_data = googlesheets4::read_sheet(sheet_url) %>%
  rowwise() %>%
  mutate(
    LocationDisplay = collapse_locations(
      LocationFull,
      LocationFull2,
      `Other cities/countries of researchers:`
    ),
    LocationGeocode = normalise_geocode_location(LocationFull),
    geo = list(
      if (is.na(LocationGeocode) || LocationGeocode == "") {
        c(NA_real_, NA_real_)
      } else {
        mb_geocode(LocationGeocode, limit = 1, access_token = token)
      }
    ),
    lon = unname(unlist(geo))[1],
    lat = unname(unlist(geo))[2]
    ) %>%
  select(Timestamp,
         Email = "Email address",
         Title = "Project name",
         BriefSummary = "Aim of project:",
         ResponsiblePartyInvestigators = "Research team members",
         LocationCity = "City of researchers (site 1)",
         LocationRegion = "State/region/province of researchers (site 1)",
         LocationCountry = "Country of researchers (site 1)",
         LocationFull,
         LocationCity2 = "City of researchers (site 2)",
         LocationRegion2 = "State/region/province of researchers (site 2)",
         LocationCountry2 = "Country of researchers (site 2)",
         LocationFull2,
         OtherLocations = "Other cities/countries of researchers:",
         LocationDisplay,
         Lat = lat,
         Lon = lon,
         Funded = "Is the project funded?",
         FundingSource = "If yes, how is the project funded?",
         PhaseOfResearch = "Phase of research",
         OngoingOrComplete = "This project is:",
         PlanToCommericalise = "Are there plans to commercialise the technology?",
         Category = "The technology in this project is categorised as:",
         Comments = "Other comments:",
         Publications = "Publications or resources:"
  )

write_rds(google_data, file = "google_data.rds")
