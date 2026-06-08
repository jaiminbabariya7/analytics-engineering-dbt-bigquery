.PHONY: setup lint clean
setup:
	pip install google-cloud-bigquery google-cloud-storage pandas
lint:
	sqlfluff lint sql/ --dialect bigquery 2>/dev/null || echo "sqlfluff not installed - run: pip install sqlfluff"
clean:
	rm -rf __pycache__/ .pytest_cache/
