Determine_Significance = function(input = NULL, choice = NULL) {
  StepName = "Determine_Significance"
  Choices = c("Holm", "Bonferroni", "None")
  Order = 13
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:

  # Handles all Choices listed above 
  # Runs the statistical Test, corrects for multiple comparisons and 
  # Prepares Output Table
  
  # (1) Get Names and Formulas of variable Predictors
  # (2) Initiate Functions for Hypothesis Testing
  # (3) Main Effects of Accuracy for different Tasks
  # (4) Interaction with Perfectionism
  # (5) Correct for Multiple Comparisons
  # (6) Export as CSV file
  
  
  
  
  #########################################################
  # (1) Get Names and Formulas of variable Predictors
  #########################################################
  # Names are used to select relevant columns
  # Formula (parts) are used to be put together and parsed to the lm() function,
  # thats why they have to be added by a * or +

  
  # Get column Names and Formula for Covariates
  if (input$stephistory["Covariate"] == "None") { 
    Covariate_Formula = ""
    Covariate_Name = vector()
  } else if (input$stephistory["Covariate"] == "Gender_MF") { 
    Covariate_Formula = "+ Covariate_Gender"
    Covariate_Name = "Covariate_Gender"
  } else if (input$stephistory["Covariate"] == "Age_MF") { 
    Covariate_Formula = "+ Covariate_Age"
    Covariate_Name = "Covariate_Age"
  } else { 
    Covariate_Name = names(output)[names(output) %like% "Covariate_"]
    if (length(Covariate_Name)  > 1) {
      Covariate_Formula = paste("*(", paste(Covariate_Name, collapse = " + "), ")")
    } else {
      Covariate_Formula = paste( "*", Covariate_Name)
    }
  }
  
  
  # Get possible additional factors to be included in the GLM (depends on the forking
  # these have been determined at earlier step (Covariate) when determining the grouping variables)
  #additional_Factors_Name = input$stephistory[["additional_Factors_Name"]]
  #additional_Factor_Formula = input$stephistory[["additional_Factor_Formula"]]
  # not sure but always three electrodes?
  additional_Factors_Name = "Electrode"
  additional_Factor_Formula = "+ Electrode"
  
  #########################################################
  # (2) Initiate Functions for Hypothesis Testing
  #########################################################
  wrap_test_Hypothesis = function (Name_Test,lm_formula,  Data, Component, Task, columns_to_keep) {
    # wrapping function to parse specific Information to the test_Hypothesis Function
    # Does three things: (1) Select Subset depending on Conditions and Tasks ans Analysis Phase
    # (2) Test the Hypothesis/Calculate Model and 
    # (3) Checks the direction of the effects
    # Inputs:
    # Name_Test is the Name that will be added as first collumn, to identify tests across forks, str (next to the actual interaction term)
    # lm_formula contains the formula that should be given to the lm, str
    # Data contains data (that will be filtered), df
    # GMA_Measure selects relevant Data
    # Task selects relevant Data
    # columns_to_keep lists all collumns that should be checked for completeness, array of str

    # Create Subset
    Subset = Data[Data$Component == Component &
                    Data$Task == Task,
                  names(Data) %in% c("ID", "Lab", "Epochs", "SME", "Component", columns_to_keep)]
    
    # Run Model
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, "exportModel")
    
    # extract all Effects
    Estimates = rbind(
      # Main Condition
      test_Hypothesis( "Main_Condition",lm_formula, Subset, "Condition", "previousModel", ModelResult),
      
      # Main PersonalStandards
      test_Hypothesis( "Main_Standards",lm_formula, Subset, "Personality_MPS_PersonalStandards", "previousModel", ModelResult),
      
      # Main ConcernOverMistakes
      test_Hypothesis( "Main_Concerns",lm_formula, Subset, "Personality_MPS_ConcernOverMistakes", "previousModel", ModelResult),
      
      #  Condition * PersonalStandards
      test_Hypothesis( "ConditionxStandards",lm_formula, Subset, c("Condition", "Personality_MPS_PersonalStandards"), "previousModel", ModelResult),
      
      #  Condition * ConcernOverMistakes
      test_Hypothesis( "ConditionxConcerns",lm_formula, Subset, c("Condition", "Personality_MPS_ConcernOverMistakes"), "previousModel", ModelResult),
      
      #  PersonalStandards * ConcernOverMistakes
      test_Hypothesis( "StandardsxConcerns",lm_formula, Subset, c("Personality_MPS_PersonalStandards", "Personality_MPS_ConcernOverMistakes"), "previousModel", ModelResult),
      
      #  Condition *PersonalStandards * ConcernOverMistakes 
      test_Hypothesis( "StandardsxConcernsxCondition",lm_formula, Subset, c("Condition", "Personality_MPS_ConcernOverMistakes", "Personality_MPS_PersonalStandards"), "previousModel", ModelResult))
    
    # Adjust Direction to estimates
    Estimates$value_EffectSize[which(Estimates$Estimate_summary<0)] = Estimates$value_EffectSize[which(Estimates$Estimate_summary<0)]*-1
    
    # Add Info for Label
    Estimates$Effect_of_Interest = paste0(Name_Test, "_", Estimates$Effect_of_Interest)
    return(Estimates)
  }
  

  #########################################################
  # (1) EEG Components
  #########################################################
  #5.1. We expect larger Ne/c amplitudes with higher PSP scores.
  #5.2. We expect smaller Ne/c amplitudes with higher ECP scores.
  #5.3. We expect larger Pe/c amplitudes with larger PSP scores
  
  Estimates = data.frame()
  
    columns_to_keep = c("Condition", Covariate_Name, 
                        "Personality_MPS_PersonalStandards",
                        "Personality_MPS_ConcernOverMistakes",
                        "EEG_Signal", "Electrode")
    lm_formula =   paste( "EEG_Signal ~ ( ( Condition * Personality_MPS_PersonalStandards * Personality_MPS_ConcernOverMistakes) )", 
                          Covariate_Formula, additional_Factor_Formula)
    
    for (i_Component in c("ERN", "PE")) {
      for (i_task in c("GoNoGo", "Flanker")) {
        print(paste("Test ", i_task, i_Component))

        Estimates = rbind(Estimates,
                                wrap_test_Hypothesis(paste0(i_task, "_", i_Component),
                                                     lm_formula, output, i_Component, i_task,
                                                     columns_to_keep))
        
      }}
  
    
  #########################################################
  # (5) Behaviour
  #########################################################
    #5.4. We expect more Post-Response Accuracy with higher PSP scores.
    #5.5. We expect less Post-Response Accuracy with higher ECP scores.
    #5.6. We expect more Pre-Post-Response Reaction Time Differences with higher PSP scores.
    #5.7. We expect less Pre-Post-Response Reaction Time Differences with higher ECP scores.
    columns_to_keep = c("Condition", Covariate_Name, 
                        "Personality_MPS_PersonalStandards",
                        "Personality_MPS_ConcernOverMistakes",
                        "Behav")
    lm_formula =   paste( "Behav ~ ( ( Condition * Personality_MPS_PersonalStandards * Personality_MPS_ConcernOverMistakes) )", 
                          Covariate_Formula)
    
    for (i_Component in c("RTDiff", "post_ACC")) {
      for (i_task in c("GoNoGo", "Flanker")) {
        print(paste("Test ", i_task, i_Component))
        
        Estimates = rbind(Estimates,
                          wrap_test_Hypothesis(paste0(i_task, "_", i_Component),
                                               lm_formula, output, i_Component, i_task,
                                               columns_to_keep))
        
      }}
  
  
  #########################################################
  # (6) Correct for Multiple Comparisons 
  #########################################################
    # For every Effect 4 Tests?
    Effects = c("Main_Condition","Main_Standards", "Main_Concerns", 
                "ConditionxStandards", "ConditionxConcerns", "
                StandardsxConcerns", "StandardsxConcernsxCondition")
  for (i_task in c("GoNoGo", "Flanker")) {
    for (i_Test in Effects) {
      Idx = grepl(i_Test, Estimates$Effect_of_Interest) &
        grepl(i_task, Estimates$Effect_of_Interest)
      Estimates$p_Value[Idx] = p.adjust(Estimates$p_Value[Idx],
                                       method = tolower(choice), n = 4)
      
    }
  }
  
  #########################################################
  # (6) Export as CSV file
  #########################################################
  FileName= input$stephistory[["Final_File_Name"]]
  write.csv(Estimates,FileName, row.names = FALSE)
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = Estimates,
    stephistory = stephistory
  ))
}
