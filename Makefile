# Essential Makefile for Self-Hosted Modular Infrastructure

# Usage:
#   make create-network   # Creates the home_network if it doesn't exist

NETWORK_NAME=home_network

.PHONY: create-network
create-network:
	@if docker network inspect $(NETWORK_NAME) > /dev/null 2>&1; then \
		 echo "Network '$(NETWORK_NAME)' already exists."; \
	else \
		docker network create $(NETWORK_NAME); \
		echo "Network '$(NETWORK_NAME)' created."; \
	fi
