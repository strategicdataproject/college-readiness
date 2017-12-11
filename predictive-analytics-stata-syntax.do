/*
//test edit
This do file provides guidance and Stata syntax examples for the hands-on predictive analytics
session during the Fall 2017 Cohort 8 Strategic Data Project Workshop in Philadelphia.

During the workshop, we'll ask you develop a predictive college-going indicator for the state of 
Faketucky using student data collected through the end of 11th grade. You can take any approach you 
like to do this. Your goal is to make the best predictions possible, and then think about how the 
predictive model would work in the real world, and then recommend an indicator. In the real world, the
indicator you recommend might or might not be the most predictive one--you might argue for one that
is more useful because it gives predictions sooner in a student's academic career, or you might argue
for one that is slightly less accurate but simpler and easier to explain.

Logistic regression is one tool you can use, and we'll demonstrate it here. There are many other 
techniques of increasing complexity. (Many of the best predictive analytics packages are written in the 
R programming language.) But for a binary outcome variable, most data scientists start with logistic 
regressions, and those are very straightforward to do in Stata.

Here are the steps:

1) explore the data, especially college enrollment predictors and outcomes
2) examine the relationship between predictors and outcomes
3) evaluate the predictive power of different variables and select predictors for your model
4) make predictions using logistic regression
5) convert the predicted probabilities into a 0/1 indicator
6) look at the effect of different probability cutoffs on prediction accuracy (develop a "confusion matrix")

When you've been through those steps with your first model, you can submit it to Kaggle 
for scoring, and then iterate through the process again until you are satisfied with the results.
The commands in this do file won't tell you everything you need to do to develop your model, but 
they will give you command syntax that you should be able to adjust and adapt to get the project done.

You can also take an even simpler approach, outlined in the Chicago Consortium on School Research 
CRIS technical guide assigned in the workshop pre-reading. With that "checklist" approach, you 
experiment with different thresholds for your predictor variables, and combine them to directly predict 
0/1 values without using the predict command after running a logistic regression. The CCSR approach has 
the advantage of being easy to explain and implement, but it might not yield the most accurate 
predictions. We won't demonstrate that approach here, but if you want to try it you can draw on the 
syntax examples here and follow the instructions in the CCSR technical guide.

Before you get started, you need to think about variables, time, and datasets. The sooner in a student's 
academic trajectory you can make a prediction, the sooner you can intervene--but the less accurate
your predictions, and hence your intervention targeting, is likely to be. What data, and specifically
which variables, do you have available to make predictions? What outcome are you trying to predict?

It can be helpful to group the data you have available by time categories: pre-high school, early high 
school, late high school, and graduation/post-secondary. One fundamental rule is that you can't use
data from the future to make predictions. If you're planning to use your model to make predictions for 
students at the end of 11th grade, for instance, and if most students take AP classes as seniors, you 
can't use data about AP coursetaking collected during senior year to predict the likelihood of college 
enrollment, even if you have that data available for past groups of students.

In terms of datasets, you can develop your model and then test its accuracy on the dataset you used to
develop the model, but that is bad practice--in the real world, your model is only as good as its 
predictions on different, out of sample datasets. It's good practice to split your data into three parts: 
one part for developing your model, one for repeatedly testing different versions of your model, and a 
third to use for a final out of sample test. 

We're using two cohorts of high-school students for the predictive analytics task--students who were 
ninth graders in 2009 and in 2010. In a production predictive analytics model for a school system, you 
might split data from the most recent cohort for which you have data into two parts for model development 
and testing, and then check the model against outcomes for the next year's cohort when it became 
available. 

For the workshop, though, we're using the online Kaggle competition platform to evaluate model accuracy 
and the data is split somewhat differently. The 2009 data is available to you for model development. 
Kaggle has randomly split the 2010 data, which you'll use to make predictions with your model for 
scoring, into two parts. Kaggle will show scoring results for the first part on a public leaderboard, 
but final scores will depend on how the model performs on the second half of the data.

One last point--in the real world, you'll need to make predictions for every student, even if you're 
missing data for that student which your model needs in order to run. Just making predictions using a 
logistic regression won't be enough. You'll need to use decision rules based on good data exploration 
and your best judgment to predict and fill in outcomes for students where you have insufficient data.

If you're using the do file version of these materials, start by saving a new version of the do file with 
your initials in the title, so you can edit it without worrying about overwriting the original. Then 
work through the do file in Stata by highlighting one or a few command lines at a time, clicking the 
"execute" icon in the toolbar above (or pressing control-D), and then looking at the results in Stata's 
results window. Edit or add commands as you wish. 

This do file uses the 2009 cohort data, which has one observation (row) per student. Each observation 
contains data about demographics, academic performance, school and district enrollment, and high school 
and post-secondary outcomes. It also has information about the characteristics of the colleges that
students attended. To work through the do file, you need to put the training_2009.dta data file 
on your computer desktop or in a working folder of your choice, and then edit the username and 
basepath global commands below to tell Stata where to look for the data. If you have trouble doing this, 
ask for help from other members of your group.
*/

	// Set up
	set more off
	set type double
	capture log close
	
	// Define file paths. Replace "mmn919" with your Windows username.
	global username "mmn919"  
	
	// Edit the next line if you've stored the data somewhere other than your Windows desktop.
	global basepath "C:/Users/$username/Desktop" 
	
	// Change Stata's working directory to the location where the data is stored.
	cd "$basepath"
	
	// Open a log file. This stores a record of the commands and their output in a text file you can review later.
	log using "$basepath/Faketucky_collegereadiness.log", replace 
	
	// Load the data. 
	use "$basepath/training_2009.dta", clear
	
	// Verify that there is exactly one observation per student, and check the total number of observations.
	isid sid
	count
	
	// Verify that the data includes just students who were ninth-graders in 2009
	tab chrt_ninth, mi
	
	// When did these students graduate (if they did)?
	tab chrt_grad, mi
	
	// Now that we have a sense of the time structure of the data, let's look at geography. How many high
	// schools and how many districts are? What are those regional education services coops?
	codebook first_hs_name
	codebook first_dist_name
	tab first_coop_code, mi
	
	// Which districts are part of the coop region you have been assigned to, and how many students do
	// they have? Find out the numeric code for your coop and then replace the ??? below.
	tab first_coop_code, mi nolabel
	tab first_dist_name if first_coop_code == ???
	
	// What are outcome variables, and what are potential predictor variables?
	// What student subgroups are we interested in? Let's start by looking at student subgroups. Here's
	// gender.
	tab male, mi
	
	// Here's a shortcut command to look at one-way tabs of a lot of variables at once.
	tab1 male race_ethnicity frpl_11 sped_11 lep_11 gifted_11, mi
	
	// Let's examine the distribution of student subgroups by geography. For this command, we'll use 
	// Stata's looping syntax, which lets you avoid repetition by applying commands to multiple
	// variables at once. You can't use loops when you are entering commands directly into the command
	// window, but they are very powerful in do files. You can type "help foreach" into the Stata 
	// command window if you want to learn more about how to use loops in Stata.
	foreach var of varlist male race_ethnicity frpl_11 sped_11 lep_11 gifted_11 {
		tab first_coop_code `var', row mi
	}

	// Now, let's look at outcomes. We won't examine them all, but you should. Here's a high 
	// school graduation outcome variable:
	tab ontime_grad, mi
	
	// Wait! What if the data includes students who transferred out of state? That might bias the 
	// graduation rate and make it too low, because those ninth graders might show up as having dropped
	// out.
	tab transferout, mi
	
	// It looks like the data has been cleaned to include only students who did not transfer out.	
	// Let's look at the distribution of this outcome variable by geography and then by subgroup.
	tab first_coop_code ontime_grad, mi row
	foreach var of varlist male race_ethnicity frpl_11 sped_11 lep_11 gifted_11 {
		tab `var' ontime_grad, row mi
	}

	// What are other outcome variables? Can you identify and examine the college enrollment variables?
	// For each outcome that you are interested in, you can copy and paste the commands below, fill in ??? 
	// and then run the commands. If you don't have time to do this right now, skip forward to the next set
	// of commands.
	tab ???, mi
	tab first_coop_code ???, mi row
	foreach var of varlist male race_ethnicity frpl_11 sped_11 lep_11 gifted_11 {
		tab `var' ???, row mi
	}
	
	// It looks like there is a college readiness indicator in the data, but it's zero except for a handful 
	// of students. In fact, the statewide college readiness indicator wasn't implemented until the 2010 
	// cohort. You'll be able to compare your college readiness indicator to the Faketucky college 
	// readiness indicator when you score your model in Kaggle.
	tab collegeready_ever_in_hs, mi

	// Next, identify and examine the performance and behavioral variables that you can use as predictors.
	// These are mostly numerical variables, so you should use the summary, histogram, and table
	// commands to explore them. Here's some syntax for examining 8th grade math scores. You can replicate 
	// and edit it to examine other potential predictors and their distributions by different subgroups.
	summ scale_score_8_math, detail
	hist scale_score_8_math, width(1)
	table first_coop_code, c(mean scale_score_8_math)
	table frpl, c(mean scale_score_8_math)
	
	// Finally, here's some sample code you can use to look at missingness patterns in the data. The "gen"
	// command is used to generate a new variable.
	gen math8_miss = missing(scale_score_8_math)
	tab math8_miss
	foreach var of varlist first_coop_code male race_ethnicity frpl_11 sped_11 lep_11 gifted_11 {
		tab `var' math8_miss, mi row
	}
	
	// Did you see any outlier or impossible values while you were exploring the data? If so, you might
	// want to truncate them or change them to missing. Here's how you can replace a numeric variable 
	// with a missing value if it is larger than a certain number (in this case, 100 percent).
	hist pct_absent_11
	replace pct_absent_11 = . if pct_absent_11 > 100 
	hist pct_absent_11
	
	// Now that you've explored the data, you can start to examine the relationship between predictor and 
	// outcome variables. Here we'll continue to look at the high school graduation outcome, and we'll 
	// restrict the predictors to just two: 8th grade math scores and percent of enrolled days absent 
	// through 11th grade. For your college-going model, you can of course use more and different predictor 
	// variables. First, check the correlation between outcome and predictors.
	corr ontime_grad scale_score_8_math pct_absent_11
	
	// A correlation is just one number, and it would be nice to have a better idea of the overall 
	// relationship between outcomes and predictors. But you can't make a meaningful scatterplot when
	// the independent, or y value, is a binary outcome variable (try it!). Here's some nifty code to make 
	// plots that give you a clearer look at the relationship between our predictors and outcomes.
	// The idea behind this code is to show the mean of the outcome variable for each value of the 
	// predictor, or for categories of the predictor variable if it has too many values. This uses 
	// the egen command (which stands for "extensions to generate"). Type "help egen" in the command window 
	// if you want more information. First, define categories (in this case, group by percentages) of the 
	// percent absent variable, and then truncate the variable so that low-frequency values are grouped 
	// together.
	egen pct_absent_cat = cut(pct_absent_11), at(0(1)100)
	tab pct_absent_cat
	replace pct_absent_cat = 30 if pct_absent_cat >= 30
	
	// Next, define a variable which is the average ontime graduation rate for each absence category, and 
	// then make a scatter plot of average graduation rates by absence percent.
	egen abs_ontime_grad = mean(ontime_grad), by(pct_absent_cat)
	scatter abs_ontime_grad pct_absent_cat
	
	// You can do the same thing for 8th grade test scores, without having to group them with the egen cut
	// command.
	egen math_8_ontime_grad = mean(ontime_grad), by(scale_score_8_math)
	scatter math_8_ontime_grad scale_score_8_math
	
	// You can see there are some 8th grade math score outliers--if you haven't already, you might want to
	// set them to zero.
	replace scale_score_8_math = . if scale_score_8_math > 80
	scatter math_8_ontime_grad scale_score_8_math
	
	// Looking at the plot, if you think the relationship between eigth grade math scores and ontime 
	// graduation is more of a curve than a line, you can define variables for the square and cube of the 
	// math scores so that Stata will be able to fit a polynomial equation to the data instead of a 
	// straight line when you build your model.
	gen math_8_squared = scale_score_8_math^2
	gen math_8_cubed = scale_score_8_math^3
	
	// Now we're ready to call on the logit command to examine the relationship between our binary outcome
	// variable and our predictor variables. When you run a logistic regression with the logit command, 
	// Stata calculates the parameters of an equation that fits the relationship between the predictor 
	// variables and the outcome. A regression model typically won't be able to explain all of the 
	// variation in an outcome variable--any variation that is left over is treated as unexplained noise in 
	// the data, or error, even if there are additional variables not in the model which could explain more 
	// of the variation. Once you've run a logit regression, you can have Stata generate a variable with 
	// new, predicted outcomes for each observation in your data with the predict command. The predictions 
	// are calculated using the model equation and ignore the unexplained noise in the data. For logit 
	// regressions, the predicted outcomes take the form of a probability number between 0 and 1. To start
	// with, let's do a regession of ontime graduation on eighth grade math scores.
	logit ontime_grad scale_score_8_math
	
	// Even before you use the predict command, you can use the logit output to learn something about the 
	// relationship between the predictor and the outcome variable. The Pseudo R2 (read R-squared) is a 
	// proxy for the share of variation in the outcome variable that is explained by the predictor.
	// Statisticians don't like it when you take the pseudo R2 too seriously, but it can be useful in
	// predictive exercises to quickly get a sense of the explanatory power of variables in a logit model.
	// Does adding polynomial terms increase the pseudo R2? Not by very much. Any time you add predictors
	// to a model, the R2 will increase, even if the variables are fairly meaningless, so it's best to 
	// focus on including predictors that add meaningful explanatory power.
	logit ontime_grad scale_score_8_math math_8_squared math_8_cubed
	
	// Now take a look at the R2 for the absence variable. Absence rates seem to have more explanatory 
	// power than 8th grade test scores.
	logit ontime_grad pct_absent_11
	
	// Let's combine our two predictors. This model has more explanatory power than the single-variable
	// models.
	logit ontime_grad pct_absent_11 scale_score_8_math
	
	// Now, let's use the predict command. Stata applies the predict command to the most recent regression
	// model.
	predict model1
	
	// This generates a new variable with the probability of ontime high school graduation, according to 
	// the model. But if you look at the number of observations with predictions, you'll see that it is
	// smaller than the total number of students. This is because Stata doesn't use observations that
	// have missing data for any of the variables in the model.
	summ model1, detail
	count
	
	// Let's convert this probability to a 0/1 indicator for whether or not a student is likely to 
	// graduate ontime. If the probability in the model is equal to or greater than .5, or 50%, we'll say 
	// the student is likely to graduate. We can use this syntax to make sure that we are not accidentally
	// defining the indicator variable in cases where the predicted probability is missing.
	gen grad_indicator = 0 if model1 < .5 & model1 ~= .
	replace grad_indicator = 1 if model1 >= .5 & model1 ~= .
	tab grad_indicator, mi
	
	// Lets evaluate the accuracy of the model by comparing the predictions to the actual graduation 
	// outcomes for the students for whom we have predictions. This type of crosstab is called a "confusion
	// matrix." The observations in the upper right corner, where the indicator and the actual outcome 
	// are both 0, are true negatives. The observations in the lower right corner, where the indicator 
	// and the outcome are both 1, are true positives. The upper right corner contains false positives,
	// and the lower left corner contains false negatives. Overall, if you add up the cell percentages
	// for true positives and true negatives, the model got 84.5 percent of the predictions right.
	tab ontime_grad grad_indicator, cell
	
	// However, almost all of the wrong predictions are false positives--these are students who would not
	// have been flagged as dropout risks even though they didn't graduate ontime. If you want your
	// indicator system to be have fewer false positives, you can change the probability cutoff. This
	// cutoff has a lower share of false positives and a higher share of false negatives, with a somewhat 
	// lower share of correct predictions.
	replace grad_indicator = 0 if model1 < .75 & model1 ~= .
	tab ontime_grad grad_indicator, cell

	// How should we handle the students with missing data? A predictive analytics system is more useful  
	// if it makes an actionable prediction for every student. And, the students missing 8th grade test 
	// scores are likely to be higher mobility students; you can check and see that they have a much lower
	// graduation rate than the students who do have test scores.
	tab ontime_grad if math8_miss == 1
	
	// There are a number of options. One is to run a model with fewer variables for only those students, 
	// and then use that model to fill in the missing indicators.
	logit ontime_grad pct_absent_11 if math8_miss == 1
	predict model2 if math8_miss == 1
	summ model2, detail
	replace grad_indicator = 0 if model2 < .75 & model2 ~= . & model1 == .
	replace grad_indicator = 1 if model2 >= .75 & model2 ~= . & model1 == .
	
	// We now have predictions for all but a very small share of students, and those students are split
	// between graduates and non-graduates. We have to apply a rule or a model to make predictions for 
	// them--we can't use information from the future, except to develop the prediction system. We'll
	// arbitrarily decide to flag them as potential non-graduates, since students with lots of missing
	// data might merit some extra attention.
	tab grad_indicator, mi
	replace grad_indicator = 0 if grad_indicator == .
	
	// Now we have a complete set of predictions from our simple models. How well does the prediction 
	// system work? Can we do better? 
	tab ontime_grad grad_indicator, cell
	
	// A confusion matrix is one way to evaluate the success of a model and evaluate tradeoffs as you are 
	// developing prediction systems, but there are others. The metric used in the Kaggle competition is 
	// AUC, which stands for "area under the curve." You'll learn more about ways to evaluate a prediction 
	// system, including the AUC metric, during Day 2 of the workshop, but here's a sneak peak. First,
	// look at row percentages instead of cell percentages in the confusion matrix.
	tab ontime_grad indicator, row
	
	// Next, use the "roctab" command to plot the true positive rate (sensitivity in the graph) against 
	// the false positive rate (1-specificity in the graph). You can see these percentages match the row 
	// percentages in the last table. The AUC is the "area under ROC curve" in this graph, and it is a 
	// useful single-number summary of predictive accuracy.
	roctab ontime_grad grad_indicator, graph
	
	// A couple of last thoughts and notes. First, note that so far we haven't done any out-of-sample
	// testing. If you wanted to develop the best model you could to predict ontime high school 
	// graduation with just this data, you should subdivide the dataset so that you would have out of 
	// sample data to use for testing. You'll be able to test your models for the college enrollment Kaggle 
	// competition using 2010 cohort data. Second, should we use subgroup membership variables to 
	// make predictions, if they improve the accuracy of predictions? This is more a policy question than a 
	// technical question, and you should consider it when you are developing your models. You'll also
	// want to check to see how accurate your model is for different subgroups. Finally, once 
	// you've made your college outcome predictions, you'll want to export them to a text file for 
	// uploading into Kaggle. Here's the syntax for exporting a list of student IDs and outcomes in text 
	// format.
	outsheet sid grad_indicator using "$basepath/prediction1.csv", comma replace
	
	log close

	
