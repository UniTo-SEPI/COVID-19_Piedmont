# Gestione e Modellizzazione Dati COVID-19 in Piemonte

[![Language: English](https://img.shields.io/badge/Language-English-red.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/README.md)
[![Documentation: Manual](https://img.shields.io/badge/Docs-Manual-orange.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/docs/README.md)
[![Language: Italian](https://img.shields.io/badge/Language-Italian-blue.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/README-ITA.md) 
[![Documentation: Manual](https://img.shields.io/badge/Docs-Manuale-lightblue.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/docs/README.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/LICENSE)

<img align="right" width="215" height="215" src="https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/images/logo/logo.png?raw=true">

Questo repository contiene il [codice](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/src), [il manuale di documentazione](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/docs/README-ITA.md) e [visualizzazioni dati](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/images/plots) per il design e l'operazione della pipeline di modellizzazione e gestione dei dati di sorveglianza COVID-19 in Piemonte che abbiamo sviluppato in collaborazione con il Servizio Sovrazonale di Epidemiologia ([SEPI](https://www.epi.piemonte.it/)).

Per motivi di privacy tutti i dati contenuti in questo repository sono o [`fake`](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/data/fake-input) (i.e. inventati) or [`synthetic`](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/data/synthetic-input) (i.e. simulati) in modo da essere strutturalmente equivalenti ai dati individuali originali per riprodurre accuratemente il funzionamento della pipeline di modellizzazione dati. 

L'unica referenza ai dati reali si può trovare nei grafici presenti nella cartella [`images/real-output`](https://github.com/UniTo-SEPI/COVID-19_Piedmont/tree/main/images/plots/real-output).

## Come Citare

Se usate questi contenuti nel vostro lavoro siete pregati di citare questo repository usando i metadati contenuti nel file [`CITATION.bib`](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/CITATION.bib).

## Referenze 

### Dati 

1. CSI Piemonte (2020) [Piedmont Region COVID-19 Data Management Platform](https://www.csipiemonte.it/en/project/piedmont-region-covid-19-platform). *CSI Piemonte*
2. CSI Piemonte (2020) [GESCOVID19: Piattaforma di Gestione Dati in Piemonte](https://github.com/regione-piemonte/gescovid19). *GitHub*
3. Leproni (2021) [La Piattaforma COVID-19 della Regione Piemonte](https://www.masteradabi.it/images/CSI_Piattaforma_COVID_20210308_V2.pdf). *CSI Piemonte*
4. Moroni, Monticone (2022) [Italian COVID-19 Integrated Surveillance Dataset](https://doi.org/10.5281/zenodo.5748141). *Zenodo*

### Software 

1. Monticone, Moroni (2022) [ICD_GEMs.jl: A Julia Package to Translate Between ICD-9 and ICD-10 Codes](https://doi.org/10.5281/zenodo.6564434). *Zenodo*
2. Monticone, Moroni (2022) [UnrollingAverages.jl: A Julia Package to Deconvolve Time Series Data.](https://doi.org/10.5281/zenodo.5725301). *Zenodo*


### Articoli 

* Del Manso et al. (2020) [COVID-19 integrated surveillance in Italy: outputs and related activities](https://doi.org/10.19191/EP20.5-6.S2.105). *Epidemiologia & Prevenzione*
* Milani et al. (2021). [Characteristics of patients affecting the duration of positivity at SARS-CoV-2: a cohort analysis of the first wave of epidemic in Italy](https://epiprev.it/5814). *Epidemiologia & Prevenzione* 
* Starnini et al. (2021) [Impact of data accuracy on the evaluation of COVID-19 mitigation policies](https://www.doi.org/10.1017/dap.2021.25). *Data & Policy*, 3, E28. 
* Zhang et al. (2021) [Data science approaches to confronting the COVID-19 pandemic: a narrative review](https://doi.org/10.1098/rsta.2021.0127). *Philosophical Transactions of the Royal Society A*
* Vasiliauskaite et al. (2021) [On some fundamental challenges in monitoring epidemics](https://doi.org/10.1098/rsta.2021.0117). *Philosophical Transactions of the Royal Society A*
* Badker et al. (2021) [Challenges in reported COVID-19 data: best practices and recommendations for future epidemics](http://dx.doi.org/10.1136/bmjgh-2021-005542). *BMJ Global Health*
* Shadbolt et al. (2022) [The Challenges of Data in Future Pandemics](https://doi.org/10.1016/j.epidem.2022.100612). *Epidemics*