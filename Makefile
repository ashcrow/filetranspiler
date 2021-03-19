.PHONY: help
help:
	@echo "Targets"
	@echo "- help: The thing you are reading right now"
	@echo "- test: Run basic testing"
	@echo "- container: Build the container image locally with podman"

.PHONY: test
test:
	./test/test.sh

.PHONY: container
container:
	podman build . -t filetranspiler:latest