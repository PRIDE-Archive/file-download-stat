# ------------ Define variables ------------

# Conda environment name
CONDA_ENV_NAME=file_download_stat

# Load variables from .env file if it exists
-include .env
export $(shell sed 's/=.*//' .env 2>/dev/null)

# ------------ setting up variables ------------
PARAMS_FILE=params/$(RESOURCE_NAME)-$(PROFILE)-params.yml
CONDA_ENV_LIST := $(shell conda env list | grep $(CONDA_ENV_NAME))

# ------------------------------------------------
.PHONY: all check_conda check_env create_env check_packages check_log_copy_path check_params check_mamba check_working_dir install setup clean uninstall

all: check_conda check_env check_packages check_log_copy_path check_params check_working_dir

install: setup check_conda check_env check_packages check_log_copy_path check_params check_working_dir
	@echo "✅ Installation completed successfully!"

setup:
	@echo "🔍 Checking if required variables are set..."
	@bash -c ' \
		if [ -z "$(LOGS_DESTINATION_ROOT)" ]; then \
			read -p "Enter LOGS_DESTINATION_ROOT: " LOGS_DESTINATION_ROOT; \
			echo "LOGS_DESTINATION_ROOT=$$LOGS_DESTINATION_ROOT" >> .env; \
		fi; \
		if [ -z "$(RESOURCE_NAME)" ]; then \
			read -p "Enter RESOURCE_NAME (pride, ena, etc): " RESOURCE_NAME; \
			echo "RESOURCE_NAME=$$RESOURCE_NAME" >> .env; \
		fi; \
		if [ -z "$(PROFILE)" ]; then \
			read -p "Enter PROFILE (eg: local, ebislurm): " PROFILE; \
			echo "PROFILE=$$PROFILE" >> .env; \
		fi; \
		if [ -z "$(WORKING_DIR)" ]; then \
			read -p "Enter WORKING_DIR: " WORKING_DIR; \
			echo "WORKING_DIR=$$WORKING_DIR" >> .env; \
		fi; \
		echo "✅ Setup completed. Variables saved in .env."; \
	'
check_conda:
	@echo "🔍 Checking Conda installation..."
	@if ! command -v conda > /dev/null 2>&1; then \
		echo "❌ Conda not found. Please install Miniconda or Anaconda and try again."; \
		exit 1; \
	fi
	@echo "✅ Conda is installed."


# Target to install mamba if it's not installed
check_mamba:
	@echo "🔍 Checking if mamba is installed..."
	@if ! command -v mamba > /dev/null 2>&1; then \
		echo "❌ Mamba not found. Installing mamba..."; \
		conda install mamba -c conda-forge -y || { \
			echo "❌ Failed to install mamba. Please install it manually."; \
			exit 1; \
		}; \
		echo "✅ Mamba installed successfully."; \
	else \
		echo "✅ Mamba is already installed."; \
	fi

check_env:
	@echo "🔍 Checking Conda environment '$(CONDA_ENV_NAME)'..."
	@if [ -z "$(CONDA_ENV_LIST)" ]; then \
		read -p "⚠️ Conda environment '$(CONDA_ENV_NAME)' not found. Install it? (y/n): " CONFIRM; \
		if [ "$$CONFIRM" = "y" ]; then \
			$(MAKE) create_env; \
		else \
			echo "⏩ Skipping Conda environment setup."; \
		fi; \
	else \
		echo "✅ Conda environment '$(CONDA_ENV_NAME)' already exists."; \
	fi

create_env:
	@echo "Creating Conda environment $(CONDA_ENV_NAME)..."
	@read -p "⚠️ File path where you want to install conda environment: " ENV_FOLDER; \
	if [ "$$ENV_FOLDER" ]; then \
		mamba env create -f environment.yml -p $$ENV_FOLDER --debug || { echo "Failed to create Conda environment."; exit 1; }; \
		echo "✅ Conda environment '$(CONDA_ENV_NAME)' created in '$$ENV_FOLDER' successfully."; \
	else \
		echo "⏩ Skipping Conda environment setup."; \
	fi

check_packages:
	@echo "⚠️ TODO: Conda packages check: Upcoming feature!!!."

check_log_copy_path:
	@echo "🔍 Checking LOGS_DESTINATION_ROOT: $(LOGS_DESTINATION_ROOT)"
	@if [ ! -d "$(LOGS_DESTINATION_ROOT)" ]; then \
		read -p "⚠️ LOGS_DESTINATION_ROOT '$(LOGS_DESTINATION_ROOT)' does not exist. Create it? (y/n): " CONFIRM; \
		if [ "$$CONFIRM" = "y" ]; then \
			mkdir -p $(LOGS_DESTINATION_ROOT)/fasp-aspera/public/; \
			mkdir -p $(LOGS_DESTINATION_ROOT)/ftp/public/; \
			mkdir -p $(LOGS_DESTINATION_ROOT)/gridftp-globus/public/; \
			mkdir -p $(LOGS_DESTINATION_ROOT)/http/public/; \
			echo "✅ Created LOGS_DESTINATION_ROOT: $(LOGS_DESTINATION_ROOT)"; \
		else \
			echo "⏩ Skipping LOGS_DESTINATION_ROOT creation."; \
		fi; \
	else \
		echo "✅ LOGS_DESTINATION_ROOT exists."; \
	fi

check_params:
	@echo "🔍 Checking for params file: $(PARAMS_FILE)"
	@if [ ! -f "$(PARAMS_FILE)" ]; then \
		echo "⚠️ WARNING: Params file '$(PARAMS_FILE)' is missing!"; \
	else \
		echo "✅ Params file found."; \
	fi


check_working_dir:
	@echo "🔍 Checking working directory: $(WORKING_DIR)"
	@if [ ! -d "$(WORKING_DIR)" ]; then \
		read -p "⚠️ WORKING_DIR '$(WORKING_DIR)' does not exist. Create it? (y/n): " CONFIRM; \
		if [ "$$CONFIRM" = "y" ]; then \
			mkdir -p $(WORKING_DIR); \
			echo "✅ Created working directory: $(WORKING_DIR)"; \
		else \
			echo "⏩ Skipping working directory creation."; \
		fi; \
	else \
		echo "✅ working directory exists."; \
	fi


clean:
	@echo "🗑️  Cleaning up..."
	@read -p "⚠️ Do you want to remove '$(WORKING_DIR)'? (y/n): " CONFIRM; \
	if [ "$$CONFIRM" = "y" ]; then \
		rm -rf $(WORKING_DIR); \
		echo "✅ Working directory deleted: $(WORKING_DIR)"; \
	else \
		echo "⏩ Skipping working directory deletion."; \
	fi; \
	echo "✅ Cleanup complete."


uninstall:
	@echo "❌ Uninstalling everything..."
	@read -p "⚠️ Do you want to remove conda environment'$(CONDA_ENV_NAME)'? (y/n): " CONFIRM; \
	if [ "$$CONFIRM" = "y" ]; then \
		conda remove -n $(CONDA_ENV_NAME) --all -y; \
		echo "✅ CONDA_ENV_NAME deleted: $(CONDA_ENV_NAME)"; \
	else \
		echo "⏩ Skipping CONDA_ENV_NAME deletion."; \
	fi;
	@read -p "⚠️ Do you want to remove '$(WORKING_DIR)'? (y/n): " CONFIRM; \
	if [ "$$CONFIRM" = "y" ]; then \
		rm -rf $(WORKING_DIR); \
		echo "✅ Working directory deleted: $(WORKING_DIR)"; \
	else \
		echo "⏩ Skipping working directory deletion."; \
	fi;
	@read -p "⚠️ Do you want to remove '$(LOGS_DESTINATION_ROOT)'? (y/n): " CONFIRM; \
	if [ "$$CONFIRM" = "y" ]; then \
		rm -rf $(LOGS_DESTINATION_ROOT); \
		echo "✅ LOGS_DESTINATION_ROOT deleted: $(LOGS_DESTINATION_ROOT)"; \
	else \
		echo "⏩ Skipping LOGS_DESTINATION_ROOT deletion."; \
	fi;
	@echo "✅ Uninstall complete."

