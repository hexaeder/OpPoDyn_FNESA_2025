# Workshop: Energiesystemdynamik mit Julia

Dieses Repository enthält Workshopmaterialien für Energiesystemdynamik mit Julia, entwickelt für das **Jahrestreffen des Forschungsnetzwerks Energiesystemanalyse** am 6.-7. Juni 2025 in Berlin.

Wenn Sie während des Workshops die Codebeispiele nachvollziehen möchten, bitten wir Sie,
die folgenden Schritte **vor dem Workshop durchzuführen**. Insbesondere geht es um die Kompilierung von Paketen, die einige Zeit dauern kann.

Bitte melden Sie sich per Mail bei uns, wenn es irgendwelche Probleme geben sollte.

## Julia 1.11 installieren

   Die empfohlene Methode zur [Installation von Julia ist JuliaUp](https://julialang.org/install/), das die Verwaltung verschiedener Julia-Versionen erleichtert:

   ```bash
   # Unter Windows in der PowerShell ausführen (Starmenu öffnen und nach "PowerShell" suchen)
   winget install --name Julia --id 9NJNWW8PVKMN -e -s msstore

   # Unter Linux/macOS:
   curl -fsSL https://install.julialang.org | sh
   ```

   Julia ist korrekt installiert, wenn sich beim Ausführen von `julia` im Terminal/Powershell ein Julia Prozess öffnet:
   ![image](https://github.com/user-attachments/assets/28f73953-7afe-4ac6-b568-953e84f3033e)

   Sollte das **nicht** der Fall sein, lesen Sie bitte den [Troubleshooting Abschnitt](Troubleshooting: Julia Installation unter Windows) weiter unten.

## Workshop-Notebook herunterladen und nötige Pakete installieren

1. **Laden Sie die neueste Notebook-Version herunter**

   Gehen Sie zur [Release-Seite](../../releases) dieses Repositories und laden Sie die neueste `notebook.zip`-Datei herunter.

2. **Entpacken Sie die ZIP-Datei** an einen Ort Ihrer Wahl

3. **Terminal/Eingabeaufforderung öffnen**

   ### Windows:
   - **Methode 1**: Rechtsklick auf die Schaltfläche "Start" und wählen Sie "Terminal" oder "Eingabeaufforderung"
   - **Methode 2**: Drücken Sie `Win + R`, geben Sie `cmd` oder `powershell` ein und drücken Sie Enter
   - **Methode 3**: Im Datei-Explorer zum entpackten Ordner navigieren, dann mit gedrückter Umschalttaste rechtsklicken und "PowerShell-Fenster hier öffnen" oder "Eingabeaufforderungsfenster hier öffnen" wählen

   ### macOS:
   - Öffnen Sie Spotlight (Cmd + Leertaste) und geben Sie "Terminal" ein, dann drücken Sie Enter
   - Oder navigieren Sie zu Programme > Dienstprogramme > Terminal

   ### Linux:
   - Üblicherweise öffnet Strg + Alt + T ein Terminal
   - Oder suchen Sie nach "Terminal" im Anwendungsmenü

4. **Zum Ordner navigieren**

   Verwenden Sie den Befehl `cd`, um zum entpackten Ordner zu navigieren:

   ```bash
   # Windows-Beispiel
   cd C:\pfad\zum\entpackten\notebook

   # macOS/Linux-Beispiel
   cd /pfad/zum/entpackten/notebook
   ```

   Tipps für Windows-Benutzer:
   - Verwenden Sie `dir`, um Dateien im aktuellen Verzeichnis aufzulisten
   - Verwenden Sie `cd ..`, um eine Ebene im Verzeichnisbaum nach oben zu gehen
   - Sie können einen Ordner in das Terminalfenster ziehen, um seinen Pfad automatisch einzufügen
   - Tab-Vervollständigung hilft bei der Navigation: Geben Sie einen Teil eines Ordnernamens ein und drücken Sie Tab

5. **Workshop-Umgebung initialisieren**

   Sobald Sie zum Ordner navigiert sind, muss die Workshop-Umgebung initialisiert werden.
   Gehen Sie unbedingt sicher, dass dieser Befehl im richtigen Ordner ausgeführt wird. Dies ist der Fall, wenn `dir` (Windows) bzw. `ls` (macOS/Linux) im Terminal die Dateien `Project.toml` und `workshop.ipynb` anzeigt.

   ```bash
   # Auf allen Plattformen
   julia --project=@. -e "using Pkg; Pkg.instantiate()"
   ```

   Dieses Kommando wird alle nötigen Julia-Pakete herunterladen und kompilieren. Das kann etwas dauern.

## Workshop-Notebook öffnen

Um am Tag des Workshops interaktiv teilzunehmen, muss Jupyter gestartet und das Notebook geöffnet werden. Navigieren Sie dafür zunächst wie oben beschrieben zum entpackten Verzeichnis.
In diesem Verzeichnis wird der Befehl

```bash
julia --project=@. -e 'using IJulia; notebook(dir=".")'
```

ausgeführt. Daraufhin sollte sich der Browser mit Jupyter öffnen. Hier kann die Datei `workshop.ipynb` ausgewählt und geöffnet werden.

## Troubleshooting: Julia Installation unter Windows

Julia sollte durch Anwender auch ohne Admin-Rechte installiert werden können.
Auf manchen gemanagten Windows Rechnern kann es dennoch zu Problem kommen.
Generell empfehlen wir, sich die [Hinweise zur Installation auf der Julia Homepage](https://julialang.org/install/) durchzulesen.
Wenn `juliaup` nicht funktioniert, können Sie alternativ versuchen eine bestimmte Version von Julia manuell zu installieren.
Gehen Sie dazu wie folgt vor:

1. Gehen Sie zur [Julia Download Page](https://julialang.org/downloads/), und laden Sie den **Installer** für das aktuelle Release 1.11.5 herunter.

** insert screenshot**

2. Starten Sie den Installer und stellen Sie sicher, dass der Haken bei "Add Julia to Path" gesetzt ist:

** insert screenshot **

3. Öffnen Sie eine **neue** PowerShell (im Startmenü nach PowerShell suchen) und
   geben Sie `julia` ein. Starten Sie gegebenenfalls Ihren PC neu. Sollte sich
   nach wie vor keine Julia-REPL öffnen, kontaktieren Sie uns bitte.
