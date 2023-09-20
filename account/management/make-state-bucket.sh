#!/usr/bin/env sh

BUCKET_NAME=cdg-tfstate-yoxau1
BUCKET_REGION=ca-central-1

echo Creating bucket
aws s3 mb s3://$BUCKET_NAME --region "$BUCKET_REGION"

echo Enabling versioning
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

echo Enabling encryption
aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

#echo Making bucket private
#aws s3api put-bucket-acl --bucket $BUCKET_NAME --acl private

echo Finished
