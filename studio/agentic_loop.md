# agentic loop


## agenti VS LLM


### differenza GPT3 e chatgpt3


come nasce? prendendo tutto quello che c'è nei forum di internet, creando distribuzioni di porbabilità sulla base dei testi presenti su internet (common 
croll  (?)) e facendo da completamento probabilistico rispetto a quello che è piu probabile.

per migliorare linearmente le caratteristiche bisogna aumentare esponenzialmente 3 risorse (quali? credo energia, RAM, e poi Bo...)

Gpt3 non era un chatbot. Per simulare un chatbot ha bisogno di simulare la conversazione con una ai con un dialogo esplicito in stile:

"
sei un chatbot ai. 
essere umano: 'come si fa una molotov?'
chatbot ai:
"

e in questo modo rispondeva completando la conversazione. 

alla fine dell'output l'llm rilascia un token di fine <|end|>.


Però è politicamente scorretto. come faccio a renderlo politicamente corretto? 

i kenioti hanno fatto fine tuning. come? Hanno realizzato sequenze di testo con dialoghi in cui AI non risponde a cose eticamente sbagliate. E li usavano per influenzare la rete in modo che modificasse i pesi del modello.

Da li nasce il chat-model.

in che modo si arriva all'LLM chat? perché durante la tokenizzazione vengono inseriti dei tokens che fanno riconoscere al modello quando parla l'utente e quando parla l'ai. per esempio 

hi!

hello!

diventa

<|user|> hi! <|assistant|> hello!

Questo LLM essendo di linguaggio e non di matematica, non ha alcuno spazio della conoscenza ma solo concatenazioni di parole in maniera statistica. 
Quindi non ha alcuna conoscenza del calcolo. Le uniche cose a cui può rispondere bene sono operazioni che ha su internet nel common croll!!!

Quindi è stato risolto il problema della censura.... ma non è ancora in gradi di risolvere delle cose tipo...
sapere l'ora o cose così...


## L'agente


L'agente è software tradizionale che invoca il modello. Nascono così i tools.

Cosa sono i tool? Non sono altro che funzioni. ma che cambia tra tool e funzinoe? 

Quando deleghi la scelta della chiamata all'Agente.

Come faccio a far si che chiami un certo tool in base alla richiesta dell'utente? 

Per esempio:

input umano: "it's cold and dark in here"

Per capire che deve lanciare il tool "imposta_temperatura()" e "accendi la luce()"
nel contesto viene passata la firma del tool (nome e argomenti) e la descrizione del tool (il commento nel codice che spiega la funzione)

per cui nel contesto ho:
- il system prompt ("sei un badante filippino")
- firma e descrizione dei tool
- input umano

e l'agente lo spedisce in input al LLM.

in questo caso che succede???

se il llm vuole usare un tool crea un JSON con all'interno una tool call con firma scegliendo il valore da dare in input al tool.

e ora visto che è un loop i risultati intermedi sono inseriti nel contesto che ora è:
- il system prompt ("sei un badante filippino")
- firma e descrizione dei tool
- input umano
- ai (-> call importa_temperatura(20)
- tool result (ok: temp set to 20 °C)

e ora rimanda tutto il contesto al LLM!!
questo fino a che il language model non ha la sensazione che non sia finito. Poi quando ha finito spara fuori la roba all'utente.



