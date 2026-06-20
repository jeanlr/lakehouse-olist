import os
import boto3
from botocore.exceptions import ClientError

endpoint = os.environ["MINIO_ENDPOINT"]
access_key = os.environ["AWS_ACCESS_KEY_ID"]
secret_key = os.environ["AWS_SECRET_ACCESS_KEY"]

s3 = boto3.client(
    "s3",
    endpoint_url=endpoint,
    aws_access_key_id=access_key,
    aws_secret_access_key=secret_key,
)

buckets = [
    "lakehouse",
    "bronze",
    "silver",
    "gold",
    "landing"
]

for bucket in buckets:
    try:
        s3.head_bucket(Bucket=bucket)
        print(f"Bucket {bucket} já existe")
    except ClientError:
        s3.create_bucket(Bucket=bucket)
        print(f"Bucket {bucket} criado")