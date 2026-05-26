# Run from repo root when challenge1 apply fails after terraform destroy.
# Requires AWS CLI configured for account 986314682348 (or your account).
$ErrorActionPreference = "Stop"
$Region = "us-east-1"
$SecretId = "cloudzenia/rds/wordpress"

Write-Host "=== 1. Secrets Manager (scheduled deletion) ===" -ForegroundColor Cyan
try {
  aws secretsmanager restore-secret --secret-id $SecretId --region $Region 2>$null
  Write-Host "Restored secret: $SecretId"
} catch {
  Write-Host "Restore skipped (run force-delete if still blocked):"
  Write-Host "  aws secretsmanager delete-secret --secret-id $SecretId --force-delete-without-recovery --region $Region"
}

Write-Host "`n=== 2. Stuck NAT / EIP ===" -ForegroundColor Cyan
$failedNat = aws ec2 describe-nat-gateways --region $Region `
  --filter "Name=state,Values=failed,deleting" `
  --query "NatGateways[?Tags[?Key=='Project' && Value=='cloudzenia']].NatGatewayId" `
  --output text
if ($failedNat) {
  foreach ($id in $failedNat.Split()) {
    if ($id) {
      Write-Host "Deleting NAT gateway: $id"
      aws ec2 delete-nat-gateway --nat-gateway-id $id --region $Region
    }
  }
  Write-Host "Wait ~2 minutes, then re-run terraform apply."
}

Write-Host "`n=== 3. Orphan EIPs (cloudzenia-nat-eip) ===" -ForegroundColor Cyan
aws ec2 describe-addresses --region $Region `
  --filters "Name=tag:Name,Values=cloudzenia-nat-eip-1" `
  --query "Addresses[*].[AllocationId,AssociationId,NetworkInterfaceId]" `
  --output table

Write-Host "`n=== 4. NAT state mismatch (EIP already associated) ===" -ForegroundColor Cyan
$goodNat = aws ec2 describe-nat-gateways --region $Region `
  --filter "Name=state,Values=available" `
  --query "NatGateways[?Tags[?Key=='Name' && Value=='cloudzenia-nat-1']].NatGatewayId | [0]" `
  --output text
$failedNat = aws ec2 describe-nat-gateways --region $Region `
  --filter "Name=state,Values=failed" `
  --query "NatGateways[?Tags[?Key=='Challenge' && Value=='1']].NatGatewayId | [0]" `
  --output text
if ($failedNat -and $failedNat -ne "None") {
  Write-Host "Deleting failed Challenge 1 NAT: $failedNat"
  aws ec2 delete-nat-gateway --nat-gateway-id $failedNat --region $Region
}
if ($goodNat -and $goodNat -ne "None") {
  Write-Host "Working NAT exists: $goodNat"
  Write-Host "If apply still fails, run:"
  Write-Host "  terraform state rm module.vpc.aws_nat_gateway.main[0]"
  Write-Host "  terraform import module.vpc.aws_nat_gateway.main[0] $goodNat"
}

Write-Host "`nNext: cd terraform/challenge1; terraform apply" -ForegroundColor Green
