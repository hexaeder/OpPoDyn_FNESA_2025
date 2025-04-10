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

3. **Navigate to the extracted folder** in your terminal/command prompt

4. **Start Julia and instantiate the environment**

   ```bash
   cd path/to/extracted/notebook
   julia --project=.
   ```

   In the Julia REPL, run:
   ```julia
   using Pkg
   Pkg.instantiate()
   ```

5. **Start the Jupyter notebook**

   To open the Jupyter notebook, start a new julia process in the `notebook` directory and execute the following commands:
   ```julia
   using IJulia
   notebook(dir=".")
   ```

6. **Open the workshop notebook**
   
   In the Jupyter browser interface that opens, click on `workshop.ipynb` to start the workshop.
