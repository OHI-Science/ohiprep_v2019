## Ocean Health Index: Natural products (NP)


See full data prep details [here](https://rawgit.com/OHI-Science/ohiprep_v2018/master/globalprep/np/v2018/np_dataprep.html).

If using these data, please see our [citation policy](http://ohi-science.org/citation-policy/).

[alternatively, if you want a specific citation for this resource, you can add that here....]


### Layers Created

* Relative harvest value (np_harvest_product_weight)
* Natural product harvest (np_harvest_tonnes)
* Relative harvest tonnes (np_harvest_tonnes_relative)


### Files
* np_dataprep.Rmd - script for preparing the Natural Products data
* Gap_fill_product.R - summarizing the gap-fill commodity data to get an estimate of the proportion of data that was gap-filled for each; was not used in 2018 Global Assessment


### Additional information
FAO Commodities data are used to determine the Natural Products goal. FAO metadata found [here](http://ref.data.fao.org/dataset?entryId=aea93578-9b01-4448-9305-917348ca00b2&tab=metadata).

The FAO fisheries and aquaculture web page (http://www.fao.org/fishery/topic/166235/en) provides instructions on downloading and installing their FishStatJ software.  Once you've done that, then:

* From the [same web page](http://www.fao.org/fishery/topic/166235/en), under **FishStatJ available workspaces,** download the Global datasets workspace to your computer.
* Start **FishStatJ**.
* Invoke the **Tools -> Import Workspace** command.
* In the Import Workspace dialog, change the current directory to where you have downloaded the workspace(s) and select it.
* Follow the directions to import the workspace (press **Next** a couple of times then **Install Workspace**)
    * It may take a while to import the workspace. Go make a sandwich, get some coffee, drink a beer, learn a new hobby.
* Open the two data sets: *Global commodities production and trade - Quantity* and *- Value*.
    * No need to filter; the `data_prep.R` script does that.
* For each data set, select all (`ctrl-A` or `command-A`), then **Edit -> Save selection (.csv file)...**  Save as these filenames: 
        `FAO_raw_commodities_quant_[start-year]_[end-year].csv` and
        `FAO_raw_commodities_value_[start-year]_[end-year].csv`
    * **Note:** in prior years, people have reported that this may not capture all the rows in the .csv file, so make sure to double-check.
* Put the resulting files in an appropriate folder and have fun!
