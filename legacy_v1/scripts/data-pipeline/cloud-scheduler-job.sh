gcloud scheduler jobs create http load-data-job \
    --schedule="0 0 * * *" \
    --uri="https://REGION-PROJECT_ID.cloudfunctions.net/load_data" \
    --http-method=GET
