# Reproducible Builds Fix

## Problem
Terraform was creating new Lambda layers and updating all Lambda functions on every CI/CD run, even when no code changes were made.

## Root Cause
The `archive_file` data source in Terraform includes file metadata (timestamps, permissions) when creating zip files. Each CI/CD run:
1. Checked out fresh code
2. Ran `npm install`, creating `node_modules` with current timestamps
3. Created zip files with these new timestamps
4. Generated different hashes even though content was identical
5. Triggered recreation of layers and updates to all Lambda functions

## Solution Implemented

### 1. Build Script Changes (`scripts/build.sh`)

Added two new functions to create reproducible zips:

- **`build_layer_zips()`**: Creates layer zips with fixed timestamps
- **`build_lambda_zips()`**: Creates Lambda function zips with fixed timestamps

Both functions:
- Set `SOURCE_DATE_EPOCH=1` for reproducible timestamps
- Use `zip -X` flag to remove extra file attributes
- Create zips in `terraform/builds/` directory
- Are called before `terraform plan` and `terraform apply`

### 2. Terraform Module Changes

#### Lambda Layer Module (`terraform/modules/lambda_layer/main.tf`)
- **Before**: Used `archive_file` data source to create zips dynamically
- **After**: Uses pre-built zips created by build script
- Hash computed with `filebase64sha256()` on pre-built zip
- Only changes when actual file content changes

#### Lambda Module (`terraform/modules/lambda/main.tf`)
- **Before**: Used `archive_file` data source to create zips dynamically
- **After**: Uses pre-built zips created by build script
- Hash computed with `filebase64sha256()` on pre-built zip
- Only changes when actual file content changes

### 3. CI/CD Workflow Integration

The existing workflow already supported this:
- Plan step: Creates zips and uploads `terraform/builds/` directory
- Deploy step: Downloads build artifacts and reuses them
- No rebuilding during apply ensures plan and apply use identical zips

## Benefits

1. **Consistency**: Plan and apply use identical zip files
2. **Efficiency**: No unnecessary layer recreations or Lambda updates
3. **Faster Deployments**: Only changed resources are updated
4. **Deterministic**: Same code always produces same hash
5. **Cost Savings**: Fewer unnecessary AWS API calls

## Testing

To test the fix locally:

```bash
# Clean and build
./scripts/build.sh clean
./scripts/build.sh plan dev

# Run again without code changes - should show no changes
./scripts/build.sh plan dev
```

## Technical Details

### Reproducible Timestamps
- `SOURCE_DATE_EPOCH=1` sets all file timestamps to January 1, 1970
- Combined with `zip -X` flag removes extended attributes
- Results in byte-identical zips for identical content

### Hash Computation
- Uses `filebase64sha256()` instead of `archive_file.output_base64sha256`
- Computes hash from pre-built zip file
- Independent of when/how zip was created

## Maintenance

- Zips are created fresh during each plan/apply
- Build artifacts uploaded/downloaded between CI/CD steps
- No manual intervention required
- Clean builds with `./scripts/build.sh clean` when needed
