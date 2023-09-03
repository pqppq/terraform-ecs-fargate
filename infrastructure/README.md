## init
```
terraform init -backend-config=./infrastructure-prod.config
```

## plan
```
terraform plan -var-file=./production.tfvars
```

## apply
```
terraform apply -var-file=./production.tfvars
```
