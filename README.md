# Workshop: Energiesystemdynamik mit Julia

Dieses Repository enthält Workshopmaterialien für Energiesystemdynamik mit Julia, entwickelt für das **Jahrestreffen des Forschungsnetzwerks Energiesystemanalyse** am 6.-7. Juni 2025 in Berlin.

## Erste Schritte

### Voraussetzungen

1. **Julia 1.11 installieren**

   Die empfohlene Methode zur Installation von Julia ist [JuliaUp](https://julialang.org/downloads/), das die Verwaltung verschiedener Julia-Versionen erleichtert:

   ```bash
   # Unter Windows (PowerShell mit Administratorrechten):
   winget install --name Julia --id 9NJNWW8PVKMN -e -s msstore

   # Unter Linux/macOS:
   curl -fsSL https://install.julialang.org | sh
   ```

2. **IJulia in deiner globalen Umgebung installieren**

   Starte Julia und führe folgenden code aus, um `IJulia` (die Notebook-Umgebung) zu installieren:
   ```julia
   using Pkg
   Pkg.add("IJulia")
   ```

### Workshop-Notebook herunterladen und ausführen

1. **Lade die neueste Notebook-Version herunter**
   
   Gehe zur [Release-Seite](../../releases) dieses Repositories und lade die neueste `notebook.zip`-Datei herunter.

2. **Entpacke die ZIP-Datei** 📦 an einen Ort deiner Wahl

3. **Terminal/Eingabeaufforderung öffnen**

   #### Windows:
   - **Methode 1**: Rechtsklick auf die Schaltfläche Start und wähle "Windows Terminal" oder "Eingabeaufforderung"
   - **Methode 2**: Drücke `Win + R`, gib `cmd` oder `powershell` ein und drücke Enter
   - **Methode 3**: Im Datei-Explorer zum entpackten Ordner navigieren, dann mit gedrückter Umschalttaste rechtsklicken und "PowerShell-Fenster hier öffnen" oder "Eingabeaufforderungsfenster hier öffnen" wählen
   
   #### macOS:
   - Öffne Spotlight (Cmd + Leertaste) und gib "Terminal" ein, dann drücke Enter
   - Oder navigiere zu Programme > Dienstprogramme > Terminal

   #### Linux:
   - Üblicherweise öffnet Strg + Alt + T ein Terminal
   - Oder suche nach "Terminal" im Anwendungsmenü

4. **Zum Ordner navigieren**

   Verwende den Befehl `cd`, um zum entpackten Ordner zu navigieren:

   ```bash
   # Windows-Beispiel
   cd C:\pfad\zum\entpackten\notebook
   
   # macOS/Linux-Beispiel
   cd /pfad/zum/entpackten/notebook
   ```

   Tipps für Windows-Benutzer:
   - Verwende `dir`, um Dateien im aktuellen Verzeichnis aufzulisten
   - Verwende `cd ..`, um eine Ebene im Verzeichnisbaum nach oben zu gehen
   - Du kannst einen Ordner in das Terminalfenster ziehen, um seinen Pfad automatisch einzufügen
   - Tab-Vervollständigung hilft bei der Navigation: Gib einen Teil eines Ordnernamens ein und drücke Tab

5. **Julia starten**

   Sobald du zum Ordner navigiert bist:

   ```bash
   # Auf allen Plattformen
   julia --project=@.
   ```

6. **Umgebung initialisieren**

   In der Julia-REPL (die wie `julia>` aussieht), führe aus:
   ```julia
   using Pkg
   Pkg.instantiate()
   ```

7. **Jupyter-Notebook starten**

   In derselben Julia-Sitzung:
   ```julia
   using IJulia
   notebook(dir=".")
   ```

   Dies öffnet deinen Standardbrowser mit der Jupyter-Oberfläche.

8. **Workshop-Notebook öffnen**
   
   In der Jupyter-Browseroberfläche klickst du auf `workshop.ipynb`, um den Workshop zu starten.
