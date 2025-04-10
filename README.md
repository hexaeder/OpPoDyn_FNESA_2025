# Workshop Companion

This repository contains workshop materials for energy system dynamics using Julia. The workshop notebook is automatically generated from template files and published as a GitHub release.

## Getting Started

### Prerequisites

1. **Install Julia 1.11**

   The recommended way to install Julia is using [JuliaUp](https://julialang.org/downloads/), which helps manage Julia versions:

   ```bash
   # On Windows (using PowerShell with admin rights):
   winget install --name Julia --id 9NJNWW8PVKMN -e -s msstore

   # On Linux/macOS:
   curl -fsSL https://install.julialang.org | sh
   ```

   After installation, you can select Julia 1.11:
   ```bash
   juliaup add 1.11
   juliaup default 1.11
   ```

2. **Install IJulia in your global environment**

   Start Julia and run:
   ```julia
   using Pkg
   Pkg.add("IJulia")
   ```

### Downloading and Running the Workshop Notebook

1. **Download the latest notebook release**
   
   Go to the [Releases page](../../releases) of this repository and download the latest `notebook.zip` file.

2. **Extract the zip file** to a location of your choice

3. **Opening a Terminal/Command Prompt**

   #### Windows:
   - **Method 1**: Right-click on the Start button and select "Windows Terminal" or "Command Prompt"
   - **Method 2**: Press `Win + R`, type `cmd` or `powershell`, and press Enter
   - **Method 3**: In File Explorer, navigate to the extracted folder, then right-click while holding Shift and select "Open PowerShell window here" or "Open command window here"
   
   #### macOS:
   - Open Spotlight (Cmd + Space) and type "Terminal", then press Enter
   - Or navigate to Applications > Utilities > Terminal

   #### Linux:
   - Usually Ctrl + Alt + T opens a terminal
   - Or search for "Terminal" in your application menu

4. **Navigating to the Folder**

   Use the `cd` command to navigate to the extracted folder:

   ```bash
   # Windows example
   cd C:\path\to\extracted\notebook
   
   # macOS/Linux example
   cd /path/to/extracted/notebook
   ```

   Tips for Windows users:
   - Use `dir` to list files in the current directory
   - Use `cd ..` to go up one level in the directory tree
   - You can drag and drop a folder into the terminal window to automatically insert its path
   - Tab completion will help you navigate: type part of a folder name and press Tab

5. **Starting Julia**

   Once you've navigated to the folder:

   ```bash
   # On all platforms
   julia --project=@.
   ```

6. **Instantiate the environment**

   In the Julia REPL (which looks like `julia>`), run:
   ```julia
   using Pkg
   Pkg.instantiate()
   ```

7. **Start the Jupyter notebook**

   In the same Julia session:
   ```julia
   using IJulia
   notebook(dir=".")
   ```

   This will open your default web browser with the Jupyter interface.

8. **Open the workshop notebook**
   
   In the Jupyter browser interface that opens, click on `workshop.ipynb` to start the workshop.
