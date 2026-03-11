# EBS Snapshot Automation

This folder contains a Python script that creates EBS snapshots for all running EC2 instances.

## How it works
1. Uses `boto3` to connect to AWS through the local AWS CLI profile.
2. Finds all **running** EC2 instances.
3. For each attached **EBS volume**, creates a new snapshot and applies tags:
   - `CreatedBy=auto-snapshot`
   - `Name=<volume-id>-<timestamp>-auto`
   - `VolumeId` and `InstanceId`
4. Prints a JSON summary once completed.
