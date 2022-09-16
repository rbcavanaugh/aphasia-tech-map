#### Script to get data from public google sheets link

library(tidyverse)
library(googlesheets4)
library(mapboxapi)
# Comment out for local push
#token = Sys.getenv("MAPBOX")
token = get_mb_access_token()
mb_access_token(token)

googlesheets4::gs4_deauth()

sheet_url = 'https://docs.google.com/spreadsheets/d/1FOYUEroO90Pn-qHxHVvwIOkNN24hxtRKWE23Zt34P-E/edit?usp=sharing'

google_data = googlesheets4::read_sheet(sheet_url) %>%
  rowwise() %>%
  mutate(
    geo = list(mb_geocode(LocationFull, limit = 3)),
    geo = geo[1]
    ) %>%
  mutate(
  lon = geo[1],
  lat = geo[2]
  ) %>%
  select(Timestamp,
         Email = "Email address",
         Title = "Project name",
         BriefSummary = "Aim of project:",
         ResponsiblePartyInvestigators = "Research team members",
         LocationCountry = "Country where lead researchers are based:",
         LocationCity = "City where lead researchers are based:",
         LocationFull,
         Lat = lat,
         Lon = lon,
         Funded = "Is the project funded?",
         FundingSource = "If yes, how is the project funded?",
         PhaseOfResearch = "Phase of research",
         PlanToCommericalise = "Are there plans to commercialise the technology?",
         Category = "The technology in this project is categorised as:",
         Comments = "Other comments:"
  )

write_rds(google_data, file = "google_data.rds")

