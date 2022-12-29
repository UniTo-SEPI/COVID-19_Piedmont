# ICD-10 -> ICD-9 translations of InPhyT 2022 codes
const ICD_9_CM_translations = Dict(
                                    "Intestinal infections"    => execute_applied_mapping(I10_I9_GEMs_dict, ["A00-A09"], "all"),
                                    "Intestinal complications" => execute_applied_mapping(I10_I9_GEMs_dict, ["A00-A09", "K50-K67"], "all"),
                                    "Some infectious diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["A00-A99", "B00-B99"], "all"),
                                    "Sepsis and bacterial infections of unspecified site" => execute_applied_mapping(I10_I9_GEMs_dict, ["A40-A41", "A49", "B34", "B37", "B44", "B99"], "all"),
                                    "Sepsis, septic shock, and infections" => execute_applied_mapping(I10_I9_GEMs_dict, ["A40–A41", "A49", "B25–B49", "B99", "R572"], "all"),
                                    "Neoplasms-all" => execute_applied_mapping(I10_I9_GEMs_dict, ["C00-C99","D00-D48"], "all"),
                                    "Diseases of blood and blood forming organs" => execute_applied_mapping(I10_I9_GEMs_dict, ["D50-D99"], "all"),
                                    "Endocrine diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["E10-E14"], "all"),
                                    "Nutritional disorders" => execute_applied_mapping(I10_I9_GEMs_dict, ["E40-E46"], "all"),
                                    "Other diseases of the metabolism (Grippo)" => execute_applied_mapping(I10_I9_GEMs_dict, ["E70-E90"], "all"),
                                    "Dehydration" => execute_applied_mapping(I10_I9_GEMs_dict, ["E86"], "all"),
                                    "Mental and behavioural disorders" => execute_applied_mapping(I10_I9_GEMs_dict, ["F00-F99"], "all"),
                                    "Other diseases of the nervous system (Grippo)" => execute_applied_mapping(I10_I9_GEMs_dict, ["G00-G99", "H00-H99"], "all"),
                                    "Encephalitis, myelitis and encephalomyelitis" => execute_applied_mapping(I10_I9_GEMs_dict, ["G04","G93"], "all"),
                                    "Specified cardiac diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I00-I09", "I27-I45", "I47", "I52"], "all"),
                                    "Myocardial infarction" => execute_applied_mapping(I10_I9_GEMs_dict, ["I20-I24"], "all"),
                                    "Acute myocardial infarction" => execute_applied_mapping(I10_I9_GEMs_dict, ["I21"], "all"),
                                    "Chronic ischaemic heart disease" => execute_applied_mapping(I10_I9_GEMs_dict, ["I25"], "all"),
                                    "Other circulatory diseases (Grippo)" => execute_applied_mapping(I10_I9_GEMs_dict, ["I70-I79", "I83-I89", "I95-I99"], "all"),
                                    "Cardiac arrest" => execute_applied_mapping(I10_I9_GEMs_dict, ["I46"], "all"),
                                    "Atrial fibrillation and other arrhythmias (Grippo)" => execute_applied_mapping(I10_I9_GEMs_dict, ["I48-I49"], "all"),
                                    "Heart complications (heart failure and unspecified cardiac disease)" => execute_applied_mapping(I10_I9_GEMs_dict, ["I50-I51"], "all"),
                                    "Acute cerebrovascular accidents" => execute_applied_mapping(I10_I9_GEMs_dict, ["I60-I64"], "all"),
                                    "Phlebitis, thrombophlebitis and thrombosis of peripheral vessels" => execute_applied_mapping(I10_I9_GEMs_dict, ["I80-I82"], "all"),
                                    "Other respiratory diseases (Grippo)" => execute_applied_mapping(I10_I9_GEMs_dict, ["J00-J99"], "all"),
                                    "Pneumonia (Grippo)" => execute_applied_mapping(I10_I9_GEMs_dict, ["J12-J18", "J84","J98"], "all"),
                                    "Pneumonia-Orsi" => execute_applied_mapping(I10_I9_GEMs_dict, ["J12-J18", "J849"], "all"),
                                    "ARDS and pulmonary oedema" => execute_applied_mapping(I10_I9_GEMs_dict, ["J80-J81"], "all"),
                                    "Adult respiratory distress syndrome (ARDS)" => execute_applied_mapping(I10_I9_GEMs_dict, ["J80"], "all"),
                                    "Respiratory failure" => execute_applied_mapping(I10_I9_GEMs_dict, ["J960", "J969"], "all"),
                                    "Respiratory failure and related symptoms" => execute_applied_mapping(I10_I9_GEMs_dict, ["J96", "R04", "R06", "R09"], "all"),
                                    "Other diseases of the digestive system (Grippo)" => execute_applied_mapping(I10_I9_GEMs_dict, ["K00-K99"], "all"),
                                    "Other diseases of intestine and peritoneum (Grippo)" => execute_applied_mapping(I10_I9_GEMs_dict, ["K50-K67"], "all"),
                                    "Diseases of the musculoskeletal system and connective tissue" => execute_applied_mapping(I10_I9_GEMs_dict, ["M00-M99"], "all"),                               
                                    "Kidney failure" => execute_applied_mapping(I10_I9_GEMs_dict, ["N00", "N04", "N17", "N19"], "all"),
                                    "Renal failure (Grippo)" => execute_applied_mapping(I10_I9_GEMs_dict, ["N17", "N19"], "all"),
                                    "Other diseases of the genitourinary system (Grippo)" => execute_applied_mapping(I10_I9_GEMs_dict, ["N00-N99"], "all"),
                                    "Symptoms and signs involving the respiratory system" => execute_applied_mapping(I10_I9_GEMs_dict, ["R04-R09"], "all"),
                                    "Shock (Grippo)" => execute_applied_mapping(I10_I9_GEMs_dict, ["R57"], "all"),
                                    "Shock (cardiogenic)" => execute_applied_mapping(I10_I9_GEMs_dict, ["R571", "R573-R579"], "all"),
                                    "Systemic inflammatory response syndrome (SIRS)" => execute_applied_mapping(I10_I9_GEMs_dict, ["R65"], "all"),
                                    "External causes" => execute_applied_mapping(I10_I9_GEMs_dict, ["S00-S99", "T00-T98", "V01-V99", "W00-W99", "X00-X99", "Y00-Y98"], "all")
    )

    # #ICD-10 -> ICD-9 translations of Orsi 2021 codes
    # const ICD_9_CM_translations_orsi = Dict(
    #                                 # Antencedents
    #                                 "Neoplasms"                          => execute_applied_mapping(I10_I9_GEMs_dict, ["C00-C99", "D00-D48"], "all"),
    #                                 "Chronic lower respiratory diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["J40-J47"], "all"),
    #                                 "Cerebrovascular accident"           => execute_applied_mapping(I10_I9_GEMs_dict, ["I60-I66", "I670", "I672-I679"], "all"),
    #                                 "Hypertensive heart disease"         => execute_applied_mapping(I10_I9_GEMs_dict, ["I10-I13"], "all"),
    #                                 "Dementia"                           => execute_applied_mapping(I10_I9_GEMs_dict, ["F00-F03"], "all"),
    #                                 "Chronic ischemic heart disease" => execute_applied_mapping(I10_I9_GEMs_dict, ["I25"], "all"),
    #                                 "Diabetes mellitus" => execute_applied_mapping(I10_I9_GEMs_dict, ["E10-E14"], "all"),
    #                                 "Atrial fibrillation" => execute_applied_mapping(I10_I9_GEMs_dict, ["I48"], "all"),
    #                                 "Alzheimer disease" => execute_applied_mapping(I10_I9_GEMs_dict, ["G30-G31"], "all"),
    #                                 "Chronic renal failure" => execute_applied_mapping(I10_I9_GEMs_dict, ["N18"], "all"),
    #                                 # Precipitating conditions
    #                                 "Heart failure and other cardiac diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I50-I51"], "all"),
    #                                 "Sepsis and infections of unspecified site" => execute_applied_mapping(I10_I9_GEMs_dict, ["A40-A41", "B37", "B49", "B99"], "all"),
    #                                 "Shock" => execute_applied_mapping(I10_I9_GEMs_dict, ["R570-R571", "R573-R579"], "all"),
    #                                 "Renal failure, acute and unspecified" => execute_applied_mapping(I10_I9_GEMs_dict, ["N17", "N19"], "all"),
    #                                 "Other diseases of the respiratory system" => execute_applied_mapping(I10_I9_GEMs_dict, ["J00-J11", "J30-J39", "J60-J70", "J820-J848", "J85-J99"], "all"),
    #                                 "Volume depletion and other fluid disorders" => execute_applied_mapping(I10_I9_GEMs_dict, ["E86-E87"], "all"),
    #                                 "Acute ischemic heart diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I20-I24"], "all"),
    #                                 "Pulmonary embolism" => execute_applied_mapping(I10_I9_GEMs_dict, ["I26"], "all"),
    #                                 "Other infectious and parasitic diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["A00-A39", "A42-A99", "B00-B36", "B38-B48", "B50-B98"], "all"),
    #                                 "Other circulatory diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I00-I09", "I90-I99"], "all"),
    #                                 "Pulmonary oedema" => execute_applied_mapping(I10_I9_GEMs_dict, ["J81"], "all"),
    #                                 # Complications
    #                                 "Pneumonia" => execute_applied_mapping(I10_I9_GEMs_dict, ["J12-J18", "J849"], "all"),
    #                                 "Respiratory failure" => execute_applied_mapping(I10_I9_GEMs_dict, ["J960", "J969"], "all"),
    #                                 "Adult respiratory distress syndrome (ARDS)" => execute_applied_mapping(I10_I9_GEMs_dict, ["J80"], "all"),
    #                                 "Symptoms and signs involving the respiratory system" => execute_applied_mapping(I10_I9_GEMs_dict, ["R04-R09"], "all"),
    #                                 "Systemic inflammatory response syndrome (SIRS)" => execute_applied_mapping(I10_I9_GEMs_dict, ["R65"], "all")) =#



    # #ICD-10 -> ICD-9 translations of Orsi 2021 codes
    # const ICD_9_CM_translations_orsi_and_all_respiratory = Dict(
    #                                 # Antencedents
    #                                 "Neoplasms"                          => execute_applied_mapping(I10_I9_GEMs_dict, ["C00-C99", "D00-D48"], "all"),
    #                                 "Chronic lower respiratory diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["J40-J47"], "all"),
    #                                 "Cerebrovascular accident"           => execute_applied_mapping(I10_I9_GEMs_dict, ["I60-I66", "I670", "I672-I679"], "all"),
    #                                 "Hypertensive heart disease"         => execute_applied_mapping(I10_I9_GEMs_dict, ["I10-I13"], "all"),
    #                                 "Dementia"                           => execute_applied_mapping(I10_I9_GEMs_dict, ["F00-F03"], "all"),
    #                                 "Chronic ischemic heart disease" => execute_applied_mapping(I10_I9_GEMs_dict, ["I25"], "all"),
    #                                 "Diabetes mellitus" => execute_applied_mapping(I10_I9_GEMs_dict, ["E10-E14"], "all"),
    #                                 "Atrial fibrillation" => execute_applied_mapping(I10_I9_GEMs_dict, ["I48"], "all"),
    #                                 "Alzheimer disease" => execute_applied_mapping(I10_I9_GEMs_dict, ["G30-G31"], "all"),
    #                                 "Chronic renal failure" => execute_applied_mapping(I10_I9_GEMs_dict, ["N18"], "all"),
    #                                 # Precipitating conditions
    #                                 "Heart failure and other cardiac diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I50-I51"], "all"),
    #                                 "Sepsis and infections of unspecified site" => execute_applied_mapping(I10_I9_GEMs_dict, ["A40-A41", "B37", "B49", "B99"], "all"),
    #                                 "Shock" => execute_applied_mapping(I10_I9_GEMs_dict, ["R570-R571", "R573-R579"], "all"),
    #                                 "Renal failure, acute and unspecified" => execute_applied_mapping(I10_I9_GEMs_dict, ["N17", "N19"], "all"),
    #                                 "Other diseases of the respiratory system" => execute_applied_mapping(I10_I9_GEMs_dict, ["J00-J11", "J30-J39", "J60-J70", "J820-J848", "J85-J99"], "all"),
    #                                 "Volume depletion and other fluid disorders" => execute_applied_mapping(I10_I9_GEMs_dict, ["E86-E87"], "all"),
    #                                 "Acute ischemic heart diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I20-I24"], "all"),
    #                                 "Pulmonary embolism" => execute_applied_mapping(I10_I9_GEMs_dict, ["I26"], "all"),
    #                                 "Other infectious and parasitic diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["A00-A39", "A42-A99", "B00-B36", "B38-B48", "B50-B98"], "all"),
    #                                 "Other circulatory diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["I00-I09", "I90-I99"], "all"),
    #                                 "Pulmonary oedema" => execute_applied_mapping(I10_I9_GEMs_dict, ["J81"], "all"),
    #                                 # Complications
    #                                 "Pneumonia" => execute_applied_mapping(I10_I9_GEMs_dict, ["J12-J18", "J849"], "all"),
    #                                 "Respiratory failure" => execute_applied_mapping(I10_I9_GEMs_dict, ["J960", "J969"], "all"),
    #                                 "Adult respiratory distress syndrome (ARDS)" => execute_applied_mapping(I10_I9_GEMs_dict, ["J80"], "all"),
    #                                 "Symptoms and signs involving the respiratory system" => execute_applied_mapping(I10_I9_GEMs_dict, ["R04-R09"], "all"),
    #                                 "Systemic inflammatory response syndrome (SIRS)" => execute_applied_mapping(I10_I9_GEMs_dict, ["R65"], "all"),
    #                                 # Further respiratory aggregations
    #                                 ## Grippo
    #                                 "Diseases of the respiratory system" => execute_applied_mapping(I10_I9_GEMs_dict, ["J00-J99"], "all"),
    #                                 "Pneumonia Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["J12-J18", "J84", "J98"], "all"),
    #                                 "ARDS and pulmonary oedema Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["J80-J81"], "all"),
    #                                 "Respiratory failure and related symptoms Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["J96", "R04", "R06", "R09"], "all"),
    #                                 ## Fedeli
    #                                 "Flu, Pneumonia Fedeli" => execute_applied_mapping(I10_I9_GEMs_dict, ["J090-J189"], "all"),
    #                                 ## CDC-NCHS 
    #                                 "Other diseases of the respiratory system CDC-NCHS" => execute_applied_mapping(I10_I9_GEMs_dict, ["J00–J06", "J20–J39", "J60–J70", "J80–J86", "J90–J96", "J97–J99", "R092","U04"], "all"),
    #                                 # Further Cardiovasular aggregations
    #                                 ## Grippo
    #                                 "Diseases of the circulatory system" => execute_applied_mapping(I10_I9_GEMs_dict, ["I00-I99"], "all"),
    #                                 "Hypertensive heart diseases Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["I10-I15"], "all"),
    #                                 "Ischaemic heart diseases Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["I20-I25"], "all"),
    #                                 "Cerebrovascular diseases Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["I60-I69"], "all"),
    #                                 "Specified cardiac diseases Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["I00-I09", "I27-I45", "I47", "I52"], "all"),
    #                                 "Chronic ischaemic heart disease Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["I25"], "all"),
    #                                 "Other circulatory diseases Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["I70-I79", "I83-I89", "I95-I99"], "all"),
    #                                 "Cardiac arrest Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["I46"], "all"),
    #                                 "Atrial fibrillation and other arrhythmias Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["I48-I49"], "all"),
    #                                 "Acute cerebrovascular accidents Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["I60-I64"], "all"),
    #                                 "Phlebitis, thrombophlebitis and thrombosis of peripheral vessels Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["I80-I82"], "all"),
    #                                 "Heart complications Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["I50–I51"], "all"),
    #                                 ## CDC-NCHS
    #                                 "Other disease of the circulatory system CDC-NCHS" => execute_applied_mapping(I10_I9_GEMs_dict, ["I00–I09", "I26–I49", "I51", "I52", "I70–I99"], "all"),
    #                                 # Infectious and parasitic diseases
    #                                 ## Grippo
    #                                 "Infectious and parasitic diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["A00-A99","B00-B99"], "all"),
    #                                 # Endocrine, nutritional and metabolic diseases
    #                                 ## Grippo
    #                                 "Endocrine, nutritional and metabolic diseases" => execute_applied_mapping(I10_I9_GEMs_dict, ["E00-E99"], "all"),
    #                                 # Mental and behavioural disorders
    #                                 ## Grippo
    #                                 "Mental and behavioural disorders" => execute_applied_mapping(I10_I9_GEMs_dict, ["F00-F99"], "all"),
    #                                 "Dementia and Alzheimer Grippo" => execute_applied_mapping(I10_I9_GEMs_dict, ["F01-F03", "G30"], "all"),
    #                                 # Diseases of the nervous system
    #                                 ## Grippo
    #                                 "Diseases of the nervous system" => execute_applied_mapping(I10_I9_GEMs_dict, ["G00-G99","H00-H99"], "all"),
    #                                 # Diseases of the digestive system
    #                                 ## Grippo
    #                                 "Diseases of the digestive system" => execute_applied_mapping(I10_I9_GEMs_dict, ["K00-K99"], "all"),
    #                                 # Diseases of the musculoskeletal system and connective tissue
    #                                 ## Grippo
    #                                 "Diseases of the musculoskeletal system and connective tissue" => execute_applied_mapping(I10_I9_GEMs_dict, ["M00-M99"], "all"),
    #                                 # Other diseases of the genitourinary system
    #                                 ## Grippo
    #                                 "Other diseases of the genitourinary system" => execute_applied_mapping(I10_I9_GEMs_dict, ["N00-N99"], "all"),
    #                                 # Symptoms, signs, unspecified
    #                                 ## Fedeli
    #                                 "Symptoms, signs, unspecified" => execute_applied_mapping(I10_I9_GEMs_dict, ["R00-R99"], "all"),
    #                                 )