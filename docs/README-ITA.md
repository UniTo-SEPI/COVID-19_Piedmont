# Manuale di Documentazione

[![Language: English](https://img.shields.io/badge/Language-English-red.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/docs/README.md)
[![Language: Italian](https://img.shields.io/badge/Language-Italian-blue.svg)](https://github.com/UniTo-SEPI/COVID-19_Piedmont/blob/main/docs/README-ITA.md) 

## 0. Età

Per evitare l'insorgere di problemi di privacy legati al livello di dettaglio abbiamo definito la **seguente classificazione d'età ridotta**: `{[0,39],[40,59],[60,69],[70,79],[80+]}`. 

## 1. Sintomi

Riconosciuta la complessità dei dati relativi ai casi sintomatici (molteplice data di insorgenza dei sintomi, talvolta riportati prima e dopo la data di esito positivo del test diagnostico) abbiamo dovuto definire degli **intervalli di plausibilità notevoli** al fine di: 

1. tenere conto della variabilità indotta da ritardi strutturali del fenomeno sottostante come il periodo di incubazione ([McAloon et al. (2020)](http://dx.doi.org/10.1136/bmjopen-2020-039652));
2. sondare la variabilità indotta da ritardi contingenti dovuti all'eterogeneità dei dispositivi diagnostici (i.p. diverso limit of detection) utilizzati come il periodo di positività ([Larremore et al. (2020)](https://doi.org/10.1126/sciadv.abd5393), [Tom, Mina (2020)](https://doi.org/10.1093/cid/ciaa619), [Cevik et al. (2020)](https://doi.org/10.1016/S2666-5247(20)30172-5), [Mallet et al. (2020)](https://doi.org/10.1186/s12916-020-01810-8), [Cleary et al. (2021)](https://doi.org/10.1126/scitranslmed.abf1568), [Boum et al. (2021)](https://doi.org/10.1016/S1473-3099(21)00132-8), [Hellewell et al. (2021)](https://doi.org/10.1186/s12916-021-01982-x), [Kissler et al. (2021)](https://doi.org/10.1371/journal.pbio.3001333)); 
3. quantificare l'incertezza indotta dalla scelta di un particolare intervallo o soglia;
4. stimare con maggior accuratezza e robustezza l'incidenza di infezioni latenti nel periodo precedente alla conferma del primo caso positivo in modo da poter fissare le condizioni iniziali dei modelli compartimentali.

Abbiamo quindi definito i seguenti tre intervalli di plausibilità notevoli **complementari**:

- `[data_positività - 30, data_positività + 14]` ;
- `[data_positività - 20, data_positività + 14]` ; 
- `[data_positività - 10, data_positività + 14]` .

Pertanto l'**algoritmo** che definisce univocamente l'**effettiva data di insorgenza sintomi** di un paziente funziona come segue: 

1. Impostare un intervallo di plausibilità;
2. Considerare come effettiva data di insorgenza sintomi quella più prossima al limite inferiore dell'intervallo di plausibilità adottato in modo che ci sia un'unica data di insorgenza sintomi valida per ogni paziente.

## 2. Ricoveri 

Definiamo:

- **Reparto**: periodo di residenza in un reparto ospedaliero (di `tipo` ordinario, intensivo oppure riabilitativo) delimitato dagli eventi notevoli `data_ammissione` e `data_dimissione`;
- **Ricovero**: successione di periodi di residenza in reparti ospedalieri visitati da un paziente.

In particolare: 

* `AO = amissione_ordinaria `: ammissione in reparto ordinario ;
* `DO = dimissione_ordinaria`: dimissione da reparto ordinario ; 
* `AI = amissione_intensiva `: ammissione in reparto intensivo ;
* `DI = dimissione_intensiva`: dimissione da reparto intensivo ; 
* `AR = amissione_riabilitativa `: ammissione in reparto riabilitativo ;
* `DR = dimissione_riabilitativa`: dimissione da reparto riabilitativo .

### 2.1 Ricoveri pre-tempone positivo 

Per ciò che concerne tutti i pazienti che possiedono `data_ammissione_x` (con `x = ordinaria`  o  `x = intensiva`) precedente alla `data_positività` si procede impostando `data_positività = data_ammissione_x` .

### 2.2 Ricoveri post-fine percorso

Trascurare i ricoveri avvenuti dopo la `data_fine_percorso`.

### 2.3 Reparti pre-positività

Rimuovere i reparti che avvengono interamente prima della `data_positività` o la cui `data_dimissione` coincide con la `data_positività`.

### 2.4 Giustapposizione e uniformizzazione reparti

SE due reparti successivi sono dello stesso `tipo` allora i due reparti saranno sostituiti da un reparto che avrà come `data_ammissione` la `data_ammissione` del primo e come `data_dimissione` la `data_dimissione` del secondo;

ALTRIMENTI SE due reparti successivi sono di `tipo` diverso ma la `data_ammissione` del secondo non coincide con la `data_dimissione` del primo, allora si porterà la `data_dimissione` del primo alla `data_ammissione` del secondo.

## 3. Quarantene

Definiamo **quarantena** un generico periodo di isolamento imposto ad un qualunque soggetto (sia questo un caso sospetto o un caso confermato) completamente specificato da una `data_inizo_qurantena` ed una `data_fine_quarantena`.

* **Quarantena precauzionale**:  un periodo di isolamento imposto ad un caso sospetto completamente specificato da una `data_inizio_quarantena_precauzionale` e una `data_fine_quarantena_precauzionale ` tale che `data_fine_quarantena_precauzionale <= data_positività`;
* **Quarantena ordinaria**: un periodo di isolamento imposto ad un caso confermato completamente specificato da una `data_inizio_quarantena_ordinaria` e una `data_fine_quarantena_ordinaria` tale che `data_inizio_quarantena_ordinaria = data_positività`. 

### 3.1 Periodo di isolamento o quarantena 

Dalla lettura di tutte le [ordinanze, i comunicati](https://www.gazzettaufficiale.it/attiAssociati/1?areaNode=17) e [le circolari](https://www.salute.gov.it/portale/nuovocoronavirus/archivioNormativaNuovoCoronavirus.jsp?lingua=italiano&area=213&testo=&tipologia=CIRCOLARE&giorno=&mese=&anno=&btnCerca=cerca&iPageNo=6&cPageNo=6) emanati dal Ministero della Salute ed estratto tutti quelli rilevanti per informare la scelta degli estremi di tali intervalli (i.e. che presentassero il numero di giorni di isolamento imposti a casi sospetti o confermati):

1. [Ordinanza del 21-02-2020 ](https://www.gazzettaufficiale.it/eli/id/2020/02/22/20A01220/sg);
2. [Ordinanza del 28-03-2020](https://www.gazzettaufficiale.it/eli/id/2020/03/29/20A01921/sg);
3. [Ordinanza del 23-12-2020](https://www.gazzettaufficiale.it/eli/id/2020/12/23/20A07212/sg);
4. [Circolare del 28-02-2020](https://www.trovanorme.salute.gov.it/norme/renderNormsanPdf?anno=2020&codLeg=73458&parte=1&serie=null); 
5. [Circolare del 29-05-2020](https://www.trovanorme.salute.gov.it/norme/renderNormsanPdf?anno=2020&codLeg=74178&parte=1&serie=null);
6. [Circolare del 12-10-2020](https://www.trovanorme.salute.gov.it/norme/renderNormsanPdf?anno=2020&codLeg=76613&parte=1&serie=null).

si evince che in Italia durante l'anno 2020 (periodo di interesse per cui sono disponibili i dati stratificati per età e stato clinico) sono stati applicate **tre differenti durate del periodo di isolamento o quarantena**:

- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 14 giorni` dal 21-02-2020 al 12-10-2020 ;
- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 10 giorni` con test per gli asintomatici dal 12-10-2020 ;
- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 10 giorni` di cui almeno 3 giorni senza sintomi con test per i sintomatici dal 12-10-2020 ;
- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 21 giorni` dall'insorgenza dei sintomi per i sintomatici dal 12-10-2020 ;
- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 10 giorni` con test dall'ultima esposizione al caso confermato positivo per i contatti stretti di casi confermati positivi dal 12-10-2020;
- `T_quarantena = |data_fine_quarantena - data_inizio_quarantena| = 14 giorni` senza test dall'ultima esposizione al caso confermato positivo per i contatti stretti di casi confermati positivi dal 12-10-2020. 

In Piemonte è stato adottato **un algoritmo prescrittivo di quarantena ed isolamento** documentato in [Milani et al. (2021)](https://epiprev.it/5814) per tutto l'anno 2020 (periodo di interesse per cui sono disponibili i dati stratificati per età e stato clinico). 

### 3.2 Algoritmo di identificazione date effettive di quarantena 

Per ciò che concerne l'**effettiva data di fine di quarantena** di un paziente si procede come segue: 

1. SE il paziente possiede `data_fine_quarantena` ALLORA `data_fine_quarantena_ordinaria = data_fine_quarantena` ; 
2. SE il paziente NON possiede `data_fine_quarantena` E possiede `data_guarigione` o `data_conclusione_percorso` (ASL, SISP) ALLORA `data_fine_quarantena_ordinaria = data_guarigione` o `data_fine_quarantena_ordinaria = data_conclusione_percorso` ;
3. SE il paziente NON possiede `data_fine_quarantena` E NON possiede `data_guarigione` o `data_conclusione_percorso`(ASL, SISP) E possiede `data_ultimo_negativo` ALLORA `data_fine_quarantena_ordinaria = data_ultimo_negativo` 
4. SE il paziente NON possiede `data_fine_quarantena` E NON possiede `data_guarigione` o `data_conclusione_percorso` (ASL, SISP) E NON possiede `data_ultimo_negativo` ALLORA `data_fine_quarantena_ordinaria = data_inizio_quarantena_ordinaria + T_quarantena` (per i dettagli si veda la descrizione dell'algoritmo riportata di seguito). 

In generale definiamo: 

* `T_quarantena = 14 giorni` ;
* `{data_inizio_quarantena_i}`: l'insieme delle `data_inizio_quarantena` di un paziente ; 
* `{data_inizio_quarantena_i < data_positività}`: l'insieme delle `data_inizio_quarantena` precedenti alla `data_positività` ;
* `{data_positività, {data_inizio_quarantena_i}}`: l'insieme che contiene sia le `data_inizio_quarantena` sia la `data_positività` ;
* `{selected_data_inizio_quarantena_i}`: l'insieme delle `data_inizio_quarantena` di un paziente i cui elementi sono:
  * `selected_data_inizio_quarantena_1 = data_inizio_quarantena_1` ;
  * `selected_data_inizio_quarantena_2 = min({data_inizio_quarantena_i > data_inizio_quarantena_1 + T_quarantena })`;
  * `selected_data_inizio_quarantena_3 = min({data_inizio_quarantena_i > selected_data_inizio_quarantena_2 + T_quarantena })` ;
  * `...` ;
  * `selected_data_inizio_quarantena_i = min({data_inizio_quarantena_i > selected_data_inizio_quarantena_(i-1) + T_quarantena })` ; 
  * `...` ;
* `{data_fine_quarantena_i}`: l'insieme delle `data_fine_quarantena` di un paziente; 
* `data_ammissione_x`: una generica data di ammissione in reparto ospedaliero con `x` IN `{ordinaria, intensiva, riabilitativa}`; 
* `data_dimissione_x`: una generica data di dimissione da reparto ospedaliero con `x` IN `{ordinaria, intensiva, riabilitativa}`; 
* `{data_ammissione_x_i}`: l'insieme delle `data_ammissione_x` di un paziente; 
* `{data_dimissione_x_i}`: l'insieme delle `data_dimissione_x` di un paziente. 

L' **algoritmo** che si occupa di assegnare le date effettive di inizio e fine quarantena ordinaria e precauzionale a ciascun paziente funziona come segue: 

1. Se non presenta `data_ammissione_ordinaria` E non presenta `data_ammissione_intensiva` :

   - `data_inizio_quarantena_precauzionale = max({selected_data_inizio_quarantena_i < data_positività})` ;
   - SE presenta `data_fine_quarantena` E si è assegnata `data_inizio_quarantena_precauzionale`, ALLORA `data_fine_quarantena_precauzionale = min({data_positività, max({data_inizio_quarantena_precauzionale < data_fine_quarantena_i <= data_positività}) })` ;

   - ALTRIMENTI SE non presenta `data_fine_quarantena` E si è assegnata `data_inizio_quarantena_precauzionale`, ALLORA `data_fine_quarantena_precauzionale = min({data_positività, data_inizio_quarantena_precauzionale + T_quarantena})` ;
   - ALTRIMENTI SE non presenta `data_fine_quarantena` E non si è assegnata `data_inizio_quarantena_precauzionale`, ALLORA non si assegnerà `data_fine_quarantena_precauzionale` ;
   - `data_inizio_quarantena_ordinaria = data_positività` ;
   - SE presenta `data_guarigione` (oppure `data_decesso`) allora si procede come segue:
     - SE la `data_guarigione` (oppure `data_decesso`) dista dalla `data_positività` MENO del multiplo di 7 giorni più vicino all'upper whisker della distribuzione di tempo di transizione `P_G` (oppure `P_D`) allora `data_fine_quarantena_ordinaria = data_guarigione` (oppure `data_fine_quarantena_ordinaria = data_decesso`);
     - ALTRIMENTI SE la `data_guarigione` (oppure `data_decesso`) dista dalla `data_positività` PIU' del multiplo di 7 giorni più vicino all'upper whisker della distribuzione di tempo di transizione`P_G` (oppure `P_D`) E vi è almeno una `data_fine_quarantena` allora `data_fine_quarantena_ordinaria = max(data_positività < data_fine_quarantena_i < data_positività + P_G_upper_whisker)` (oppure `data_fine_quarantena` allora `data_fine_quarantena_ordinaria = max(data_positività < data_fine_quarantena_i < data_positività + P_D_upper_whisker)`);
     - ALTRIMENTI SE la `data_guarigione` (oppure `data_decesso`) dista dalla `data_positività` PIU' del multiplo di 7 giorni più vicino all'upper whisker della distribuzione di tempo di transizione `P_G` (oppure `P_D`) E NON vi è alcuna una `data_fine_quarantena` allora `data_fine_quarantena_ordinaria = data_positività + P_G_upper_whisker` (oppure `data_fine_quarantena_ordinaria = data_positività + P_D_upper_whisker`).
   - ALTRIMENTI SE NON presenta `data_guarigione` (oppure `data_decesso`) allora si procede come segue:
     - SE vi è almeno una `data_fine_quarantena` ALLORA `data_fine_quarantena_ordinaria = max(data_positività < data_fine_quarantena_i < data_positività + P_G_upper_whisker)`;
     - ALTRIMENTI SE NON vi è alcuna una `data_fine_quarantena` allora `data_fine_quarantena_ordinaria = data_positività + P_G_upper_whisker`.

2. SE presenta `data_ammissione_ordinaria` O presenta `data_ammissione_intensiva` :
   - `data_inizio_quarantena_precauzionale = max({selected_data_inizio_quarantena_i < data_positività})` ;

   - `data_fine_quarantena_precauzionale = min( {data_positività, max({ data_inizio_quarantena_precauzionale < data_fine_quarantena_i <= data_positività})} )` ;

   - SE presenta `data_fine_quarantena` E `max({data_fine_quarantena_i}) <= max({data_dimissione_x_i})`:
     - SE `data_positività = min({data_ammissione_x_i})` ALLORA non si assegneranno le date di `quarantena_ordinaria` ;
     - SE `min({data_ammissione_x_i}) > data_positività`: 
       - `data_inizio_quarantena_ordinaria = data_positività` ;
       - `data_fine_quarantena_ordinaria = min({data_ammissione_x_i})` .
     - Non consideriamo il caso in cui `data_positività > min({data_ammissione_x_i})` in quanto questa eventualità è esclusa dal punto [2.1](#2.1-Ricoveri-pre-tempone-positivo).

   - ALTRIMENTI SE presenta `data_fine_quarantena` E `max({data_fine_quarantena_i}) > max({data_dimissione_x_i})`:

     - SE `min({data_ammissione_x_i}) =  data_positività`, ALLORA non si assegneranno le date di quarantena_ordinaria;

     - ALTRIMENTI SE `min({data_ammissione_x_i}) > data_positività`: 
       - `data_inizio_quarantena_ordinaria = data_positività` ;
       - `data_fine_quarantena_ordinaria = min({date_ammissione_x})` .
     - Non consideriamo il caso in cui `data_positività > min({data_ammissione_x_i})` in quanto questa eventualità è esclusa dal punto [2.1](#2.1-Ricoveri-pre-tempone-positivo).

   - ALTRIMENTI SE non presenta `data_fine_quarantena`:

     - SE `min({data_ammissione_x_i}) = data_positività`, ALLORA non si assegneranno le date di `quarantena_ordinaria`;
     - SE `min({data_ammissione_x_i}) > data_positività`: 
       - `data_inizio_quarantena_ordinaria = data_positività`;
       - `data_fine_quarantena_ordinaria = min({date_ammissione_x_i})`.

     - Non consideriamo il caso in cui `data_positività > min({data_ammissione_x_i})` in quanto questa eventualità è esclusa dal punto [2.1](#2.1-Ricoveri-pre-tempone-positivo).

## 4. Guarigioni e Decessi

SE NON presenta alcuna `data_ammissione_x` allora si procede come segue:

- SE presenta `data_guarigione` (oppure `data_decesso`) E `data_guarigione > data_fine_quarantena_ordinaria` (oppure `data_decesso > data_fine_quarantena_ordinaria`) ALLORA si correggerà `data_guarigione = data_fine_quarantena_ordinaria` (oppure `data_decesso = data_fine_quarantena_ordinaria`);
- ALTRIMENTI SE NON presenta `data_guarigione` né `data_decesso`, ALLORA si porrà `data_guarigione = data_fine_quarantena_ordinaria`.

ALTRIMENTI SE presenta almeno una `data_ammissione_x`, si procede come segue:

- SE presenta `data_guarigione` (oppure `data_decesso`) E `data_guarigione != max({data_dimissione_x_i})` (oppure `data_decesso != max({data_dimissione_x_i})`) ALLORA si correggerà `data_guarigione = max({data_dimissione_x_i})` (oppure `data_decesso  = max({data_dimissione_x_i})`);
- ALTRIMENTI SE NON presenta `data_guarigione` né `data_decesso`, ALLORA si porrà `data_guarigione = max({data_dimissione_x_i})`.

## 5. Sequenze

Definiamo **sequenza o percorso clinico** la successione ordinata degli **eventi notevoli**:

* `IQP = inizio_quarantena_precauzionale`: inizio della quarantena precauzionale ;
* `FQP = fine_quarantena_precauzionale`: fine della quarantena precauzionale ;
* `IQO = inizio_quarantena_ordinaria `: inizio della quarantena ordinaria ;
* `IS = inizio_sintomi `: insorgenza dei sintomi;
* `P = positività `: conferma dell'esito positivo del tampone analizzato;
* `AO = amissione_ordinaria `: ammissione in ricovero ordinario ;
* `DO = dimissione_ordinaria`: dimissione da ricovero ordinario ; 
* `AI = amissione_intensiva `: ammissione in ricovero intensivo ;
* `DI = dimissione_intensiva`: dimissione da ricovero intensivo ; 
* `AR = amissione_riabilitativa `: ammissione in ricovero riabilitativo ;
* `DR = dimissione_riabilitativa`: dimissione da ricovero riabilitativo ; 
* `G = guarigione ` ;  
* `D = decesso` 

che si verificano nelle **date notevoli**:

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

Di seguito ci occupiamo di:

1. descrivere l'**algoritmo** che genera le serie temporali stratificate per età e stato clinico relative alle sequenze presenti nel line-list database gestito dal [CSI Piemonte](https://www.csipiemonte.it/en/project/piedmont-region-covid-19-platform); 
2. riportare un insieme comprensivo ma potenzialmente incompleto di **sequenze** da considerare (utile per effettuare dei check) .

### 5.1 Algoritmo 

1. Ciascun paziente ha una propria sequenza ordinata di eventi (ad esempio `(IQP,FQP,IQO,IS,P,G)`) che si sono verificati in una sequenza ordinata di date (in questo esempio`(data_IQP, data_FQP, data_IQO, data_IS, data_P, data_G)`). 
2. Per ogni data (ad esempio `data_IQO=10/03/2020`) nella sequenza ordinata di eventi (ad esempio `(IQP,FQP,IQO,IS,P,G)`) si va ad aggiungere un'osservazione alla **riga corrispondente alla data** (qui `data=data_IQO`) e alla **colonna relativa all'evento per il percorso specifico** (qui colonna `iqp_fqp_IQO_is_p_g`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di inizio quarantena ordinaria della coorte con percorso `(IQP,FQP,IQO,IS,P,G)`). 

Evitiamo di riportare anche le rappresentazioni dei datasets di esempio troncati, ovvero privi delle colonne relative a tutte le possibili permutazioni rilevanti, perché si tratterebbe di un semplice passaggio da 4 a 13 eventi notevoli rispetto a quello riportato nell'allegato precedente. 

### 5.2 Insieme di possibili sequenze

Riportiamo qui di seguito un insieme comprensivo (ma potenzialmente incompleto) di **percorsi ordinati da prendere in considerazione** (i.e. sia quelli che includono sia quelli che escludono la quarantena ordinaria e/o precauzionale, sia quelli che includono sia quelli che escludono l'insorgenza dei sintomi, sia quelli che includono sia quelli che escludono i ricoveri ordinari e/o intensivi e/o riabilitativi). La suddivisione in **casi notevoli** di questi ultimi è stata concepita per pura comodità e chiarezza espositiva, dunque senza riflettere alcuna richiesta o definizione (e.g. la presenza o meno di flag di sintomaticità per restringere il campione dei pazienti con un certo percorso plausibile).

##### Casi Asintomatici 

* `(IQO,P,G) = (inizio_quarantena_ordinaria, positività, guarigione) `: percorso plausibile per casi asintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IQO,G) = (positività, inizio_quarantena_ordinaria, guarigione) `: percorso plausibile per casi asintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,P,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, guarigione) `: percorso plausibile per casi asintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IQO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, guarigione) `: percorso plausibile per casi asintomatici a cui è stata imposta la quarantena precauzionale;

##### Casi Sintomatici, Non Ricoverati e Guariti

* `(IS,IQO,P,G) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,IS,P,G) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,P,IS,G) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IS,P,IQO,G) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IS,IQO,G) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IQO,IS,G) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,IQO,P,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,IQO,P,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,IS,P,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,P,IS,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,P,IQO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,P,IQO,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IS,IQO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IQO,IS,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;

##### Casi Sintomatici, Non Ricoverati e Deceduti

* `(IS,IQO,P,D) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,IS,P,D) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,P,IS,D) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IS,P,IQO,D) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IS,IQO,D) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IQO,IS,D) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,IQO,P,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, decesso) `: percorso plausibile per casi sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,IQO,P,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, decesso) `: percorso plausibile per casi sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,IS,P,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, decesso) `: percorso plausibile per casi sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,P,IS,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, decesso) `: percorso plausibile per casi sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,P,IQO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, decesso) `: percorso plausibile per casi sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,P,IQO,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, decesso) `: percorso plausibile per casi sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IS,IQO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, decesso) `: percorso plausibile per casi sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IQO,IS,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, decesso) `: percorso plausibile per casi sintomatici a cui è stata imposta la quarantena precauzionale;

##### Casi Sintomatici, Ricoverati Ordinari e Guariti

* `(IS,IQO,P,AO,DO,G) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,IS,P,AO,DO,G) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,P,IS,AO,DO,G) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IS,P,IQO,AO,DO,G) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IS,IQO,AO,DO,G) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IQO,IS,AO,DO,G) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,IQO,P,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,IQO,P,AO,DO,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,IS,P,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,P,IS,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,P,IQO,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,P,IQO,AO,DO,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IS,IQO,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IQO,IS,AO,DO,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;

##### Casi Sintomatici, Ricoverati Ordinari e Deceduti

* `(IS,IQO,P,AO,DO,D) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,IS,P,AO,DO,D) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,P,IS,AO,DO,D) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IS,P,IQO,AO,DO,D) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IS,IQO,AO,DO,D) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IQO,IS,AO,DO,D) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,IQO,P,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,IQO,P,AO,DO,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,IS,P,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,P,IS,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,P,IQO,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,P,IQO,AO,DO,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IS,IQO,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IQO,IS,AO,DO,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;

##### Casi Sintomatici, Ricoverati Intensivi e Guariti

* `(IS,IQO,P,AI,DI,G) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,IS,P,AI,DI,G) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,P,IS,AI,DI,G) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IS,P,IQO,AI,DI,G) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IS,IQO,AI,DI,G) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IQO,IS,AI,DI,G) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,IQO,P,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,IQO,P,AI,DI,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,IS,P,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,P,IS,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,P,IQO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,P,IQO,AI,DI,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IS,IQO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IQO,IS,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;

##### Casi Sintomatici, Ricoverati Intensivi e Deceduti

* `(IS,IQO,P,AI,DI,D) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,IS,P,AI,DI,D) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,P,IS,AI,DI,D) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IS,P,IQO,AI,DI,D) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IS,IQO,AI,DI,D) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IQO,IS,AI,DI,D) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,IQO,P,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,IQO,P,AI,DI,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,IS,P,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,P,IS,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,P,IQO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,P,IQO,AI,DI,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IS,IQO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IQO,IS,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;

##### Casi Sintomatici, Ricoverati Ordinari-Intensivi e Guariti

* `(IS,IQO,P,AO,DO,AI,DI,G) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,IS,P,AO,DO,AI,DI,G) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,P,IS,AO,DO,AI,DI,G) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IS,P,IQO,AO,DO,AI,DI,G) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IS,IQO,AO,DO,AI,DI,G) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IQO,IS,AO,DO,AI,DI,G) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,IQO,P,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,IQO,P,AO,DO,AI,DI,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,IS,P,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,P,IS,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,P,IQO,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,P,IQO,AO,DO,AI,DI,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IS,IQO,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;

##### Casi Sintomatici, Ricoverati Ordinari-Intensivi e Deceduti

* `(IS,IQO,P,AO,DO,AI,DI,D) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,IS,P,AO,DO,AI,DI,D) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,P,IS,AO,DO,AI,DI,D) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IS,P,IQO,AO,DO,AI,DI,D) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IS,IQO,AO,DO,AI,DI,D) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IQO,IS,AO,DO,AI,DI,D) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,IQO,P,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,IQO,P,AO,DO,AI,DI,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,IS,P,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,P,IS,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,P,IQO,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,P,IQO,AO,DO,AI,DI,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IS,IQO,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;

##### Casi Sintomatici, Ricoverati Ordinari-Intensivi-Riabilitativi e Guariti

* `(IS,IQO,P,AO,DO,AI,DI,AR,DR,G) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,IS,P,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,P,IS,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IS,P,IQO,AO,DO,AI,DI,AR,DR,G) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IS,IQO,AO,DO,AI,DI,AR,DR,G) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IQO,IS,AO,DO,AI,DI,AR,DR,G) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,IQO,P,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,IQO,P,AO,DO,AI,DI,AR,DR,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,IS,P,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,P,IS,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,P,IQO,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,P,IQO,AO,DO,AI,DI,AR,DR,G) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IS,IQO,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,G) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, guarigione) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;

##### Casi Sintomatici, Ricoverati Ordinari-Intensivi-Riabilitativi e Deceduti

* `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) = (inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,IS,P,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQO,P,IS,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IS,P,IQO,AO,DO,AI,DI,AR,DR,D) = (inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IS,IQO,AO,DO,AI,DI,AR,DR,D) = (positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(P,IQO,IS,AO,DO,AI,DI,AR,DR,D) = (positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per casi sintomatici a cui non è mai stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,IQO,P,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,IQO,P,AO,DO,AI,DI,AR,DR,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,IS,P,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, inizio_sintomi, positività, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IQO,P,IS,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_quarantena_ordinaria, positività, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,IS,P,IQO,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, inizio_sintomi, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IS,IQP,FQP,P,IQO,AO,DO,AI,DI,AR,DR,D) = (inizio_sintomi, inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IS,IQO,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_sintomi, inizio_quarantena_ordinaria, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;
* `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) = (inizio_quarantena_precauzionale, fine_quarantena_precauzionale, positività, inizio_quarantena_ordinaria, inizio_sintomi, ammissione_ordinaria, dimissione_ordinaria, ammissione_intensiva, dimissione_intensiva, ammissione_riabilitativa, dimissione_riabilitativa, decesso) `: percorso plausibile per sintomatici a cui è stata imposta la quarantena precauzionale;

Dunque le variabili o colonne del dataset finale (di cui riporteremo solo una porzione notevole) saranno:

*  `data`: data relativa al giorno di calendario ;
*  `età`: classe di età; 
*  `stato_clinico`: stato clinico appartenente all'insieme {"SINTOMATICO", "ASINTOMATICO"};
*  `IQO_p_g`: serie temporale stratificata per età e stato clinico dei casi asintomatici per data di inizio quarantena ordinaria della coorte con percorso `(IQO,P,G) `;
*  `iqo_P_g`: serie temporale stratificata per età e stato clinico dei casi asintomatici per data di positività della coorte con percorso `(IQO,P,G) `;
*  `iqo_p_G`: serie temporale stratificata per età e stato clinico dei casi asintomatici per data di guarigione della coorte con percorso `(IQO,P,G) `;
*  ...
*  `IS_iqo_p_g`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di inizio sintomi della coorte con percorso `(IS,IQO,P,G) `;
*  `is_IQO_p_g`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di inizio quarantena ordinaria della coorte con percorso `(IS,IQO,P,G) `;
*  `is_iqo_P_g`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di positività della coorte con percorso `(IS,IQO,P,G) `;
*  `is_iqo_p_G`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di guarigione della coorte con percorso `(IS,IQO,P,G) `;
*  ...
*  `IS_iqo_p_ao_do_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di inizio sintomi della coorte con percorso `(IS,IQO,P,AO,DO,D) `;
*  `is_IQO_p_ao_do_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di inizio quarantena ordinaria della coorte con percorso `(IS,IQO,P,AO,DO,D) `;
*  `is_iqo_P_ao_do_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di positività della coorte con percorso `(IS,IQO,P,AO,DO,D) `;
*  `is_iqo_p_AO_do_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di ammissione ordinaria della coorte con percorso `(IS,IQO,P,AO,DO,D) `;
*  `is_iqo_p_ao_DO_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di dimissione ordinaria della coorte con percorso `(IS,IQO,P,AO,DO,D) `;
*  `is_iqo_p_ao_do_D`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di decesso della coorte con percorso `(IS,IQO,P,AO,DO,D) `;
*  ...
*  `IS_iqo_p_ao_do_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di inizio sintomi della coorte con percorso `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_IQO_p_ao_do_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di inizio quarantena ordinaria della coorte con percorso `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_P_ao_do_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di positività della coorte con percorso `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_AO_do_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di ammissione ordinaria della coorte con percorso `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_DO_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di dimissione ordinaria della coorte con percorso `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_do_AI_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di ammissione intensiva della coorte con percorso `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_do_ai_DI_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di dimissione intensiva della coorte con percorso `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_do_ai_di_AR_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di ammissione riabilitativa della coorte con percorso `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_do_ai_di_ar_DR_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di dimissione riabilitativa della coorte con percorso `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  `is_iqo_p_ao_do_ai_di_ar_dr_D`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di decesso della coorte con percorso `(IS,IQO,P,AO,DO,AI,DI,AR,DR,D) `;
*  ...
*  `IQP_fqp_p_iqo_is_ao_do_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di inizio quarantena precauzionale della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_FQP_p_iqo_is_ao_do_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di fine quarantena precauzionale della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_P_iqo_is_ao_do_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di positività della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_IQO_is_ao_do_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di inizio quarantena ordinaria della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_IS_ao_do_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di inizio sintomi della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_AO_do_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di ammissione ordinaria della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_DO_ai_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di dimissione ordinaria della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_do_AI_di_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di ammissione intensiva della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_do_ai_DI_ar_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di dimissione intensiva della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_do_ai_di_AR_dr_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di ammissione riabilitativa della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_do_ai_di_ar_DR_d`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di dimissione riabilitativa della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;
*  `iqp_fqp_p_iqo_is_ao_do_ai_di_ar_dr_D`: serie temporale stratificata per età e stato clinico dei casi sintomatici per data di decesso della coorte con percorso `(IQP,FQP,P,IQO,IS,AO,DO,AI,DI,AR,DR,D) `;

## 6. Tempi di Transizione

Definiamo **tempi di transizione** gli intervalli temporali intercorsi tra eventi notevoli: 

* `T_IQP_FQP`: intervallo di tempo intercorso tra `inizio_quarantena_precauzionale` e `fine_quarantena_precauzionale` ; 
* `T_FQP_IS`: intervallo di tempo intercorso tra `fine_quarantena_precauzionale` e `inizio_sintomi` ; 
* `T_FQP_P`: intervallo di tempo intercorso tra `fine_quarantena_precauzionale` e `positività` ; 
* `T_FQP_IQO`: intervallo di tempo intercorso tra `fine_quarantena_precauzionale` e `inizio_quarantena_ordinaria` ; 
* `T_IS_P`: intervallo di tempo intercorso tra `inizio_sintomi` e `positività` ; 
* `T_IS_IQO`: intervallo di tempo intercorso tra `inizio_sintomi` e `inizio_quarantena_ordinaria` ; 
* `T_IS_AO`: intervallo di tempo intercorso tra `inizio_sintomi` e `ammissione_ordinaria` ; 
* `T_IS_AI`: intervallo di tempo intercorso tra `inizio_sintomi` e `ammissione_intensiva` ; 
* `T_IS_G`: intervallo di tempo intercorso tra `inizio_sintomi` e `guarigione` ; 
* `T_IS_D`: intervallo di tempo intercorso tra `inizio_sintomi` e `decesso` ; 
* `T_P_IS`: intervallo di tempo intercorso tra `positività` e `inizio_sintomi` ; 
* `T_P_IQO`: intervallo di tempo intercorso tra `positività` e `inizio_quarantena_ordinaria` ; 
* `T_P_AO`: intervallo di tempo intercorso tra `positività` e `ammissione_ordinaria` ; 
* `T_P_AI`: intervallo di tempo intercorso tra `positività` e `ammissione_intensiva` ; 
* `T_P_G`: intervallo di tempo intercorso tra `positività` e `guarigione` ; 
* `T_P_D`: intervallo di tempo intercorso tra `positività` e `decesso` ; 
* `T_IQO_P`: intervallo di tempo intercorso tra `inizio_quarantena_ordinaria` e `positività` ; 
* `T_IQO_IS`: intervallo di tempo intercorso tra `inizio_quarantena_ordinaria` e `inizio_sintomi` ; 
* `T_IQO_AO`: intervallo di tempo intercorso tra `inizio_quarantena_ordinaria` e `ammissione_ordinaria` ; 
* `T_IQO_AI`: intervallo di tempo intercorso tra `inizio_quarantena_ordinaria` e `ammissione_intensiva` ; 
* `T_IQO_G`: intervallo di tempo intercorso tra `inizio_quarantena_ordinaria` e `guarigione` ; 
* `T_IQO_D`: intervallo di tempo intercorso tra `inizio_quarantena_ordinaria` e `decesso` ; 
* `T_AO_DO`: intervallo di tempo intercorso tra `ammissione_ordinaria` e `dimissione_ordinaria` ; 
* `T_AO_AI`: intervallo di tempo intercorso tra `ammissione_ordinaria` e `ammissione_intensiva` ; 
* `T_AO_G`: intervallo di tempo intercorso tra `ammissione_ordinaria` e `guarigione` ; 
* `T_AO_D`: intervallo di tempo intercorso tra `ammissione_ordinaria` e `decesso` ; 
* `T_DO_AI`: intervallo di tempo intercorso tra `dimissione_ordinaria` e `ammissione_intensiva` ; 
* `T_DO_G`: intervallo di tempo intercorso tra `dimissione_ordinaria` e `guarigione` ; 
* `T_DO_D`: intervallo di tempo intercorso tra `dimissione_ordinaria` e `decesso` ; 
* `T_AI_DI`: intervallo di tempo intercorso tra `ammissione_intensiva` e `dimissione_intensiva` ; 
* `T_AI_AR`: intervallo di tempo intercorso tra `ammissione_intensiva` e `ammissione_riabilitativa` ; 
* `T_AI_G`: intervallo di tempo intercorso tra `ammissione_intensiva` e `guarigione` ; 
* `T_AI_D`: intervallo di tempo intercorso tra `ammissione_intensiva` e `decesso` ; 
* `T_DI_AR`: intervallo di tempo intercorso tra `dimissione_intensiva` e `ammissione_riabilitativa` ; 
* `T_DI_G`: intervallo di tempo intercorso tra `dimissione_intensiva` e `guarigione` ; 
* `T_DI_D`: intervallo di tempo intercorso tra `dimissione_intensiva` e `decesso` ; 
* `T_AR_DR`: intervallo di tempo intercorso tra `ammissione_riabilitativa` e `dimissione_riabilitativa` ; 
* `T_AR_G`: intervallo di tempo intercorso tra `ammissione_riabilitativa` e `guarigione` ; 
* `T_AR_D`: intervallo di tempo intercorso tra `ammissione_riabilitativa` e `decesso` ; 
* `T_DR_G`: intervallo di tempo intercorso tra `dimissione_riabilitativa` e `guarigione` ; 
* `T_DR_D`: intervallo di tempo intercorso tra `dimissione_riabilitativa` e `decesso` ; 

Il **dataset in output** sarà costituito da più tabelle, ciascuna riportante la distribuzione empirica di un tempo di transizione specifico per una classe d'età, uno stato clinico e temporalmente, con ampiezza dell'intervallo che sarà indicata con `T`, con binning giornaliero. Per ogni tupla `(T_A_B, classe_età, stato_clinico)`, la procedura è la seguente:

1. Considerare una tupla `(T_A_B, classe_età, stato_clinico)`, porre il periodo di aggregazione temporale `T` a  `T = 0 giorni` ;
2. Aumentare `T` di 1 giorno ;
3. Calcolare le distribuzioni empiriche di tempi di transizione relative a ogni intervallo di ampiezza `T` in cui il dataset viene suddiviso ;
4. Se non vi sono più NA dovuti alla privacy, salvare il dataset, passare alla prossima tupla e quindi tornare al punto 1. ;
5. Se ancora vi sono NA dovuti alla privacy, salvare il dataset e tornare al punto 2. .

Al fine di chiarire ulteriormente il funzionamento dell'**algoritmo** descritto sopra forniamo un esempio applicativo semplificato qui di seguito:

##### 6.1 Dataset di Date Notevoli in INPUT (TRONCATO)

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

##### 6.2 Dataset di Distribuzione Empirica di `T_IQO_P` per Casi Sintomatici di `70-79` Anni con `T=1` in OUTPUT (SALVATE come "Distribuzione_IQO_P_70-79_Sintomatici_1.csv")

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

##### 6.3 Dataset di Distribuzione Empirica di `T_IQO_P` per Casi Confermati di `70-79` Anni sintomatici con `T=2` in OUTPUT (SALVATE come "Distribuzione_IQO_P_70-79_Sintomatici_2.csv")

| `data_inizio` | `data_fine` | `T`  | `T_IQO_P` | `frequenza_T_IQO_P` |
| :-----------: | :---------: | :--: | :-------: | :-----------------: |
|  01-03-2020   | 02-03-2020  |  2   |     0     |          0          |
|  01-03-2020   | 02-03-2020  |  2   |     1     |          0          |
|  01-03-2020   | 02-03-2020  |  2   |     2     |          5          |
|  01-03-2020   | 02-03-2020  |  2   |     3     |          4          |
|  01-03-2020   | 02-03-2020  |  2   |     4     |          5          |
|  01-03-2020   | 02-03-2020  |  2   |     5     |          0          |

## 7. Schede di Dimissione Ospedaliera (SDO) e di Morte (SM)

### Obiettivi

- Stimare le infezioni latenti nel periodo pre-sorveglianza necessarie ad inizializzare alcune variabili e parametri dei modelli di simulazione che dovranno poi essere calibrati sulle incidenza stratificate per età e sequenza estratti come descritto nelle sezioni precedenti;
- Analisi degli eccessi di evento notevole (ammissioni, decessi, etc.) stratficato per causa anche volta a determinare eventuali casi COVID-19 mis-diagnosticati. 

### Sintesi 

I codici che riportiamo qui di seguito andrebbero utilizzati per costruire un dataset analogo alla sezione [5. Sequenze](#5-Sequenze) stratificato per età e per aggregazione di codici di causa nel periodo 2015-2020. 

Come si legge nella [sezione ministeriale sui ricoveri ospedalieri](http://www.salute.gov.it/portale/temi/p2_4.jsp?lingua=italiano&tema=Assistenza,ospedaleeterritorio&area=ricoveriOspedalieri): 

* il sistema di codifica utilizzato per le SDO è l'**ICD-9**;
* il sistema di codifica utilizzato per le SM è l'**ICD-10**.

Poiché le SM risultano disponibili soltanto fino al 2018 ci siamo trovati costretti a considerare soltanto le SDO nell'analisi descritta qui di seguito.

### Età

La classificazione d'età è la medesima descritta nella sezione [0. Età](#0-Età).

### Codici 

Al fine di selezionare i codici ICD-10 da convertire mediante il nostro pacchetto [ICD_GEMs.jl](https://github.com/JuliaHealth/ICD_GEMs.jl) nei corrispondenti codici ICD-9 rilevanti abbiamo condotto una [rapid review](https://github.com/InPhyT/SEPI-SEREMI/tree/main/References) della letteratura con un'attenzione particolare rivolta alle analisi delle schede di morte (SM) registrate in Italia. Questa revisione supporta la scelta del set di codici assegnati a complicazioni e comorbosità associate a COVID-19 che riportaimo qui di seguito. 

#### Cause Concorrenti O Precipitanti O Antecedenti

| Codici ICD-10                                                 | Descrizione                                               | Referenze                                                   |
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

#### Complicazioni 

| Codici ICD-10                     | Descrizione                                                  | Referenze                                                   |
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
