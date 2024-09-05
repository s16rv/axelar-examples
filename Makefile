.PHONY: init setup

init:
	@echo "Running Axelar initialization script..."
	@bash axelar-local/init_axelar.sh

setup:
	@echo "Running Axelar setup script..."
	@bash axelar-local/setup.sh