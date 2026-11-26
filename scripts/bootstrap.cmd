@echo off
setlocal
if not defined AWS_DEFAULT_REGION set "AWS_DEFAULT_REGION=us-east-1"
if not defined STATE_BUCKET (
 echo Set STATE_BUCKET to your unique backend bucket name first.
 exit /b 1
)
aws sts get-caller-identity || exit /b 1
if /i "%AWS_DEFAULT_REGION%"=="us-east-1" (
 aws s3api create-bucket --bucket "%STATE_BUCKET%" --region us-east-1 || exit /b 1
) else (
 aws s3api create-bucket --bucket "%STATE_BUCKET%" --region "%AWS_DEFAULT_REGION%" --create-bucket-configuration LocationConstraint=%AWS_DEFAULT_REGION% || exit /b 1
)
aws s3api put-public-access-block --bucket "%STATE_BUCKET%" --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" || exit /b 1
aws s3api put-bucket-versioning --bucket "%STATE_BUCKET%" --versioning-configuration Status=Enabled || exit /b 1
aws s3api put-bucket-encryption --bucket "%STATE_BUCKET%" --server-side-encryption-configuration file://scripts/encryption.json || exit /b 1
aws s3api get-bucket-versioning --bucket "%STATE_BUCKET%" || exit /b 1
aws s3api get-public-access-block --bucket "%STATE_BUCKET%" || exit /b 1
aws s3api get-bucket-encryption --bucket "%STATE_BUCKET%" || exit /b 1
