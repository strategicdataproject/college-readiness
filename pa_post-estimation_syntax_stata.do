	// This do file is a follow-on to the faketucky_college_readiness_20170911 do 
	// file which gives examples of Stata commands useful for data exploration and predictive 
	// analytics, using the training_2009 dataset. This do file provides an example of Stata 
	// post-estimation prediction commands developed on the training_2009 dataset and then 
	// used on out of sample data, in this case the validation_2010 dataset.
	
	// Set up
	set more off
	set type double
	capture log close
	
	// Define file paths. Replace "mmn919" with your Windows username.
	global username "Meg Nipson"  
	
	// Edit the next line if you've stored the data somewhere other than your Windows desktop.
	global basepath "C:/Users/$username/Desktop" 
	
	// Change Stata's working directory to the location where the data is stored.
	cd "$basepath"
	
	// Open a log file. 
	log using "$basepath/Faketucky_collegereadiness_postest.log", replace 
	
	// Load the training data. 
	use "$basepath/training_2009.dta", clear
	
	// Replicate the data cleaning from the previous tutorial
	replace pct_absent_11 = . if pct_absent_11 > 100 
	replace scale_score_8_math = . if scale_score_8_math > 80
	
	// Develop the model using the training data.
	logit ontime_grad pct_absent_11 scale_score_8_math
	
	// Store the model. Stata will always use the most recent model in memory 
	// to make predictions, even if you change datasets, but this gives you the 
	// option of storing multiple models and restoring them when you need them.
	estimates store main_model
	
	// Develop another model for records with missing test scores data. The 
	// missing function is another way of identifying records with missing values.
	logit ontime_grad pct_absent_11 if missing(scale_score_8_math)
	
	// Store that model too.
	estimates store testmiss_model
	
	// Load the out of sample validation dataset.
	use "$basepath/validation_2010.dta", clear
	
	// Restore the first model and do a prediction on the 2010 dataset.
	estimates restore main_model
	predict model1
	
	// Check to see how many missing predictions we have for the validation dataset.
	count if missing(model1)
	
	// Check to see which predictors are missing for those records. As in
	// 2009, in 2010 there are only a handful of records missing absence data.
	codebook pct_absent_11 scale_score_8_math if missing(model1)
	
	// Make predictions for students missing only test score data using the
	// missing data model.
	estimates restore testmiss_model
	predict model2 if missing(model1)
	
	// Just to make sure our counts line up, verify that we now have predictions
	// available for all but 96 records. 
	count if model1 == . & model2 == .
	
	// Now we'll define our graduation prediction indicator according to the 
	// algorithm (method) we developed using the training data. 
	// First we'll use the probability cutoffs we chose for the main and missing models.
	gen grad_indicator = 0 if model1 < .75 & model1 ~= .
	replace grad_indicator = 1 if model1 >= .75 & model1 ~= .
	replace grad_indicator = 0 if model2 < .75 & model2 ~= . & model1 == .
	replace grad_indicator = 1 if model2 >= .75 & model2 ~= . & model1 == .
	
	// Next, according to our algorithm, we need to set the remaining missing
	// predictions to 0 (predicting non-graduation for these students).
	replace grad_indicator = 0 if missing(grad_indicator)
	
	// Check on the predictions--no missings!
	tab grad_indicator, mi
	
	// You don't have the outcome data for 2010, but Kaggle does and so do I, so I'm 
	// going to go ahead and check the AUC. (Pretend I'm Kaggle. You won't be able to 
	// run this code.) The merge command is how Stata combines multiple files using
	// key variables.
	merge 1:1 sid using "$basepath/hsgrad_key_2010.dta"
	keep if _merge == 3
	tab ontime_grad grad_indicator, row mi
	roctab ontime_grad grad_indicator, graph
	
	// The AUC is 0.69. Can we do better? Time to go back to the training dataset and
	// try again!

	
	
	
