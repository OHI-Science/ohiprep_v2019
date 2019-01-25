This year we are moving the code to calculate the livelihoods and economies subgoals out of ohi-global/eez/conf/functions.R

Instead, we will just load in the status and trend data.  All code and files used to calculate these subgoals will be preserved in 'ohi-global/eez/archive'.

The status and trend data were extracted from 'eez/scores.csv' (from the 2017/2018 assessment) using the following script:'ohi-global/eez/archive/preparing_eco_liv_data.R',  and saved to: 'ohiprep_v2018/globalprep/le/v2018/output'.