---
name: 🏗️ Infrastructure Issue
about: Report issues with AWS infrastructure, Terraform, or deployment
title: '[INFRA] '
labels: ['infrastructure', 'aws', 'terraform', 'needs-triage']
assignees: ''
---

## 🏗️ Infrastructure Issue Description
A clear and concise description of the infrastructure problem.

## 🔍 Steps to Reproduce
1. Run command: `...`
2. Expected result: `...`
3. Actual result: `...`

## ✅ Expected Behavior
A clear and concise description of what you expected to happen.

## ❌ Actual Behavior
A clear and concise description of what actually happened.

## 🔧 Environment Information
- **Environment**: [dev/qa/prod]
- **Terraform Version**: `terraform version`
- **AWS CLI Version**: `aws --version`
- **Node.js Version**: `node --version`
- **Operating System**: [Linux/Mac/Windows]

## 📋 Commands Executed
```bash
# Paste the exact commands you ran
./scripts/build.sh plan dev
# ... other commands
```

## 📄 Error Messages
```
# Paste the exact error messages here
```

## 🔍 Troubleshooting Steps Taken
- [ ] Verified AWS credentials are configured
- [ ] Checked Terraform state files
- [ ] Validated Terraform configuration
- [ ] Checked AWS service limits
- [ ] Verified IAM permissions
- [ ] Other: _________

## 📊 Affected Components
- [ ] Lambda Functions
- [ ] DynamoDB Tables
- [ ] API Gateway
- [ ] IAM Roles/Policies
- [ ] CloudWatch Logs
- [ ] S3 Buckets
- [ ] VPC/Networking
- [ ] Other: _________

## 🔗 Related Issues
- Links to any related issues or pull requests

## 📝 Checklist
- [ ] I have provided the exact commands and error messages
- [ ] I have checked the troubleshooting steps above
- [ ] This is not a code bug (use the bug report template instead)
- [ ] I have verified my AWS credentials and permissions