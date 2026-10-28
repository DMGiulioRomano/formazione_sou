I volumi sono una tecnologia che aiuta a rendere molto piu agile l'utilizzo dello spazio di archiviazione. 

Funzionano tramite un software che si chiama LVM (Logical Volume Manager) che divide lo spazio di un physical volume in unità di allocazione chiamate Physical Extent (PE) che di norma sono 1 PE = 4MiB

abbiamo:
- Physical Volume: spazio fisico gestito da LVM. Può essere un disco intero o una partizione. Una volta inizializzato ha etichetta e metadati LVM e la parte di spazio disponibile a LVM
- Voume Group: Insieme di piu PV. IN questo modo mette a disposizione uno spazio da cui creare nuove unità logiche che sono i LV.
- Logical Volume: spazio logico che l'OS usa. Per cosa si usano? per un qualsiasi scopo per cui si usano le partizioni del disco (però li puoi ridimensionare a piacimento):
	- partizionamento OS tipo per le cartelle di log
	- storage per database
	- spazio per VM o container
	- snapshot o backup a caldo
	- etc...


## Physical Volume

![[Layout di un Physical Volume LVM 1.png]]

