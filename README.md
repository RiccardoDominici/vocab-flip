# Vocab Flip

Web app per imparare vocaboli inglesi partendo dall'italiano, con flip card interattive e pronuncia audio.

**[Provala live](https://vocab-flip.pages.dev)**

## Come funziona

1. **Scegli un tema** dalla home (Cibi, Animali, Vestiti, Casa, Trasporti, Corpo, Natura, Numeri)
2. **Guarda la card** con l'emoji e la parola italiana — prova a pensare alla traduzione inglese
3. **Tocca la card** per girarla e vedere la risposta
4. **Tocca di nuovo** per confermare e passare alla prossima
5. **Ascolta la pronuncia** premendo il bottone speaker sulla card girata
6. **Nuovo round** alla fine per ricaricare parole diverse

## Caratteristiche

- 8 temi con 20-30 vocaboli ciascuno (livello A1-B1)
- Animazione flip 3D sulle card
- Una sola card visibile alla volta
- Pronuncia inglese tramite Web Speech API nativa del browser
- Progress bar e contatore per ogni round
- Nessuna API esterna, nessun account richiesto
- Tutto funziona offline dopo il primo caricamento

## Stack tecnico

- **Flutter Web** (Dart) — channel stable
- **State management**: setState (niente overengineering)
- **Pronuncia**: Web Speech API (`speechSynthesis`) via `dart:js_interop`
- **Immagini**: Emoji native del sistema (zero dipendenze esterne)
- **Hosting**: Cloudflare Pages
- **CI/CD**: Deploy manuale con Wrangler CLI

## Sviluppo locale

```bash
# Clona il progetto
git clone https://github.com/RiccardoDominici/vocab-flip.git
cd vocab-flip

# Installa dipendenze
flutter pub get

# Avvia in modalita' sviluppo
flutter run -d chrome

# Build per produzione
flutter build web --release
```

## Deploy

```bash
# Deploy su Cloudflare Pages
npx wrangler pages deploy build/web --project-name=vocab-flip
```

## Struttura progetto

```
lib/
├── main.dart                 # Entry point
├── data/
│   └── vocabulary.dart       # Vocaboli statici per tutti i temi
├── screens/
│   ├── home_screen.dart      # Griglia selezione tema
│   └── game_screen.dart      # Schermata gioco con griglia card
├── widgets/
│   └── flip_card.dart        # Widget flip card con animazione 3D
└── utils/
    └── speech.dart           # Bridge Web Speech API
```
