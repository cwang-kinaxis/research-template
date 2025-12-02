# Research Template
This is the research repository for a dockerized environment on the DGX


## Setup powershell environment
Set env variables and functions with command: `. .\env.ps1`
The project can be configured using different .ps1 files: 
- env.ps1: default
- env_lilly.ps1: for lilly package 
- env_reg.ps1: for regeneron package
- env_overwrite.ps1: to overwrite some env variables when needed.
- env_local.ps1: to overwrite some env variables for local testing.

These env variables are loaded in src.config.py. 

## Create uv env from backup 
- Run the powershell function `RestoreUVEnv` to restore the env from dark zone fileshare.

## Create uv env from scratch 
This project uses uv (https://github.com/astral-sh/uv) to manage the python environment. 
You can download uv at https://github.com/astral-sh/uv/releases. We also need to download python: https://github.com/astral-sh/python-build-standalone/releases/. We refer to env.ps1 for the paths where to place these files. 
- ExtractCPython, to extract cpython. 
- `uv pip install -r requirements.txt`, to create the env. 
- CompressUVEnv, to compress the env in a tar.gz file.
- ExportUVEnv, to export to public fileshare.
- BackUpUVEnv, to backup the env to dark zone fileshare. 

You can run a script using the following command:
```bash
uv run <script_name.py>
```
or 
```bash
uv run -m <module_name>
```
## Setup data package 
- In env.ps1, you can find powershell functions called: CopyDataPackage, SetDataPath, and SetSymLink which will help you to setup the data package at the right location. 

## Setup users
- Run powershell function `setAdminPassword` to set the admin password.
- Run `uv run -m src.create_user` to create the ML user with the required permissions. You still need to login as admin in the java UI and assign all filters, sites and workbooks manually.

## Import resources 
- Run `uv run -m src.import_rr_scripts` to import the maestro scripts that manage the scenarios (required). This will delete any existing script with the same name. 
- Run `uv run -m src.import_workbooks` to import the workbooks (optional). They are useful to visualize the results. This will delete any existing workbook with the same name. 
## Train end to end 
- Run `uv run -m src.train_end_to_end` to run the end to end training. This will run the commands below in sequence. 

## Create scenarios
- Run `uv run -m src.create_parent_scenario` to create the training parent scenario. This private scenario will be the parent of all the other scenarios. You need to run this only once.
- Run `uv run -m src.create_scenarios` to generate both the MPS files and the SPOE tables for each mutated scenario.

## Export/Import MPS files
- Export the MPS files to public fileshare with `uv run -m src.export_mps_files`(from dark zone)
- Import the MPS files from the public fileshare with `uv run -m src.import_mps_files` (from light zone)

## Export/Import for SPOE tables
- Export SPOE tables with `uv run -m src.export_spoe_tables` (from dark zone)
- Import SPOE tables with `uv run -m src.import_spoe_tables` (from light zone)

## Training 
- Run `uv run -m src.create_graphs` to create the training graphs, the encoders and the normalization data.
- Run `uv run -m src.train_gnn` to train the GNN.
- Run `uv run -m src.train_xgb` to train the XGBoost model.
- Run `uv run -m src.train_oracle` to train the Oracle model.

## Export training metadata
- Run `uv run -m src.export_metadata` in light zone to copy the files in the public fileshare.
- Run `uv run -m src.import_metadata` in dark zone to copy the files in the dark zone fileshare.

## SPOE Heuristic scenarios  
- Run `uv run -m src.create_spoe_heuristic_scenarios` to generate the SPOE heuristic scenarios.
## Integer relaxation scenarios
- Run `uv run -m src.create_integer_relaxation_scenarios` to generate the integer relaxation scenarios.

## Setting up Maestro 
- Move datapackage to `C:\RapidResponse\Data`
- Setup Gurobi credentials 
- Setup SPOE licenses (https://confluence.kinaxis.com/spaces/analytics/pages/123115636/SPOE+Licenses): 
    - SPOEDevelopment
    - SPOEGraphReduction
    - SupplyPlanningOptimization
    - SPOEPerformanceImprovement2024

# Setting Maestro for inference
- Run powershell function `CopyONNXDll` to copy onnxruntime.dll from dark zone fileshare to the RapidResponse bin folder.
- Make sure metadata files are available in the dark zone fileshare. Need to run `uv run -m src.import_metadata` after training. 
- Run `uv run -m src.copy_metadata` to copy the metadata files to the upload folder where Maestro can find them.
- Run `uv run -m src.upload_blobs`. This script will upload the blobs and create the SPOEModelMetadata records on the PUBLIC_ROOT_SCENARIO scenario.
- Run `uv run -m src.create_inference_parent_scenario` to create a private child scenario of PUBLIC_ROOT_SCENARIO. This scenario will inherit the SPOEModelMetadata records.
- Run `uv run -m src.print_metadata_table` to print the SPOEModelMetadata table and get the model metadata IDs.
- Run `uv run -m src.create_inference_configuration` to link SPOEModelMetadata to an inference configuration record. This will also link the inference configuration to optimization configuration. 
- Run `uv run -m src.create_inference_scenarios` to create the inference scenarios.
- Run `uv run -m src.export_spoe_tables` will export the resulting SPOE tables to the public fileshare. 
- Run `uv run -m src.threshold_analysis` to see the corresponding fixing ratio for different thresholds.
- Run `uv run -m src.compare_inference_predictions` to compare the predictions from maestro and python.

# Setup env on GCP 
GCP instances run Linux, so we need to adjust the dependencies to run the project there. You need to setup ssh access and git to be able to push the code and sync the data. 

### On GCP 
```
cd ~; mkdir git; cd git; 
git init --bare supply-optimization-machine-learning.git
```
### On Local machine
Make sure you have configured SSH access to the GCP instance. You can do this by adding an entry to your `~/.ssh/config` called `gcp-instance`. 

```
git remote add gcp gcp-instance:git/supply-optimization-machine-learning.git
```
Verify the remote was added correctly:
```
git remote -v
```
Push branches to GCP:
```
git push -u gcp master
git push -u gcp clarocca-dev # for dev branch
```

Now upload uv with 
```
uv run -m src.upload_uv_gcp
```
and the spoe tables with
```
uv run -m src.upload_tables_gcp
```
### On GCP
Clone the repo:
```
git clone ~/git/supply-optimization-machine-learning.git
```
Source the env.sh file to setup the environment variables.
```
source env_gcp.sh 
```
Setup uv: 
```
uv --version # verify uv is installed
uv venv 
uv pip install -r requirements_GCP.txt
uv run -m src.create_graphs
uv run -m src.train_gnn
```
From light zone, download the metadata with 
```
uv run -m src.download_metadata_gcp
```
