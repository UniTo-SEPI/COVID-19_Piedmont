# Piedmont COVID-19 Data Modelling & Management

[![Language: Italian](https://img.shields.io/badge/Language-Italian-blue.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/README-ITA.md) 
[![Documentation: Manuale](https://img.shields.io/badge/Docs-Manuale-lightblue.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/docs/README-ITA.md)
[![Language: English](https://img.shields.io/badge/Language-English-red.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/README.md)
[![Documentation: Manual](https://img.shields.io/badge/Docs-Manual-orange.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/docs/README.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/LICENSE)

<img align="right" width="230" height="225" src="https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/images/logo/logo.png?raw=true">

This repository contains the [code](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/src), [documentation manual](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/docs) and [data visualisations](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/images/plots) for the design and operation of the Piedmont COVID-19 surveillance data modelling and management pipeline developed in collaboration with the Piedmont Epidemiological Service ([SEPI](https://www.epi.piemonte.it/)).

For privacy purposes all the data in this repository are either [`fake`](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/data/fake-input) (i.e. invented) or [`synthetic`](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/data/synthetic-input) (i.e. simulated) in order to be structurally equivalent to the original individual-level data to accurately showcase the functionalities of the data modelling and management pipeline. 

The only reference to the real data can be found in the plots located in the [`images/real-output`](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/images/plots/real-output) folder. 

## How to Cite

If you use these contents in your work, please cite this repository using the metadata in [`CITATION.bib`](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/CITATION.bib).

## References 

### Data 

1. CSI Piemonte (2020) [Piedmont Region COVID-19 Data Management Platform](https://www.csipiemonte.it/en/project/piedmont-region-covid-19-platform). *CSI Piemonte*
2. CSI Piemonte (2020) [GESCOVID19: COVID-19 Data Management Platform in Piedmont](https://github.com/regione-piemonte/gescovid19). *GitHub*
3. Leproni (2021) [The Piedmont Region COVID-19 Platform](https://www.masteradabi.it/images/CSI_Piattaforma_COVID_20210308_V2.pdf). *CSI Piemonte*
4. Moroni, Monticone (2022) [Italian COVID-19 Integrated Surveillance Dataset](https://doi.org/10.5281/zenodo.5748141). *Zenodo*

### Software 

1. Monticone, Moroni (2022) [ICD_GEMs.jl: A Julia Package to Translate Between ICD-9 and ICD-10 Codes](https://doi.org/10.5281/zenodo.6564434). *Zenodo*
2. Monticone, Moroni (2022) [UnrollingAverages.jl: A Julia Package to Deconvolve Time Series Data.](https://doi.org/10.5281/zenodo.5725301). *Zenodo*

### Papers 

* Del Manso et al. (2020) [COVID-19 integrated surveillance in Italy: outputs and related activities](https://doi.org/10.19191/EP20.5-6.S2.105). *Epidemiologia & Prevenzione*
* Milani et al. (2021). [Characteristics of patients affecting the duration of positivity at SARS-CoV-2: a cohort analysis of the first wave of epidemic in Italy](https://epiprev.it/5814). *Epidemiologia & Prevenzione* 
* Starnini et al. (2021) [Impact of data accuracy on the evaluation of COVID-19 mitigation policies](https://www.doi.org/10.1017/dap.2021.25). *Data & Policy*, 3, E28. 
* Zhang et al. (2021) [Data science approaches to confronting the COVID-19 pandemic: a narrative review](https://doi.org/10.1098/rsta.2021.0127). *Philosophical Transactions of the Royal Society A*
* Vasiliauskaite et al. (2021) [On some fundamental challenges in monitoring epidemics](https://doi.org/10.1098/rsta.2021.0117). *Philosophical Transactions of the Royal Society A*
* Badker et al. (2021) [Challenges in reported COVID-19 data: best practices and recommendations for future epidemics](http://dx.doi.org/10.1136/bmjgh-2021-005542). *BMJ Global Health*
* Shadbolt et al. (2022) [The Challenges of Data in Future Pandemics](https://doi.org/10.1016/j.epidem.2022.100612). *Epidemics*