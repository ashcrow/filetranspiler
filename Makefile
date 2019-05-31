.PHONY: help
help:
	@echo "Targets"
	@echo "- help: The thing you are reading right now"
	@echo "- test: Run basic testing"

.PHONY: test
test:
	./test/test.sh
