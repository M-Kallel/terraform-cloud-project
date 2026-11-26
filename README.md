# AWS Academy Terraform project | Windows CMD walkthrough

Run numbered steps in Command Prompt from the extracted terraform-cloud-project directory. GitHub-hosted jobs use Linux automatically. Run only one environment at a time to conserve lab credit. Deployment requires an active authorized lab. The files use Terraform 1.10.5 and AWS provider 5.100.0.

## 1. Start the lab and authenticate

Start Learner Lab, wait for AWS Details to show the current AWS CLI credentials. Check the tools:

    aws --version
    terraform version
    git --version

Install AWS CLI v2, Terraform and Git for Windows if missing. Open a new CMD after installation. Use the current lab values in these commands; never put real values in the repository, screenshots or chat.

    set "AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY"
    set "AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY"
    set "AWS_SESSION_TOKEN=YOUR_SESSION_TOKEN"
    set "AWS_DEFAULT_REGION=us-east-1"
    aws sts get-caller-identity

Keep this CMD window open. If tokens expire, refresh all three from AWS Details. If using another permitted region, change aws_region in all three terraform.tfvars.example files and the GitHub AWS_REGION variable.

## 2. Fix S3 access and bootstrap once

    aws s3 ls
    for /f "delims=" %A in ('aws sts get-caller-identity --query Account --output text') do set "ACCOUNT_ID=%A"
    set "STATE_BUCKET=cloud5-tfstate-%ACCOUNT_ID%-%AWS_DEFAULT_REGION%"
    echo %STATE_BUCKET%

Verify the account number in the name. For a NEW bucket run:

    scripts\bootstrap.cmd

The script creates the bucket in the selected region, blocks all public access, enables versioning and sets SSE-S3 encryption. It stops at the first AWS error. A blank list from aws s3 ls can be normal. AccessDenied on ListBuckets alone does not establish that access to a specific bucket was denied.

Already created your bucket earlier? Set STATE_BUCKET to its exact name, skip create, and verify:

    aws s3api head-bucket --bucket "%STATE_BUCKET%"
    aws s3api get-public-access-block --bucket "%STATE_BUCKET%"
    aws s3api get-bucket-versioning --bucket "%STATE_BUCKET%"
    aws s3api get-bucket-encryption --bucket "%STATE_BUCKET%"

If an owned bucket was only partly configured, run the missing put commands from scripts/bootstrap.cmd individually. Never run configuration changes on a shared instructor bucket without authorization. If CreateBucket is denied, ask for an authorized bucket and state prefix. Change each backend.tf key to e.g. students/YOUR_ID/dev/terraform.tfstate where required. Ask for ListBucket scoped as appropriate, GetObject/PutObject on each state, and GetObject/PutObject/DeleteObject on its .tflock. Ask the administrator to restrict the bucket to authorized roles. A supplied backend does not grant permission for the separate application bucket. If creating application buckets is prohibited, ask for an instructor-approved exception or pre-provisioned application bucket arrangement before applying. CMD uses the same lab permissions as the console.

To open the bucket page, first sign in using the Academy console link:

    start "" "https://s3.console.aws.amazon.com/s3/buckets/%STATE_BUCKET%"

## 3. Read the configuration

Each environments directory is a separate Terraform root with a separate S3 key. terraform.tfvars.example is the actual nonsecret lab configuration passed explicitly in every plan. Edit owner, region and supported instance classes there. The six shared modules implement:

    Internet -> public ALB in two AZs -> private EC2 ASG in two AZs
    App SG -> TCP 3306 -> encrypted private MySQL RDS
    Private EC2 -> NAT -> internet for package installation
    Terraform -> encrypted, versioned S3 backend with native locking

Network creates public/app/db subnets ending in 1/2, 11/12 and 21/22 respectively. Dev uses 10.20.0.0/16, test 10.21.0.0/16 and prod 10.22.0.0/16. Dev/test share one NAT across zones; prod has one per zone. Security allows public HTTP to ALB, HTTP from ALB to app, MySQL from app to RDS. No inbound SSH. The plain HTTP page serves a public demo hostname only. EC2 needs no AWS API privileges, so no instance profile is attached. IAM access for Terraform is supplied by the existing Academy session; the project creates no IAM users or roles. RDS manages the password in Secrets Manager, requiring lab support. Prod enables Multi-AZ and deletion protection. Storage creates a separate encrypted private versioned application bucket. The database is provisioned for the assignment; the hostname page does not query it.

## 4. Initialize, review, deploy dev

    set "ENV=dev"
    terraform fmt -check -recursive
    terraform -chdir=environments/%ENV% init -backend-config="bucket=%STATE_BUCKET%" -backend-config="region=%AWS_DEFAULT_REGION%"
    terraform -chdir=environments/%ENV% validate
    terraform -chdir=environments/%ENV% plan -var-file=terraform.tfvars.example -out=review.tfplan
    terraform -chdir=environments/%ENV% show review.tfplan
    terraform -chdir=environments/%ENV% apply review.tfplan
    terraform -chdir=environments/%ENV% output
    aws s3api head-object --bucket "%STATE_BUCKET%" --key dev/terraform.tfstate

Review the account, subnet ranges, capacities and paid services before apply. If migrating real existing local state, back it up securely and use init -migrate-state with the same bucket and region. If apply fails, retain the same state, correct the cause and generate a fresh plan. Never delete the state to retry.

## 5. Push to GitHub and configure CI/CD

Use a private, trusted classroom repository when permitted. Create an empty GitHub repository. From the project directory:

    git init -b main
    git add .
    git status
    git commit -m "Implement modular AWS Academy infrastructure"
    git remote add origin https://github.com/YOUR_USERNAME/terraform-cloud-project.git
    git push -u origin main

In Settings > Secrets and variables > Actions create VARIABLES AWS_REGION and STATE_BUCKET and SECRETS AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN using a fresh authorized lab session. Use this fallback only if your instructor permits GitHub-hosted deployment with lab credentials. Plan and deploy share the lab identity; GitHub approval gates this workflow but cannot reduce that role's AWS permissions. Prefer instructor-provisioned scoped roles with OIDC if available. Only trusted maintainers should be able to push branches that run credentialed PR jobs. Fork PRs cannot access these repository secrets. Refresh GitHub secrets and re-run the workflow after expiration.

Create GitHub Environments named dev, test and prod. Require reviewers on test and prod, restrict deployment branches to main, and protect main with required PR reviews and passing checks. Verify the settings actually block deployment while awaiting approval. If your plan does not support reviewer protection, arrange a supported repository with the instructor before deploying test or prod.

Create a branch, edit a harmless setting, commit, push and open a PR. Verify all three environment plans and download readable plans. Merge after review. In Actions > Terraform Academy > Run workflow select main, target test, operation apply. Open the readable-test artifact before approving the deploy job. A new plan is generated from the main commit and the approved binary is applied. Keep artifacts private; plan files may contain sensitive metadata. A stale plan requires a fresh run.

## 6. Test the deployment

For a CI-deployed test stack initialize the local root so CMD can read its remote outputs:

    set "ENV=test"
    terraform -chdir=environments/test init -backend-config="bucket=%STATE_BUCKET%" -backend-config="region=%AWS_DEFAULT_REGION%"
    terraform -chdir=environments/test output
    for /f "delims=" %A in ('terraform -chdir^=environments/test output -raw alb_url') do set "ALB_URL=%A"
    curl.exe -fsS "%ALB_URL%/health"
    for /L %i in (1,1,20) do @curl.exe -fsS "%ALB_URL%/"

If the URL variable is empty, copy alb_url from terraform output and set it manually. Allow time for Nginx setup. Confirm two distinct hostnames and two healthy targets in EC2 > Target Groups. Use this command to verify test placement:

    aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names cloud5-test-asg --query "AutoScalingGroups[0].Instances[].[InstanceId,AvailabilityZone,HealthStatus,LifecycleState]" --output table

Start continuous requests in one CMD window:

    scripts\monitor.cmd "%ALB_URL%" > docs\failover-results.txt

In the AWS Academy console, stop one verified test ASG instance. Check responses during the failure, ASG Activity, replacement ID and healthy target count. Record actual observations. For scaling, change desired_capacity from 2 to 3 in the test tfvars example, review, deploy, capture the three instances, then revert the change and redeploy. CPU scaling can independently adjust capacity.

    aws rds describe-db-instances --db-instance-identifier cloud5-test-mysql --query "DBInstances[0].[PubliclyAccessible,DBSubnetGroup.DBSubnetGroupName,Endpoint.Address]" --output table
    powershell -NoProfile -Command "Test-NetConnection 'REPLACE_WITH_RDS_ENDPOINT' -Port 3306"

Run the second command from outside the VPC without a VPN. Record the actual external result, security groups and subnet routes. For ALB 503s check target health, NAT routing, ALB-to-app port 80 and the Nginx startup log. If RDS creation fails, inspect allowed instance classes, managed password permissions and quotas. Lab service-linked role restrictions may require instructor help.

## 7. Estimate cost and destroy

In AWS Pricing Calculator choose your region and enter measured hours/usage for two EC2 instances and gp3 disks, one ALB and LCUs, NAT hours and GB, public IPv4 hours, RDS instance and storage, S3 versions/requests, Secrets Manager and transfer. Record region, date, rates, units, quantities and total. Include the extra NAT and standby database if estimating prod. Lab credit and account quotas are account-specific.

In GitHub Actions run main / test / destroy, review the deletion plan, approve and wait. Check:

    terraform -chdir=environments/test state list

For a locally created dev stack:

    terraform -chdir=environments/dev plan -destroy -var-file=terraform.tfvars.example -out=destroy.tfplan
    terraform -chdir=environments/dev show destroy.tfplan
    terraform -chdir=environments/dev apply destroy.tfplan
    terraform -chdir=environments/dev state list

Empty test application buckets including versions/delete markers if you deliberately uploaded data. Check AWS for residual NAT gateways, EIPs, RDS snapshots and EC2 volumes. Preserve the shared state bucket. Prod requires deliberately disabling deletion protection before approved teardown; verify the final snapshot name is available.

## 8. Prepare your submission

Capture the successful Actions checks and approval, VPC/subnets, healthy target group, ASG/AZ placement, private RDS, S3 backend settings, hostname page, failover log, scaling and destroy summary. Redact credentials. Give the instructor repository access. Suggested 10–15 page report: objectives (1), architecture and routing (2), modules and environment design (2), IAM and security (1–2), S3 backend and Academy constraints (1), pipeline (2), tests and screenshots (2–3), costs and conclusion (1). For the defense use seven slides covering problem, architecture, modules, state/security, pipeline, live failover, and cost/cleanup. Populate all results from your actual run.
