import google.cloud.bigquery as bigquery
import google.cloud.storage as storage
import os

def main(event, context):
    client = bigquery.Client()
    dataset_id = 'data-pipeline-bigquery-424104'
    
    tables = {
        'sales': 'gs://pip-bucket1/data/sales.csv',
        'products': 'gs://pip-bucket1/data/products.csv',
        'customers': 'gs://pip-bucket1/data/customers.csv'
    }
    
    for table, uri in tables.items():
        table_id = f"{dataset_id}.{table}"
        external_table_id = f"{dataset_id}.ext_{table}"
        
        # Create or replace external table
        external_table_query = f"""
        CREATE OR REPLACE EXTERNAL TABLE {external_table_id}
        OPTIONS (
          format = 'CSV',
          uris = ['gs://pip-bucket1/data/']
        );
        """
        client.query(external_table_query).result()
        
        # Upsert data
        upsert_query = f"""
        MERGE {table_id} T
        USING {external_table_id} S
        ON {upsert_conditions[table]}
        WHEN MATCHED THEN
          UPDATE SET {update_set[table]}
        WHEN NOT MATCHED THEN
          INSERT ({insert_columns[table]})
          VALUES ({insert_values[table]});
        """
        client.query(upsert_query).result()

upsert_conditions = {
    'sales_data': 'T.date = S.date AND T.product_id = S.product_id AND T.customer_id = S.customer_id',
    'product_info': 'T.product_id = S.product_id',
    'customer_details': 'T.customer_id = S.customer_id'
}

update_set = {
    'sales_data': 'T.quantity = S.quantity, T.total_price = S.total_price',
    'product_info': 'T.product_name = S.product_name, T.category = S.category',
    'customer_details': 'T.customer_name = S.customer_name, T.location = S.location'
}

insert_columns = {
    'sales_data': 'date, product_id, customer_id, quantity, total_price',
    'product_info': 'product_id, product_name, category',
    'customer_details': 'customer_id, customer_name, location'
}

insert_values = {
    'sales_data': 'S.date, S.product_id, S.customer_id, S.quantity, S.total_price',
    'product_info': 'S.product_id, S.product_name, S.category',
    'customer_details': 'S.customer_id, S.customer_name, S.location'
}
