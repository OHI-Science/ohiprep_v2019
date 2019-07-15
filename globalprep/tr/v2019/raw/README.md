# Travel warnings

Information from U.S State department here: https://travel.state.gov/content/passports/en/alertswarnings.html
Data downloaded: 07/02/2019


Canada's Government - Travel Advice and Advisories here:
(https://travel.gc.ca/travelling/advisories)

Data downloaded:07/02/2019


## A few notes about getting data:

**For future assesmentes** It would be worthwhile to see if data can be "scraped" directly from the website into R. This seems possible given the new format of the state department travel warning data.

Copy and paste the data for each country: from https://travel.state.gov/content/passports/en/alertswarnings.html. Paste into an excel file, convert to .csv and uploade to raw folder

Since v2018, regional warnings are not part of the methods anymore.

See script to identify regions where information can be retrieved from Canada 's Government - Travel Advice and Advisories (See script) and add this region to the csv created witht he above information


# CIA data
Open link:
https://www.cia.gov/library/publications/the-world-factbook/rankorder/2004rank.html

Click on "Download data"

Clear cia_gdp_ppp.txt and past new data (save text file)

Paste data in a new excel file, save it as a csv file and upload to raw folder.
NOTE: the script wrangles the data that is pased all in one column.

**For future assessment**
See if data from test file can be read into a data frame. Or evaluate the option of scraping the data directly from the source. 






