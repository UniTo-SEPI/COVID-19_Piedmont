# Documentation Manual

[![Language: Italian](https://img.shields.io/badge/Language-Italian-blue.svg)](https://github.com/UniTo-SEPI/COVID-19_Data_Modelling/blob/main/docs/README-ITA.md) 
[![Language: English](https://img.shields.io/badge/Language-English-red.svg)](https://github.com/UniTo-SEPI/COVID-19_Data_Modelling/blob/main/docs/README.md)

## 0. Age

In order to avoid privacy issues related to the level of granularity, we defined the **following reduced age classification**: `{[0,39],[40,59],[60,69],[70,79],[80+]}`. 

## 1. Symptoms

Acknowledging the complexity of the data on symptomatic cases (multiple dates of symptoms onset, sometimes reported before and after the date of a positive test result) we had to define **key plausibility intervals** in order to: 

1. account for the variability induced by structural delays of the underlying biophysical phenomenon such as the incubation period ([McAloon et al. (2020)](http://dx.doi.org/10.1136/bmjopen-2020-039652));
2. account for the variability induced by contingent delays due to the heterogeneity of adopted diagnostic tests (i.p. different limits of detection) such as the positivity period ([Larremore et al. (2020)](https://doi.org/10.1126/sciadv.abd5393), [Tom, Mina (2020)](https://doi.org/10.1093/cid/ciaa619), [Cevik et al. (2020)](https://doi.org/10.1016/S2666-5247(20)30172-5), [Mallet et al. (2020)](https://doi.org/10.1186/s12916-020-01810-8), [Cleary et al. (2021)](https://doi.org/10.1126/scitranslmed.abf1568), [Boum et al. (2021)](https://doi.org/10.1016/S1473-3099(21)00132-8), [Hellewell et al. (2021)](https://doi.org/10.1186/s12916-021-01982-x), [Kissler et al. (2021)](https://doi.org/10.1371/journal.pbio.3001333 )); 
3. quantify the uncertainty induced by the choice of a particular range or threshold;
4. estimate with higher accuracy and robustness the incidence of latent infections in the period prior to the confirmation of the first positive case in order to set an informed prior on the initial conditions of compartmental models.

Then we defined the following three key **complementary** plausibility intervals:

- `[data_positività - 30, data_positività + 14]` ;
- `[data_positività - 20, data_positività + 14]` ; 
- `[data_positività - 10, data_positività + 14]` .

Therefore the **algorithm** that univocally defines the **effective date of symptoms onset** of a patient works as follows: 

1. Set a plausibility interval;
2. Consider as the effective date of symptoms onset the one closest to the lower limit of the adopted plausibility interval so that there is only one valid date of symptoms onset for each patient.

## 2. Hospitalisations 

We define:

- **Reparto (Ward)**: period of residence in a hospital ward (of ordinary, intensive or rehabilitation `type`) bounded by the key events `data_ammissione` and `data_dimissione`;
- **Ricovero (Hospitalisation)**: array of periods of residence in hospital wards visited by a patient.

In particular: 

* `AO = amissione_ordinaria`: admission to ordinary hospital ward ;
* `DO = dimissione_ordinaria`: discharge from ordinary hospital ward ; 
* `AI = amissione_intensiva`: admission to intensive care unit ;
* `DI = dimissione_intensiva`: discharge from intensive care unit ; 
* `AR = amissione_riabilitativa`: admission to rehabilitative hospital ward ;
* `DR = dimissione_riabilitativa`: discharge from rehabilitative hospital ward .

### 2.1 Pre-positive admissions 

For all patients with `data_ammissione_x` (with `x = ordinaria` or `x = intensiva`) prior to `data_positività`, proceed by setting `data_positività = data_ammissione_x`.

### 2.2 Post-ending admissions

Neglect admissions occurring after the `data_fine_percorso`.

### 2.3 Pre-positive wards

Remove wards which occur entirely before the `data_positività` or whose `data_dimissione` coincides with the `data_positività`.

### 2.4 Juxtaposition and standardisation of wards

IF two successive wards are of the same `type` then the two wards will be replaced by a ward which will have as `data_ammissione` the `data_ammissione` of the first and as `data_dimissione` the `data_dimissione` of the second;

ELSE IF two successive departments are of a different `type` but the `data_ammissione` of the second does not coincide with the `data_ammissione` of the first, then the `data_ammissione` of the first will be changed to the `data_ammissione` of the second.

## 3. Quarantines

We define **quarantine** as a generic isolation period imposed on any individual (whether a suspected case or a confirmed case) fully specified by a `data_inizo_qurantena` and a `data_fine_quarantena`.

* **Precautionary quarantine**: an isolation period imposed on a suspected case fully specified by a `data_inizio_quarantena_precauzionale` and a `data_fine_quarantena_precauzionale` such that `data_fine_quarantena_precauzionale <= data_positività`;
* **Ordinary quarantine**: an isolation period imposed on a confirmed case fully specified by an `data_inizio_quarantena_ordinaria` and an `data_fine_quarantena_ordinaria` such that `data_inizio_quarantena_ordinaria = data_positività`. 

### 3.1 Isolation period or quarantine

From all the [orders, bulletins](https://www.gazzettaufficiale.it/attiAssociati/1?areaNode=17) and [circulars](https://www.salute.gov.it/portale/nuovocoronavirus/archivioNormativaNuovoCoronavirus.jsp?lingua=italiano&area=213&testo=&tipologia=CIRCOLARE&giorno=&mese=&anno=&btnCerca=cerca&iPageNo=6&cPageNo=6) released by the Italian Ministry of Health and extracting all those relevant to inform the choice of the extremes of these intervals (i.e. reporting the number of days of isolation imposed on suspected or confirmed cases):

1. [Ordinance dated 21-02-2020 ](https://www.gazzettaufficiale.it/eli/id/2020/02/22/20A01220/sg);
2. [Ordinance dated 28-03-2020](https://www.gazzettaufficiale.it/eli/id/2020/03/29/20A01921/sg);
3. [Ordinance dated 23-12-2020](https://www.gazzettaufficiale.it/eli/id/2020/12/23/20A07212/sg);
4. [Circular dated 28-02-2020](https://www.trovanorme.salute.gov.it/norme/renderNormsanPdf?anno=2020&codLeg=73458&parte=1&serie=null); 
5. [Circular dated 29-05-2020](https://www.trovanorme.salute.gov.it/norme/renderNormsanPdf?anno=2020&codLeg=74178&parte=1&serie=null);
6. [Circular dated 12-10-2020](https://www.trovanorme.salute.gov.it/norme/renderNormsanPdf?anno=2020&codLeg=76613&parte=1&serie=null).

we can conclude that in Italy during the year 2020 (period for which high resolution data are available) **three different isolation or quarantine period lengths** were effectively applied:

- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 14 days` from 21-02-2020 to 12-10-2020 ;
- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 10 days` with diagnostic tests for asymptomatic cases from 12-10-2020 ;
- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 10 days` of which at least 3 days without symptoms with diagnostic tests for symptomatic cases from 12-10-2020 ;
- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 21 days` from symptoms onset for symptomatic cases from 12-10-2020 ;
- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 10 days` with diagnostic test from the last exposure to confirmed case for close contacts of confirmed cases from 12-10-2020;
- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 14 days` without diagnostic test from the last exposure to confirmed case for close contacts of confirmed cases from 12-10-2020. 

In Piedmont the authorities adopted **a prescriptive algorithm to define isolation or quarantine** documented in detail in [Milani et al. (2021)](https://epiprev.it/5814) for the whole 2020 (i.e. period of interest).

### 3.2 Algorithm to identify the effective quarantine dates

Regarding the **effective end date of quarantine** of a given patient, the following procedure is followed: 

1. IF the patient has `data_fine_quarantena` THEN `data_fine_quarantena_ordinaria` = data_fine_quarantena` ; 
2. IF the patient does NOT have `data_fine_quarantena` AND he has `data_guarigione` or `data_conclusione_percorso` (ASL, SISP) THEN `data_fine_quarantena_ordinaria = data_guarigione` or `data_fine_quarantena_ordinaria = data_conclusione_percorso` ;
3. IF the patient DOES NOT have `data_fine_quarantena` AND DOES NOT have `data_guarigione` or `data_conclusione_percorso`(ASL, SISP) AND HAS `data_ultimo_negativo` THEN `data_fine_quarantena_ordinaria` = `data_ultimo_negativo`. 
4. IF the patient DOES NOT have `data_fine_quarantena` AND DOES NOT have `data_guarigione` or `data_conclusione_percorso` (ASL, SISP) AND DOES NOT have `data_ultimo_negativo` THEN `data_fine_quarantena_ordinaria = data_inizio_quarantena_ordinaria + T_quarantena` (see the algorithm description below for further details). 

In general we define: 

* `T_quarantena = 14` days ;
* `{data_inizio_quarantena_i}`: the set of quarantine start dates (`data_inizio_quarantena`) of a patient ; 
* `{data_inizio_quarantena_i < data_positività}`: the set of `data_inizio_quarantena` prior to positivity date (`data_positività`) ;
* `{data_positività, {data_inizio_quarantena_i}}`: the set containing both `data_inizio_quarantena` and `data_positività` ;
* `{selected_data_inizio_quarantena_i}`: the set of `data_inizio_quarantena` of the $i^{\text{th}}$ patient whose elements are:
  * `selected_data_inizio_quarantena_1 = data_inizio_quarantena_1` ;
  * `selected_data_inizio_quarantena_2 = min({data_inizio_quarantena_i > data_inizio_quarantena_1 + T_quarantena })`;
  * `selected_data_inizio_quarantena_3 = min({data_inizio_quarantena_i > selected_data_inizio_quarantena_2 + T_quarantena })` ;
  * `...` ;
  * `selected_data_inizio_quarantena_i = min({data_inizio_quarantena_i > selected_data_inizio_quarantena_(i-1) + T_quarantena })` ; 
  * `...` ;
* `{data_fine_quarantena_i}`: the set of `data_fine_quarantena` of a patient; 
* `data_ammissione_x`: a generic hospital ward admission date such that `x` $\in$ `{ordinaria, intensiva, riabilitativa}`; 
* `data_dimissione_x`: a generic hospital ward discharge date such that `x` $\in$ `{ordinaria, intensiva, riabilitativa}`; 
* `{data_ammissione_x_i}`: the set of `data_ammissione_x` of a patient; 
* `{data_dimissione_x_i}`: the set of  `data_dimissione_x` of a patient. 

The **algorithm** assigning the effective start and end dates of precautionary and ordinary quarantine to each patient works as follows: 

1. IF the patient DOES NOT have `data_ammissione_ordinaria` AND DOES NOT have `data_ammissione_intensiva` :

   - `data_inizio_quarantena_precauzionale = max({selected_data_inizio_quarantena_i < data_positività})` ;
   - IF the patient has `data_fine_quarantena` AND  it has been assigned  `data_inizio_quarantena_precauzionale`, THEN `data_fine_quarantena_precauzionale = min({data_positività, max({data_inizio_quarantena_precauzionale < data_fine_quarantena_i <= data_positività}) })` ;
   - ELSE IF the patient DOES NOT have `data_fine_quarantena` AND  it has been assigned  `data_inizio_quarantena_precauzionale`, THEN `data_fine_quarantena_precauzionale = min({data_positività, data_inizio_quarantena_precauzionale + T_quarantena})` ;
   - ELSE IF the patient DOES NOT have `data_fine_quarantena` AND it has not been assigned  `data_inizio_quarantena_precauzionale`, THEN it will not be assigned `data_fine_quarantena_precauzionale` ;
   - `data_inizio_quarantena_ordinaria = data_positività` ;
   - IF the patient has `data_guarigione` (or `data_decesso`) THEN proceed as follows:
     - IF `data_guarigione` (or `data_decesso`) is LESS THAN the nearest multiple of 7 days to the upper whisker of transition time delay distribution `P_G` (or `P_D`) away from `data_positività` THEN `data_fine_quarantena_ordinaria = data_guarigione` (or `data_fine_quarantena_ordinaria = data_decesso`);
     - ELSE IF `data_guarigione` (or `data_decesso`) is MORE THAN the nearest multiple of 7 days to the upper whisker of transition time delay distribution `P_G` (or `P_D`) away from `data_positività` AND there is at least a `data_fine_quarantena` THEN `data_fine_quarantena_ordinaria = max(data_positività < data_fine_quarantena_i < data_positività + P_G_upper_whisker)` (or `data_fine_quarantena` allora `data_fine_quarantena_ordinaria = max(data_positività < data_fine_quarantena_i < data_positività + P_D_upper_whisker)`);
     - ELSE IF `data_guarigione` (or `data_decesso`) is MORE THAN the nearest multiple of 7 days to the upper whisker of transition time delay distribution `P_G` (or `P_D`) away from `data_positività` AND there IS NOT any `data_fine_quarantena` THEN `data_fine_quarantena_ordinaria = data_positività + P_G_upper_whisker` (or `data_fine_quarantena_ordinaria = data_positività + P_D_upper_whisker`).
   - ELSE IF the patient DOES NOT have `data_guarigione` (or `data_decesso`) THEN proceed as follows:
     - IF there is at least one `data_fine_quarantena` THEN `data_fine_quarantena_ordinaria = max(data_positività < data_fine_quarantena_i < data_positività + P_G_upper_whisker)`;
     - ELSE IF there IS NOT any `data_fine_quarantena` THEN `data_fine_quarantena_ordinaria = data_positività + P_G_upper_whisker`.

2. IF the patient has `data_ammissione_ordinaria` OR `data_ammissione_intensiva` :
   - `data_inizio_quarantena_precauzionale = max({selected_data_inizio_quarantena_i < data_positività})` ;
   - `data_fine_quarantena_precauzionale = min( {data_positività, max({ data_inizio_quarantena_precauzionale < data_fine_quarantena_i <= data_positività})} )` ;
   - IF the patient has `data_fine_quarantena` AND `max({data_fine_quarantena_i}) <= max({data_dimissione_x_i})`:
     - IF `data_positività = min({data_ammissione_x_i})` THEN no ordinary quarantine will be assigned ;
     - IF `min({data_ammissione_x_i}) > data_positività`: 
       - `data_inizio_quarantena_ordinaria = data_positività` ;
       - `data_fine_quarantena_ordinaria = min({data_ammissione_x_i})` .
     - We don't consider the case in which `data_positività > min({data_ammissione_x_i})` since this possibility has been excluded by [2.1](#2.1-Pre-positive-admissions).
   - ELSE IF the patient has `data_fine_quarantena` AND `max({data_fine_quarantena_i}) > max({data_dimissione_x_i})`:
     - IF `min({data_ammissione_x_i}) = data_positività`, THEN no ordinary quarantine will be assigned;
     - ELSE IF `min({data_ammissione_x_i}) > data_positività`: 
       - `data_inizio_quarantena_ordinaria = data_positività` ;
       - `data_fine_quarantena_ordinaria = min({date_ammissione_x})` .
     - We don't consider the case in which `data_positività > min({data_ammissione_x_i})` since this possibility has been excluded by [2.1](#2.1-Pre-positive-admissions).
   - ELSE IF the patient DOES NOT have `data_fine_quarantena`:
     - IF `min({data_ammissione_x_i}) = data_positività`, THEN no ordinary quarantine will be assigned;
     - IF `min({data_ammissione_x_i}) > data_positività`: 
       - `data_inizio_quarantena_ordinaria = data_positività`;
       - `data_fine_quarantena_ordinaria = min({date_ammissione_x_i})`.
     - We don't consider the case in which `data_positività > min({data_ammissione_x_i})` since this possibility has been excluded by [2.1](#2.1-Pre-positive-admissions).

## 4. Recoveries and Deaths

IF the patient DOES NOT have any `data_ammissione_x` then proceed as follows:

- IF it has `data_guarigione` (or `data_decesso`) AND `data_guarigione > data_fine_quarantena_ordinaria` (or `data_decesso > data_fine_quarantena_ordinaria`) THEN correct `data_guarigione = data_fine_quarantena_ordinaria` (or `data_decesso = data_fine_quarantena_ordinaria`);
- ELSE IF it has NEITHER `data_guarigione` NOR `data_decesso`, THEN `data_guarigione = data_fine_quarantena_ordinaria`.

ELSE IF it has at least one `data_ammissione_x`, THEN proceed as follows:

- IF it has `data_guarigione` (or `data_decesso`) AND `data_guarigione != max({data_dimissione_x_i})` (or `data_decesso != max({data_dimissione_x_i})`) THEN correct `data_guarigione = max({data_dimissione_x_i})` (or `data_decesso = max({data_dimissione_x_i})`);
- ELSE IF it has NEITHER `data_guarigione` NOR `data_decesso`, THEN `data_guarigione = max({data_dimissione_x_i})`.

## 5. Sequences

We define **sequence or clinical pathway or clinical trajectory** the ordered array of **key events**:

* `IQP = inizio_quarantena_precauzionale`: beginning of precautionary quarantine ;
* `FQP = fine_quarantena_precauzionale`: end of precautionary quarantine ;
* `IQO = inizio_quarantena_ordinaria `: beginning of ordinary quarantine ;
* `IS = inizio_sintomi `: symptoms onset ;
* `P = positività `: confirmation of the positive result of an analysed sample collected via diagnostic testing ;
* `AO = amissione_ordinaria `: ordinary hospital ward admission ;
* `DO = dimissione_ordinaria`: ordinary hospital ward discharge ; 
* `AI = amissione_intensiva `: intensive care unit admission ;
* `DI = dimissione_intensiva`: intensive care unit discharge ; 
* `AR = amissione_riabilitativa `: rehabilitative hospital ward admission ;
* `DR = dimissione_riabilitativa`: rehabilitative hospital ward discharge ; 
* `G = guarigione `: recovery ;  
* `D = decesso`: deaths. 

which occur at **key dates**:

* `data_IQP = data_inizio_quarantena_precauzionale` ; 
* `data_FQP = data_fine_quarantena_precauzionale` ;
* `data_IQO = data_inizio_quarantena_ordinaria ` ;
* `data_IS = data_inizio_sintomi ` ;
* `data_P = data_positività ` ; 
* `data_AO = data_amissione_ordinaria ` ;
* `data_DO = data_dimissione_ordinaria` ;
* `data_AI = data_amissione_intensiva ` ;
* `data_DI = data_dimissione_intensiva` ;
* `data_AR = data_amissione_riabilitativa ` ;
* `data_DR = data_dimissione_riabilitativa` ;
* `data_G = data_guarigione ` ;  
* `data_D = data_decesso` .

In the following sections we will:

1. describe the **algorithm** that generates the time series stratified by age and clinical status associated to the sequences extracted from the line-list database managed by the [CSI Piemonte](https://www.csipiemonte.it/en/project/piedmont-region-covid-19-platform); 
2. report a comprehensive but potentially incomplete set of **sequences** to be considered (useful for validation).

### 5.1 Algorithm 

1. Each patient has his/her own ordered sequence of events (e.g. `(IQP,FQP,IQO,IS,P,G)`) that occurred in an ordered sequence of dates (in this example `(data_IQP, data_FQP, data_IQO, data_IS, data_P, data_G)`). 
2. For each date (e.g. `data_IQO=10/03/2020`) in the ordered sequence of events (e.g. `(IQP,FQP,IQO,IS,P,G)`) an observation is added to the **row corresponding to the date** (here `data=data_IQO`) and to the **column corresponding to the event for the specific pathway** (here column `iqp_fqp_IQO_is_p_g`: time series stratified by age and clinical status of symptomatic cases by date of ordinary quarantine start of the cohort whose trajectory is `(IQP,FQP,IQO,IS,P,G)`). 

### 5.2 Set of Possible Sequences

Below we report a comprehensive (but potentially incomplete) set of **ordered pathways to take into account** (i.e. both those including and those excluding ordinary and/or precautionary quarantine, both those including and those excluding symptomatic onset, both those including and those excluding ordinary and/or intensive and/or rehabilitative hospitalisation). The subdivision into **key cases** of the latter was conceived for convenience and clarity of presentation, thus not reflecting any requirement or definition (e.g. the presence or absence of symptomatic flags in order to narrow down the sample of patients with a certain plausible pathway).

##### Asymptomatic Cases 

* `(IQO,P,G) = (inizio_quarantena_ordinaria, positività, guarigione) `: plausible pathway for asymptomatic cases on whom precautionary quarantine has never been imposed;
* `(P,IQO,G) = (positività, inizio_quarantena_ordinaria, guarigione) `: plausible pathway for asymptomatic cases on whom precautionary quarantine has never been imposed;
* `(IQP,FQP,IQO,P,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, guarigione) `: plausible pathway for asymptomatic cases on whom precautionary quarantine has been imposed;
* `(IQP,FQP,P,IQO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, guarigione) `: plausible pathway for asymptomatic cases on whom precautionary quarantine has been imposed;

##### Casi Sintomatici, Non Ricoverati e Guariti

* `(IS,IQO,P,G) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,IS,P,G) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,P,IS,G) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IS,P,IQO,G) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IS,IQO,G) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IQO,IS,G) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQP,FQP,IS,IQO,P,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,IQO,P,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,IS,P,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,P,IS,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IS,P,IQO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,P,IQO,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IS,IQO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IQO,IS,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;

##### Casi Sintomatici, Non Ricoverati e Deceduti

* `(IS,IQO,P,D) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,IS,P,D) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,P,IS,D) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IS,P,IQO,D) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IS,IQO,D) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IQO,IS,D) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQP,FQP,IS,IQO,P,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, decesso) `: plausible pathway for symptomatic cases on whom precautionary quarantine has been imposed;
* `(IS,IQP,FQP,IQO,P,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, decesso) `: plausible pathway for symptomatic cases on whom precautionary quarantine has been imposed;
* `(IQP,FQP,IQO,IS,P,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, decesso) `: plausible pathway for symptomatic cases on whom precautionary quarantine has been imposed;
* `(IQP,FQP,IQO,P,IS,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, decesso) `: plausible pathway for symptomatic cases on whom precautionary quarantine has been imposed;
* `(IQP,FQP,IS,P,IQO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, decesso) `: plausible pathway for symptomatic cases on whom precautionary quarantine has been imposed;
* `(IS,IQP,FQP,P,IQO,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, decesso) `: plausible pathway for symptomatic cases on whom precautionary quarantine has been imposed;
* `(IQP,FQP,P,IS,IQO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, decesso) `: plausible pathway for symptomatic cases on whom precautionary quarantine has been imposed;
* `(IQP,FQP,P,IQO,IS,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, decesso) `: plausible pathway for symptomatic cases on whom precautionary quarantine has been imposed;

##### Casi Sintomatici, Ricoverati Ordinari e Guariti

* `(IS,IQO,P,AO,DO,G) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,IS,P,AO,DO,G) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,P,IS,AO,DO,G) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IS,P,IQO,AO,DO,G) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IS,IQO,AO,DO,G) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IQO,IS,AO,DO,G) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQP,FQP,IS,IQO,P,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,IQO,P,AO,DO,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,IS,P,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,P,IS,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IS,P,IQO,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,P,IQO,AO,DO,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IS,IQO,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IQO,IS,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;

##### Casi Sintomatici, Ricoverati Ordinari e Deceduti

* `(IS,IQO,P,AO,DO,D) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,IS,P,AO,DO,D) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,P,IS,AO,DO,D) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IS,P,IQO,AO,DO,D) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IS,IQO,AO,DO,D) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IQO,IS,AO,DO,D) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQP,FQP,IS,IQO,P,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,IQO,P,AO,DO,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,IS,P,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,P,IS,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IS,P,IQO,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,P,IQO,AO,DO,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IS,IQO,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IQO,IS,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;

##### Casi Sintomatici, Ricoverati Intensivi e Guariti

* `(IS,IQO,P,AI,DI,G) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,IS,P,AI,DI,G) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,P,IS,AI,DI,G) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IS,P,IQO,AI,DI,G) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IS,IQO,AI,DI,G) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IQO,IS,AI,DI,G) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQP,FQP,IS,IQO,P,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,IQO,P,AI,DI,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,IS,P,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,P,IS,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IS,P,IQO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,P,IQO,AI,DI,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IS,IQO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IQO,IS,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;

##### Casi Sintomatici, Ricoverati Intensivi e Deceduti

* `(IS,IQO,P,AI,DI,D) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,IS,P,AI,DI,D) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,P,IS,AI,DI,D) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IS,P,IQO,AI,DI,D) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IS,IQO,AI,DI,D) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IQO,IS,AI,DI,D) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQP,FQP,IS,IQO,P,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,IQO,P,AI,DI,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,IS,P,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,P,IS,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IS,P,IQO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,P,IQO,AI,DI,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IS,IQO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IQO,IS,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;

##### Casi Sintomatici, Ricoverati Ordinari-Intensivi e Guariti

* `(IS,IQO,P,AO,DO,AI,DI,G) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,IS,P,AO,DO,AI,DI,G) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,P,IS,AO,DO,AI,DI,G) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IS,P,IQO,AO,DO,AI,DI,G) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IS,IQO,AO,DO,AI,DI,G) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IQO,IS,AO,DO,AI,DI,G) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQP,FQP,IS,IQO,P,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,IQO,P,AO,DO,AI,DI,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,IS,P,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,P,IS,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IS,P,IQO,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,P,IQO,AO,DO,AI,DI,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IS,IQO,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;

##### Casi Sintomatici, Ricoverati Ordinari-Intensivi e Deceduti

* `(IS,IQO,P,AO,DO,AI,DI,D) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,IS,P,AO,DO,AI,DI,D) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,P,IS,AO,DO,AI,DI,D) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IS,P,IQO,AO,DO,AI,DI,D) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IS,IQO,AO,DO,AI,DI,D) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IQO,IS,AO,DO,AI,DI,D) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQP,FQP,IS,IQO,P,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,IQO,P,AO,DO,AI,DI,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,IS,P,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,P,IS,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IS,P,IQO,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,P,IQO,AO,DO,AI,DI,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IS,IQO,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;

##### Casi Sintomatici, Ricoverati Ordinari-Intensivi-Riabilitativi e Guariti

* `(IS,IQO,P,AO,DO,AI,DI,AR,DR,G) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,IS,P,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,P,IS,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IS,P,IQO,AO,DO,AI,DI,AR,DR,G) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IS,IQO,AO,DO,AI,DI,AR,DR,G) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IQO,IS,AO,DO,AI,DI,AR,DR,G) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQP,FQP,IS,IQO,P,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,IQO,P,AO,DO,AI,DI,AR,DR,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,IS,P,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,P,IS,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IS,P,IQO,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,P,IQO,AO,DO,AI,DI,AR,DR,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IS,IQO,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;

##### Casi Sintomatici, Ricoverati Ordinari-Intensivi-Riabilitativi e Deceduti

* `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,IS,P,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQO,P,IS,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IS,P,IQO,AO,DO,AI,DI,AR,DR,D) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IS,IQO,AO,DO,AI,DI,AR,DR,D) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(P,IQO,IS,AO,DO,AI,DI,AR,DR,D) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible trajectory for symptomatic cases on which precautionary quarantine has never been imposed;
* `(IQP,FQP,IS,IQO,P,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,IQO,P,AO,DO,AI,DI,AR,DR,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,IS,P,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IQO,P,IS,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,IS,P,IQO,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IS,IQP,FQP,P,IQO,AO,DO,AI,DI,AR,DR,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IS,IQO,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;
* `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: plausible pathway for symptomatic cases undergoing precautionary quarantine;

Therefore the variables or columns of the final dataset (of which we will only report below a considerable portion) would be:

*  `data`: data relativa al giorno di calendario ;
*  `età`: classe di età; 
*  `stato_clinico`: stato clinico appartenente all'insieme {"SINTOMATICO", "ASINTOMATICO"};
*  `IQO_p_g`: serie temporale stratificata per età e stato clinico dei casi asintomatici per date of ordinary quarantine start of the cohort whose trajectory is `(IQO,P,G) `;
*  `iqo_P_g`: serie temporale stratificata per età e stato clinico dei casi asintomatici per date of positivity of the cohort whose trajectory is `(IQO,P,G) `;
*  `iqo_p_G`: serie temporale stratificata per età e stato clinico dei casi asintomatici per data di guarigione della coorte con percorso `(IQO,P,G) `;
*  ...
*  `IS_iqo_p_g`: time series stratified by age and clinical status of symptomatic cases by date of symptoms onset of the cohort whose trajectory is `(IS,IQO,P,G) `;
*  `is_IQO_p_g`: time series stratified by age and clinical status of symptomatic cases by date of ordinary quarantine start of the cohort whose trajectory is `(IS,IQO,P,G) `;
*  `is_iqo_P_g`: time series stratified by age and clinical status of symptomatic cases by date of positivity of the cohort whose trajectory is `(IS,IQO,P,G) `;
*  `is_iqo_p_G`: time series stratified by age and clinical status of symptomatic cases by data di guarigione della coorte con percorso `(IS,IQO,P,G) `;
*  ...
*  `IS_iqo_p_ao_do_d`: time series stratified by age and clinical status of symptomatic cases by date of symptoms onset of the cohort whose trajectory is `(IS,IQO,P,AO,DO,D) `;
*  `is_IQO_p_ao_do_d`: time series stratified by age and clinical status of symptomatic cases by date of ordinary quarantine start of the cohort whose trajectory is `(IS,IQO,P,AO,DO,D) `;
*  `is_iqo_P_ao_do_d`: time series stratified by age and clinical status of symptomatic cases by date of positivity of the cohort whose trajectory is `(IS,IQO,P,AO,DO,D) `;
*  `is_iqo_p_AO_do_d`: time series stratified by age and clinical status of symptomatic cases by date of ordinary admission of the cohort whose trajectory is `(IS,IQO,P,AO,DO,D) `;
*  `is_iqo_p_ao_DO_d`: time series stratified by age and clinical status of symptomatic cases by date of ordinary discharge of the cohort whose trajectory is `(IS,IQO,P,AO,DO,D) `;
*  `is_iqo_p_ao_do_D`: time series stratified by age and clinical status of symptomatic cases by date of death of the cohort whose trajectory is `(IS,IQO,P,AO,DO,D) `;
*  ...
*  `IS_iqo_p_ao_do_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of symptoms onset of the cohort whose trajectory is `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_IQO_p_ao_do_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of ordinary quarantine start of the cohort whose trajectory is `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_P_ao_do_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of positivity of the cohort whose trajectory is `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_AO_do_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of ordinary admission of the cohort whose trajectory is `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_DO_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of ordinary discharge of the cohort whose trajectory is `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_do_AI_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of intensive admission of the cohort whose trajectory is `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_do_ai_DI_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of intensive discharge of the cohort whose trajectory is `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_do_ai_di_AR_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of rehabilitative admission of the cohort whose trajectory is `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_do_ai_di_ar_DR_d`: time series stratified by age and clinical status of symptomatic cases by date of rehabilitative discharge of the cohort whose trajectory is `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_do_ai_di_ar_dr_D`: time series stratified by age and clinical status of symptomatic cases by date of death of the cohort whose trajectory is `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  ...
*  `IQP_fqp_p_iqo_is_ao_do_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of precautionary quarantine start of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_FQP_p_iqo_is_ao_do_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of precautionary quarantine end of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_P_iqo_is_ao_do_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of positivity of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_IQO_is_ao_do_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of ordinary quarantine start of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_IS_ao_do_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of symptoms onset of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_AO_do_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of ordinary admission of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_DO_ai_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of ordinary discharge of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_do_AI_di_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of intensive admission of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_do_ai_DI_ar_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of intensive discharge of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_do_ai_di_AR_dr_d`: time series stratified by age and clinical status of symptomatic cases by date of rehabilitative admission of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_do_ai_di_ar_DR_d`: time series stratified by age and clinical status of symptomatic cases by date of rehabilitative discharge of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_do_ai_di_ar_dr_D`: time series stratified by age and clinical status of symptomatic cases by date of death of the cohort whose trajectory is `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;

## 6. Transition Time Delays

We define **transition time delays** the temporal intervals between two key events: 

* `T_IQP_FQP`: time delay between `inizio_quarantena_precauzionale` and `fine_quarantena_precauzionale` ; 
* `T_FQP_IS`: time delay between `fine_quarantena_precauzionale` and `inizio_sintomi` ; 
* `T_FQP_P`: time delay between `fine_quarantena_precauzionale` and `positività` ; 
* `T_FQP_IQO`: time delay between `fine_quarantena_precauzionale` and `inizio_quarantena_ordinaria` ; 
* `T_IS_P`: time delay between `inizio_sintomi` and `positività` ; 
* `T_IS_IQO`: time delay between `inizio_sintomi` and `inizio_quarantena_ordinaria` ; 
* `T_IS_AO`: time delay between `inizio_sintomi` and `ammissione_ordinaria` ; 
* `T_IS_AI`: time delay between `inizio_sintomi` and `ammissione_intensiva` ; 
* `T_IS_G`: time delay between `inizio_sintomi` and `guarigione` ; 
* `T_IS_D`: time delay between `inizio_sintomi` and `decesso` ; 
* `T_P_IS`: time delay between `positività` and `inizio_sintomi` ; 
* `T_P_IQO`: time delay between `positività` and `inizio_quarantena_ordinaria` ; 
* `T_P_AO`: time delay between `positività` and `ammissione_ordinaria` ; 
* `T_P_AI`: time delay between `positività` and `ammissione_intensiva` ; 
* `T_P_G`: time delay between `positività` and `guarigione` ; 
* `T_P_D`: time delay between `positività` and `decesso` ; 
* `T_IQO_P`: time delay between `inizio_quarantena_ordinaria` and `positività` ; 
* `T_IQO_IS`: time delay between `inizio_quarantena_ordinaria` and `inizio_sintomi` ; 
* `T_IQO_AO`: time delay between `inizio_quarantena_ordinaria` and `ammissione_ordinaria` ; 
* `T_IQO_AI`: time delay between `inizio_quarantena_ordinaria` and `ammissione_intensiva` ; 
* `T_IQO_G`: time delay between `inizio_quarantena_ordinaria` and `guarigione` ; 
* `T_IQO_D`: time delay between `inizio_quarantena_ordinaria` and `decesso` ; 
* `T_AO_DO`: time delay between `ammissione_ordinaria` and `dimissione_ordinaria` ; 
* `T_AO_AI`: time delay between `ammissione_ordinaria` and `ammissione_intensiva` ; 
* `T_AO_G`: time delay between `ammissione_ordinaria` and `guarigione` ; 
* `T_AO_D`: time delay between `ammissione_ordinaria` and `decesso` ; 
* `T_DO_AI`: time delay between `dimissione_ordinaria` and `ammissione_intensiva` ; 
* `T_DO_G`: time delay between `dimissione_ordinaria` and `guarigione` ; 
* `T_DO_D`: time delay between `dimissione_ordinaria` and `decesso` ; 
* `T_AI_DI`: time delay between `ammissione_intensiva` and `dimissione_intensiva` ; 
* `T_AI_AR`: time delay between `ammissione_intensiva` and `ammissione_riabilitativa` ; 
* `T_AI_G`: time delay between `ammissione_intensiva` and `guarigione` ; 
* `T_AI_D`: time delay between `ammissione_intensiva` and `decesso` ; 
* `T_DI_AR`: time delay between `dimissione_intensiva` and `ammissione_riabilitativa` ; 
* `T_DI_G`: time delay between `dimissione_intensiva` and `guarigione` ; 
* `T_DI_D`: time delay between `dimissione_intensiva` and `decesso` ; 
* `T_AR_DR`: time delay between `ammissione_riabilitativa` and `dimissione_riabilitativa` ; 
* `T_AR_G`: time delay between `ammissione_riabilitativa` and `guarigione` ; 
* `T_AR_D`: time delay between `ammissione_riabilitativa` and `decesso` ; 
* `T_DR_G`: time delay between `dimissione_riabilitativa` and `guarigione` ; 
* `T_DR_D`: time delay between `dimissione_riabilitativa` and `decesso` ; 

The **output dataset** consists of several tables, each one showing the empirical distribution of a specific transition time delay for a given age class, clinical state and temporally, with the width of the interval being denoted by `T`, with daily binning. For each tuple `(T_A_B, classe_età, stato_clinico)`, the procedure is as follows:

1. Consider a tuple `(T_A_B, classe_età, stato_clinico)`, set the time aggregation period `T` to `T = 0 days` ;
2. Increase `T` by 1 day ;
3. Calculate the empirical distributions of transition times relative to each interval width `T` into which the dataset is divided ;
4. If there are no more NAs due to privacy, save the dataset, move on to the next tuple, and then return to step 1. ;
5. If there are still NAs due to privacy, save the dataset and return to step 2.

In order to further clarify the operation of the **algorithm** described above, we provide a simplified example below:

##### 6.1 Dataset of Key Dates in INPUT (TRUNCATED)

| `id` | `età` | `stato_clinico` | `data_IQP` | `data_FQP` | `data_IQO` | `data_IS`  |  `data_P`  |
| :--: | :---: | :-------------: | :--------: | :--------: | :--------: | :--------: | :--------: |
|  1   |  73   |   SINTOMATICO   |     NA     |     NA     | 01-03-2020 | 02-03-2020 | 03-03-2020 |
|  2   |  75   |   SINTOMATICO   |     NA     |     NA     | 02-03-2020 | 03-03-2020 | 06-03-2020 |
|  3   |  78   |   SINTOMATICO   |     NA     |     NA     | 01-03-2020 | 02-03-2020 | 03-03-2020 |
|  4   |  71   |   SINTOMATICO   |     NA     |     NA     | 01-03-2020 | 02-03-2020 | 04-03-2020 |
|  5   |  70   |   SINTOMATICO   |     NA     |     NA     | 02-03-2020 | 02-03-2020 | 04-03-2020 |
|  6   |  79   |   SINTOMATICO   |     NA     |     NA     | 01-03-2020 | 02-03-2020 | 04-03-2020 |
|  7   |  77   |   SINTOMATICO   |     NA     |     NA     | 01-03-2020 | 02-03-2020 | 05-03-2020 |
|  8   |  78   |   SINTOMATICO   |     NA     |     NA     | 02-03-2020 | 02-03-2020 | 05-03-2020 |
|  9   |  73   |   SINTOMATICO   |     NA     |     NA     | 01-03-2020 | 02-03-2020 | 05-03-2020 |
|  10  |  71   |   SINTOMATICO   |     NA     |     NA     | 01-03-2020 | 02-03-2020 | 04-03-2020 |
|  11  |  78   |   SINTOMATICO   |     NA     |     NA     | 01-03-2020 | 02-03-2020 | 03-03-2020 |
|  12  |  74   |   SINTOMATICO   |     NA     |     NA     | 02-03-2020 | 02-03-2020 | 06-03-2020 |
|  13  |  72   |   SINTOMATICO   |     NA     |     NA     | 02-03-2020 | 02-03-2020 | 06-03-2020 |
|  14  |  70   |   SINTOMATICO   |     NA     |     NA     | 01-03-2020 | 02-03-2020 | 03-03-2020 |

##### 6.2 Dataset of Empirical Time Delay Distribution `T_IQO_P` for `70-79` years old Symptomatic Cases in age class with `T=1` in OUTPUT (SAVED as "Distribuzione_IQO_P_70-79_Sintomatici_1.csv")

| `data_inizio` | `data_fine` | `T`  | `T_IQO_P` | `frequenza_T_IQO_P` |
| :-----------: | :---------: | :--: | :-------: | :-----------------: |
|  01-03-2020   | 01-03-2020  |  1   |     0     |          0          |
|  01-03-2020   | 01-03-2020  |  1   |     1     |          0          |
|  01-03-2020   | 01-03-2020  |  1   |     2     |          4          |
|  01-03-2020   | 01-03-2020  |  1   |     3     |         NA          |
|  01-03-2020   | 01-03-2020  |  1   |     4     |         NA          |
|  01-03-2020   | 01-03-2020  |  1   |     5     |          0          |
|  01-03-2020   | 01-03-2020  |  1   |     0     |          0          |
|  01-03-2020   | 01-03-2020  |  1   |     1     |          0          |
|  01-03-2020   | 01-03-2020  |  1   |     2     |         NA          |
|  02-03-2020   | 02-03-2020  |  1   |     3     |         NA          |
|  02-03-2020   | 02-03-2020  |  1   |     4     |         NA          |
|  02-03-2020   | 02-03-2020  |  1   |     5     |          0          |

##### 6.3 Dataset of Empirical Time Delay Distribution `T_IQO_P` for `70-79` years old Symptomatic Cases in age class with `T=2` in OUTPUT (SAVED as "Distribuzione_IQO_P_70-79_Sintomatici_2.csv")

| `data_inizio` | `data_fine` | `T`  | `T_IQO_P` | `frequenza_T_IQO_P` |
| :-----------: | :---------: | :--: | :-------: | :-----------------: |
|  01-03-2020   | 02-03-2020  |  2   |     0     |          0          |
|  01-03-2020   | 02-03-2020  |  2   |     1     |          0          |
|  01-03-2020   | 02-03-2020  |  2   |     2     |          5          |
|  01-03-2020   | 02-03-2020  |  2   |     3     |          4          |
|  01-03-2020   | 02-03-2020  |  2   |     4     |          5          |
|  01-03-2020   | 02-03-2020  |  2   |     5     |          0          |

## 7. Hospital Discharge Certificates (HDCs) and Death Certificates (DCs)

### Objectives

- Estimating the latent infections in the pre-surveillance period required to initialise some variables and parameters of the simulation models to be calibrated on the incidence time series stratified by age and sequence extracted as described in the previous sections;
- Analysis of the excesses of key event (admissions, deaths, etc.) stratified by cause also aimed at inferring any misdiagnosed COVID-19 cases. 

### Synthesis 

The codes below should be used to construct a dataset similar to the [5. Sequences](#5-Sequences) section stratified by age and cause-specific code aggregation over the period 2015-2020. 

As stated in the [ministerial reports on hospitalisations](http://www.salute.gov.it/portale/temi/p2_4.jsp?lingua=italiano&tema=Assistenza,ospedaleeterritorio&area=ricoveriOspedalieri): 

* the coding system adopted for the HDCs is the **ICD-9**;
* the coding system adopted for the DCs is the **ICD-10**.

Since the DCs are only available until 2018, we were forced to consider only the HDCs in the analysis described below.

### Age

The age classification is the same as described above in section [0. Age](#0-Age).

### Codes 

In order to select ICD-10 codes to be converted via our package [ICD_GEMs.jl](https://github.com/JuliaHealth/ICD_GEMs.jl) into the corresponding relevant ICD-9 codes, we conducted a [rapid review](https://github.com/UniTo-SEPI/COVID-19_Data_Modelling/tree/main/docs/references) of the literature with a focus on the analysis of death certificates recorded in Italy. This review supports the choice of the set of codes assigned to complications and comorbidities associated with COVID-19 that we report below. 

#### Concomitant OR Precipitating OR Antecedents 

| ICD-10 Codes                                                 | Description                                               | References                                                   |
| ------------------------------------------------------------ | --------------------------------------------------------- | ------------------------------------------------------------ |
| U071, U072                                                   | COVID-19                                                  | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) ; [Grande et al. (2021)](https://doi.org/10.3390/covid1040060) |
| U071, U072, J09-J189, J80, J849, J96x                        | COVID-19 + Flu, pneumonia + selected respiratory diseases | [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) |
| A00-B99                                                      | Infectious and parasitic diseases                         | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| A40–A41                                                      | Sepsis                                                    | [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) |
| A40-A41, B37, B49, B99                                       | Sepsis and infections of unspecified site                 | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| C00-D48                                                      | Neoplasms                                                 | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) ; [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) ; [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| C00-C96                                                      | Neoplasms                                                 | [Grande et al. (2021)](https://doi.org/10.3390/covid1040060) |
| C00–C97                                                      | Malignant neoplasms                                       | [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) |
| E00–E90                                                      | Endocrine, nutritional, and metabolic diseases            | [Grande et al. (2021)](https://doi.org/10.3390/covid1040060) |
| E00-E99                                                      | Endocrine, nutritional and metabolic diseases of which    | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| E10-E14                                                      | Diabetes                                                  | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) ; [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) ; [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) ; [Grande et al. (2021)](https://doi.org/10.3390/covid1040060) |
| E66                                                          | Obesity                                                   | [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| E86-E87                                                      | Volume depletion and other fluid disorders                | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| G30, G31, F01, F03                                           | Dementia and Alzheimer                                    | [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) |
| F00–F99                                                      | Mental and behavioral disorders                           | [Grande et al. (2021)](https://doi.org/10.3390/covid1040060) |
| F00-F03, G30-G31                                             | Dementia and Alzheimer's disease                          | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| F03, G30                                                     | Dementia and Alzheimer’s disease                          | [Grande et al. (2021)](https://doi.org/10.3390/covid1040060) |
| F01-F03, G30                                                 | Dementia and Alzheimer                                    | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) ; [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) |
| G00-H99                                                      | Diseases of the nervous system (excluding Alzheimer)      | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| I00-I99                                                      | Diseases of the circulatory system of which               | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) |
| I10-I15                                                      | Hypertensive heart diseases                               | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) ; [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) ; [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) ; [Grande et al. (2021)](https://doi.org/10.3390/covid1040060) ; [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| I20-I24                                                      | Acute ischemic heart diseases                             | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| I20-I25                                                      | Ischaemic heart diseases                                  | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) ; [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) ; [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) |
| I26                                                          | Pulmonary embolism                                        | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| I48                                                          | Atrial fibrillation                                       | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) |
| I50                                                          | Heart failure                                             | [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) |
| I50-I51                                                      | Heart failure and other cardiac diseases                  | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| I60-I69                                                      | Cerebrovascular diseases                                  | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) ; [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) ; [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) |
| J00-J99                                                      | Diseases of the respiratory system of which               | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) ; [Grande et al. (2021)](https://doi.org/10.3390/covid1040060) |
| I00-I09, I90-I99                                             | Other circulatory diseases                                | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| J00–J06, J20–J39, J60–J70, J80–J86, J90–J96, J97–J99, R09.2, U04 | Other diseases of the respiratory system                  | [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) |
| I00–I99                                                      | Diseases of the circulatory system                        | [Grande et al. (2021)](https://doi.org/10.3390/covid1040060) |
| I00–I09, I26–I49, I51, I52, I70–I99                          | Other disease of the circulatory system                   | [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) |
| J09–J18                                                      | Infuenza and pneumonia                                    | [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) ; [Grande et al. (2021)](https://doi.org/10.3390/covid1040060) |
| J09-J189                                                     | Flu, Pneumonia                                            | [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) |
| J40-J47                                                      | Chronic lower-respiratory diseases                        | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) ; [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) ; [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) ; [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| J80, J849, J96x                                              | Selected respiratory diseases                             | [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) |
| J81                                                          | Pulmonary oedema                                          | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| J00-J11, J30-J39, J60-J70, J82-J848, J85-J99                 | Other diseases of the respiratory system                  | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| K00-K99                                                      | Diseases of the digestive system                          | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| K70, K73, K74                                                | Chronic liver diseases                                    | [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) |
| K70-K77                                                      | Chronic liver diseases                                    | [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| N17–N19                                                      | Renal failure                                             | [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) ; [CDC-NCHS (2022)](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm) ; [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| N18                                                          | Chronic renal failure                                     | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| R00-R99                                                      | Symptoms, signs, unspecified                              | [Fedeli et al. (2021)](https://doi.org/10.26355/eurrev_202105_25844) ; [Grande et al. (2021)](https://doi.org/10.3390/covid1040060) |
| R570-R571, R573-R579                                         | Shock                                                     | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| S00-T98                                                      | External causes                                           | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |

#### Complications 

| ICD-10 Codes                     | Description                                                  | References                                                   |
| -------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| A00-A09                          | Intestinal infections                                        | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| A00–A09, K50–K67                 | Intestinal complications                                     | [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| A00-B99                          | Some infectious diseases                                     | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| A40-A41, A49, B34, B37, B44, B99 | Sepsis and bacterial infections of unspecified site          | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| A40–A41, A49, B25–B49, B99, R572 | Sepsis, septic shock, and infections                         | [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| C00-D48                          | Neoplasms                                                    | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| D50-D99                          | Diseases of blood and blood forming organs                   | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| E10-E14                          | Endocrine diseases                                           | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| E40-E46                          | Nutritional disorders                                        | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| E66                              | Obesity                                                      | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| E70-E90                          | Other diseases of the metabolism                             | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| E86                              | Dehydration                                                  | [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| F00-F99                          | Mental and behavioural disorders                             | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| G00-H99                          | Other diseases of the nervous system                         | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| G04, G93                         | Encephalitis, myelitis and encephalomyelitis                 | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| I00-I09, I27-I45, I47, I52       | Specified cardiac diseases                                   | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| I10-I5                           | Hypertensive heart diseases                                  | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| I20-I24                          | Myocardial infarction                                        | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| I21                              | Acute myocardial infarction                                  | [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| I25                              | Chronic ischaemic heart disease                              | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| I26                              | Pulmonary embolism                                           | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| I70-I79, I83-I89, I95-I99        | Other circulatory diseases                                   | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| I46                              | Cardiac arrest                                               | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| I48-I49                          | Atrial fibrillation and other arrhythmias                    | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| I50-I51                          | Heart complications (heart failure and unspecified cardiac disease) | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| I60-I64                          | Acute cerebrovascular accidents                              | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| I80-I82                          | Phlebitis, thrombophlebitis and thrombosis of peripheral vessels | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| J00-J99                          | Other respiratory diseases                                   | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| J12-J18, J84, J98                | Pneumonia                                                    | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| J12-J18, J849                    | Pneumonia                                                    | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| J80-J81                          | ARDS and pulmonary oedema                                    | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459) ; [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| J80                              | Adult respiratory distress syndrome (ARDS)                   | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| J960, J969                       | Respiratory failure                                          | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| J96, R04, R06, R09               | Respiratory failure and related symptoms                     | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| K00-K99                          | Other diseases of the digestive system                       | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| K50-K67                          | Other diseases of intestine and peritoneum                   | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| K70-K77                          | Chronic liver diseases                                       | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| M00-M99                          | Diseases of the musculoskeletal system and connective tissue | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| N00, N04, N17, N19               | Kidney failure                                               | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| N17, N19                         | Renal failure                                                | [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| N00-N99                          | Other diseases of the genitourinary system                   | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| R04-R09                          | Symptoms and signs involving the respiratory system          | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| R57                              | Shock                                                        | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
| R57 (excluding R572)             | Shock (cardiogenic)                                          | [Grippo et al. (2021)](https://doi.org/10.3389/fmed.2021.645543) |
| R65                              | Systemic inflammatory response syndrome (SIRS)               | [Orsi et al. (2021)](https://www.istat.it/it/files/2021/05/RSU-1_2021_Article-3.pdf) |
| S00-T98, V01-Y98                 | External causes                                              | [Grippo et al. (2020)](https://doi.org/10.3390/jcm9113459)   |
