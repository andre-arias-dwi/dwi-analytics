# Data Pipelines Overview

This folder contains the code and documentation for data ingestion pipelines.

## Native Transfers

Refer to [transfer_configs.md](./transfer_configs.md) for a full list of native transfers (GCS, Facebook, Google Ads, etc.).

## Python Scripts

- `sftp.py`: Downloads daily CSV from external SFTP
- `sftp_dynamic.py`: Handles dynamic config loading from secrets