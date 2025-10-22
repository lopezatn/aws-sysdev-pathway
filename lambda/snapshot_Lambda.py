import os
import json
import datetime
import boto3

# 0) Settings via env vars:
INSTANCE_STATE = os.getenv("INSTANCE_STATE", "running")
CREATED_BY     = os.getenv("CREATED_BY", "auto-snapshot")

def utc_now_compact():
    # timezone-aware timestamp for names
    return datetime.datetime.now(datetime.UTC).strftime("%Y%m%d-%H%M")

def handler(event, context):
    ec2 = boto3.client("ec2")

    # 1) Find target instances by state
    resp = ec2.describe_instances(
        Filters=[{"Name": "instance-state-name", "Values": [INSTANCE_STATE]}]
    )
    reservations = resp.get("Reservations", [])

    # flatten reservations → instances
    instances = []
    for r in reservations:
        instances.extend(r.get("Instances", []))

    created = []   # collect results for logging/observability

    # 2) For each instance, collect attached EBS volumes and snapshot them
    for inst in instances:
        iid = inst["InstanceId"]
        mappings = inst.get("BlockDeviceMappings", [])

        for m in mappings:
            # only mappings that have EBS (skip ephemeral/NVMe-no-snapshot cases)
            if "Ebs" not in m:
                continue
            vol = m["Ebs"]["VolumeId"]

            # snapshot name: <vol>-<YYYYMMDD-HHMM>-auto
            name = f"{vol}-{utc_now_compact()}-auto"

            # 3) Create snapshot (async). Do NOT wait in Lambda.
            snap = ec2.create_snapshot(VolumeId=vol, Description=name)
            sid  = snap["SnapshotId"]

            # 4) Tag the snapshot so retention/queries can target only ours
            ec2.create_tags(
                Resources=[sid],
                Tags=[
                    {"Key": "CreatedBy",  "Value": CREATED_BY},
                    {"Key": "Name",       "Value": name},
                    {"Key": "VolumeId",   "Value": vol},
                    {"Key": "InstanceId", "Value": iid},
                ]
            )

            created.append({"snapshot_id": sid, "volume_id": vol, "instance_id": iid, "name": name})

    # 5) Structured log (goes to CloudWatch Logs)
    print(json.dumps({"created": created, "count": len(created)}))

    # Lambda response (optional)
    return {"ok": True, "created_count": len(created)}
