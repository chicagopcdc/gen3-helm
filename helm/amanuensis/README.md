# amanuensis

![Version: 1.0.1](https://img.shields.io/badge/Version-1.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: master](https://img.shields.io/badge/AppVersion-master-informational?style=flat-square)

A Helm chart for gen3 Amanuensis

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../common | common | 0.1.28 |
| https://charts.bitnami.com/bitnami | postgresql | 11.9.13 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| AMANUENSIS_CONFIG_PUBLIC | map | `{}` | Public configuration settings for Amanuensis app |
| AWS_CREDENTIALS | map | `{"AWS_SES":{"AWS_REGION":"us-east-1","RECIPIENT":"","SENDER":""},"DATA_DELIVERY_S3_BUCKET":{"aws_access_key_id":"","aws_secret_access_key":"","bucket_name":""}}` | AWS credentials for Amanuensis app |
| AWS_CREDENTIALS.AWS_SES | map | `{"AWS_REGION":"us-east-1","RECIPIENT":"","SENDER":""}` | AWS SES settings for Amanuensis app |
| AWS_CREDENTIALS.AWS_SES.AWS_REGION | map | `"us-east-1"` | AWS S3 bucket settings for Amanuensis app |
| AWS_CREDENTIALS.AWS_SES.RECIPIENT | string | `""` | Recipient email address for Amanuensis app |
| AWS_CREDENTIALS.AWS_SES.SENDER | string | `""` | Sender email address for Amanuensis app |
| AWS_CREDENTIALS.DATA_DELIVERY_S3_BUCKET | map | `{"aws_access_key_id":"","aws_secret_access_key":"","bucket_name":""}` | Data delivery S3 bucket settings for Amanuensis app |
| AWS_CREDENTIALS.DATA_DELIVERY_S3_BUCKET.aws_access_key_id | string | `""` | AWS access key ID for accessing the S3 bucket |
| AWS_CREDENTIALS.DATA_DELIVERY_S3_BUCKET.aws_secret_access_key | string | `""` | AWS secret access key for accessing the S3 bucket |
| AWS_CREDENTIALS.DATA_DELIVERY_S3_BUCKET.bucket_name | string | `""` | Name of the S3 bucket for data delivery |
| CSL_KEY | string | `""` | CSL key for Amanuensis app |
| affinity | map | `{"podAntiAffinity":{"preferredDuringSchedulingIgnoredDuringExecution":[{"podAffinityTerm":{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["amanuensis"]}]},"topologyKey":"kubernetes.io/hostname"},"weight":100}]}}` | Affinity to use for the deployment. |
| affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution | map | `[{"podAffinityTerm":{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["amanuensis"]}]},"topologyKey":"kubernetes.io/hostname"},"weight":100}]` | Option for scheduling to be required or preferred. |
| affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0] | int | `{"podAffinityTerm":{"labelSelector":{"matchExpressions":[{"key":"app","operator":"In","values":["amanuensis"]}]},"topologyKey":"kubernetes.io/hostname"},"weight":100}` | Weight value for preferred scheduling. |
| affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0] | list | `{"key":"app","operator":"In","values":["amanuensis"]}` | Label key for match expression. |
| affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].operator | string | `"In"` | Operation type for the match expression. |
| affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].values | list | `["amanuensis"]` | Value for the match expression key. |
| affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.topologyKey | string | `"kubernetes.io/hostname"` | Value for topology key label. |
| amanuensisJobs | map | `{"clearFilterSetCronjob":false,"dataDictionaryUrl":"http://sheepdog-service/api/v0/submission/_dictionary/_all","dbMigrateJob":true,"validateFilterSetsJob":false,"validateProjectDatapointsJob":true}` | which amanuensis jobs to run |
| args | list | `["-c","python /var/www/amanuensis/yaml_merge.py /var/www/amanuensis/amanuensis-config-public.yaml /var/www/amanuensis/amanuensis-config-secret.yaml /var/www/amanuensis/amanuensis-config.yaml\nif [[ -f /amanuensis/dockerrun.bash ]]; then bash /amanuensis/dockerrun.bash; elif [[ -f /dockerrun.sh ]]; then bash /dockerrun.sh; else echo 'Error: Neither /amanuensis/dockerrun.bash nor /dockerrun.sh exists.' >&2; exit 1; fi\n"]` | Default Command and arguments to run in the container. |
| autoscaling | object | `{}` |  |
| command | list | `["/bin/bash"]` | Override the default Command to run in the container. |
| commonLabels | map | `nil` | Will completely override the commonLabels defined in the common chart's _label_setup.tpl |
| criticalService | string | `"true"` | Valid options are "true" or "false". If invalid option is set- the value will default to "false". |
| env | list | `[{"name":"GEN3_UWSGI_TIMEOUT","valueFrom":{"configMapKeyRef":{"key":"uwsgi-timeout","name":"manifest-global","optional":true}}},{"name":"AWS_STS_REGIONAL_ENDPOINTS","value":"regional"},{"name":"PYTHONPATH","value":"/var/www/amanuensis"},{"name":"GEN3_DEBUG","value":"False"},{"name":"AMANUENSIS_PUBLIC_CONFIG","valueFrom":{"configMapKeyRef":{"key":"amanuensis-config-public.yaml","name":"manifest-amanuensis","optional":true}}}]` | Environment variables to pass to the container |
| externalSecrets | map | `{"amanuensisConfig":null,"createK8sAmanuensisConfigSecret":false,"dbcreds":null,"pushSecret":false}` | External Secrets settings. |
| externalSecrets.amanuensisConfig | string | `nil` | Will override the name of the aws secrets manager secret. Default is "amanuensis-config" |
| externalSecrets.createK8sAmanuensisConfigSecret | string | `false` | Will create the Helm "amanuensis-config" secret even if Secrets Manager is enabled. This is helpful if you are wanting to use External Secrets for some, but not all secrets. |
| externalSecrets.dbcreds | string | `nil` | Will override the name of the aws secrets manager secret. Default is "Values.global.environment-.Chart.Name-creds" |
| externalSecrets.pushSecret | bool | `false` | Whether to create the database and Secrets Manager secrets via PushSecret. |
| fullnameOverride | string | `""` | Override the full name of the deployment. |
| global.autoscaling.averageCPUValue | string | `"500m"` |  |
| global.autoscaling.averageMemoryValue | string | `"500Mi"` |  |
| global.autoscaling.enabled | bool | `false` |  |
| global.autoscaling.maxReplicas | int | `10` |  |
| global.autoscaling.minReplicas | int | `1` |  |
| global.aws | map | `{"awsAccessKeyId":null,"awsSecretAccessKey":null,"enabled":false,"externalSecrets":{"enabled":false,"externalSecretAwsCreds":null},"useLocalSecret":{"enabled":false,"localSecretName":null,"localSecretNamespace":null}}` | AWS configuration |
| global.aws.awsAccessKeyId | string | `nil` | Credentials for AWS stuff. |
| global.aws.awsSecretAccessKey | string | `nil` | Credentials for AWS stuff. |
| global.aws.enabled | bool | `false` | Set to true if deploying to AWS. Controls ingress annotations. |
| global.aws.externalSecrets.enabled | bool | `false` | Whether to use External Secrets for aws config. |
| global.aws.externalSecrets.externalSecretAwsCreds | String | `nil` | Name of Secrets Manager secret. |
| global.aws.useLocalSecret | map | `{"enabled":false,"localSecretName":null,"localSecretNamespace":null}` | Local secret setting if using a pre-exising secret. |
| global.aws.useLocalSecret.enabled | bool | `false` | Set to true if you would like to use a secret that is already running on your cluster. |
| global.aws.useLocalSecret.localSecretName | string | `nil` | Name of the local secret. |
| global.aws.useLocalSecret.localSecretNamespace | string | `nil` | Namespace of the local secret. |
| global.crossplane | map | `{"accountId":123456789012,"enabled":false,"oidcProviderUrl":"oidc.eks.us-east-1.amazonaws.com/id/12345678901234567890","providerConfigName":"provider-aws","s3":{"kmsKeyId":null,"versioningEnabled":false}}` | Kubernetes configuration |
| global.crossplane.accountId | string | `123456789012` | The account ID of the AWS account. |
| global.crossplane.enabled | bool | `false` | Set to true if deploying to AWS and want to use crossplane for AWS resources. |
| global.crossplane.oidcProviderUrl | string | `"oidc.eks.us-east-1.amazonaws.com/id/12345678901234567890"` | OIDC provider URL. This is used for authentication of roles/service accounts. |
| global.crossplane.providerConfigName | string | `"provider-aws"` | The name of the crossplane provider config. |
| global.crossplane.s3.kmsKeyId | string | `nil` | The kms key id for the s3 bucket. |
| global.crossplane.s3.versioningEnabled | bool | `false` | Whether to use s3 bucket versioning. |
| global.dev | bool | `true` | Whether the deployment is for development purposes. |
| global.dictionaryUrl | string | `"https://s3.amazonaws.com/dictionary-artifacts/datadictionary/develop/schema.json"` | URL of the data dictionary. |
| global.dispatcherJobNum | int | `"10"` | Number of dispatcher jobs. |
| global.environment | string | `"default"` | Environment name. This should be the same as vpcname if you're doing an AWS deployment. Currently this is being used to share ALB's if you have multiple namespaces. Might be used other places too. |
| global.externalSecrets | map | `{"clusterSecretStoreRef":"","dbCreate":false,"deploy":false,"separateSecretStore":false}` | External Secrets settings. |
| global.externalSecrets.clusterSecretStoreRef | string | `""` | Will use a manually deployed clusterSecretStore if defined. |
| global.externalSecrets.dbCreate | bool | `false` | Will create the databases and store the creds in Kubernetes Secrets even if externalSecrets is deployed. Useful if you want to use ExternalSecrets for other secrets besides db secrets. |
| global.externalSecrets.deploy | bool | `false` | Will use ExternalSecret resources to pull secrets from Secrets Manager instead of creating them locally. Be cautious as this will override secrets you have deployed. |
| global.externalSecrets.separateSecretStore | string | `false` | Will deploy a separate External Secret Store for this service. |
| global.hostname | string | `"localhost"` | Hostname for the deployment. |
| global.kubeBucket | string | `"kube-gen3"` | S3 bucket name for Kubernetes manifest files. |
| global.logsBucket | string | `"logs-gen3"` | S3 bucket name for log files. |
| global.minAvailable | int | `1` | The minimum amount of pods that are available at all times if the PDB is deployed. |
| global.netPolicy | map | `{"enabled":false}` | Controls network policy settings |
| global.pdb | bool | `false` | If the service will be deployed with a Pod Disruption Budget. Note- you need to have more than 2 replicas for the pdb to be deployed. |
| global.portalApp | string | `"gitops"` | Portal application name. |
| global.postgres.createLocalK8sSecret | bool | `false` | Whether the database should be created. |
| global.postgres.externalSecret | string | `""` | Name of external secret. Disabled if empty |
| global.postgres.master | map | `{"host":null,"password":null,"port":"5432","username":"postgres"}` | Master credentials to postgres. This is going to be the default postgres server being used for each service, unless each service specifies their own postgres |
| global.postgres.master.host | string | `nil` | hostname of postgres server |
| global.postgres.master.password | string | `nil` | password for superuser in postgres. This is used to create or restore databases |
| global.postgres.master.port | string | `"5432"` | Port for Postgres. |
| global.postgres.master.username | string | `"postgres"` | username of superuser in postgres. This is used to create or restore databases |
| global.publicDataSets | bool | `true` | Whether public datasets are enabled. |
| global.revproxyArn | string | `"arn:aws:acm:us-east-1:123456:certificate"` | ARN of the reverse proxy certificate. |
| global.tierAccessLevel | string | `"libre"` | Access level for tiers. acceptable values for `tier_access_level` are: `libre`, `regular` and `private`. If omitted, by default common will be treated as `private` |
| global.tierAccessLimit | int | `"1000"` | Only relevant if tireAccessLevel is set to "regular". Summary charts below this limit will not appear for aggregated data. |
| global.topologySpread | map | `{"enabled":false,"maxSkew":1,"topologyKey":"topology.kubernetes.io/zone"}` | Karpenter topology spread configuration. |
| global.topologySpread.enabled | bool | `false` | Whether to enable topology spread constraints for all subcharts that support it. |
| global.topologySpread.maxSkew | int | `1` | The maxSkew to use for topology spread constraints. Defaults to 1. |
| global.topologySpread.topologyKey | string | `"topology.kubernetes.io/zone"` | The topology key to use for spreading. Defaults to "topology.kubernetes.io/zone". |
| image.pullPolicy | string | `"Always"` | When to pull the image. This value should be "Always" to ensure the latest image is used. |
| image.repository | string | `"quay.io/pcdc/amanuensis"` | The Docker image repository for the amanuensis service |
| image.tag | string | `"master"` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | Docker image pull secrets. |
| labels | map | `{"authprovider":"yes","netnolimit":"yes","public":"yes","userhelper":"yes"}` | Labels to add to the pod. |
| labels.authprovider | string | `"yes"` | Grants egress from all pods to pods labeled with authrpovider=yes. For network policy selectors. |
| labels.netnolimit | string | `"yes"` | Grants egress from pods labeled with netnolimit=yes to any IP address. Use explicit proxy and AWS APIs |
| labels.public | string | `"yes"` | Grants ingress from the revproxy service for pods labeled with public=yes |
| labels.userhelper | string | `"yes"` | Grants ingress from pods in usercode namespaces for gen3 pods labeled with userhelper=yes |
| metricsEnabled | bool | `nil` | Whether Metrics are enabled. |
| nameOverride | string | `""` | Override the name of the chart. |
| nodeSelector | map | `{}` | Node Selector for the pods |
| partOf | string | `"ProjectRequest"` | Label to help organize pods and their use. Any value is valid, but use "_" or "-" to divide words. |
| podAnnotations | map | `{}` | Annotations to add to the pod |
| podSecurityContext | map | `{"fsGroup":101}` | Security context for the pod |
| postgres | map | `{"database":null,"dbCreate":null,"dbRestore":false,"host":null,"password":null,"port":"5432","separate":false,"username":null}` | Postgres database configuration. If db does not exist in postgres cluster and dbCreate is set ot true then these databases will be created for you |
| postgres.database | string | `nil` | Database name for postgres. This is a service override, defaults to <serviceName>-<releaseName> |
| postgres.dbCreate | bool | `nil` | Whether the database should be created. Default to global.postgres.dbCreate |
| postgres.host | string | `nil` | Hostname for postgres server. This is a service override, defaults to global.postgres.host |
| postgres.password | string | `nil` | Password for Postgres. Will be autogenerated if left empty. |
| postgres.port | string | `"5432"` | Port for Postgres. |
| postgres.separate | string | `false` | Will create a Database for the individual service to help with developing it. |
| postgres.username | string | `nil` | Username for postgres. This is a service override, defaults to <serviceName>-<releaseName> |
| postgresql | map | `{"primary":{"persistence":{"enabled":false}}}` | Postgresql subchart settings if deployed separately option is set to "true". Disable persistence by default so we can spin up and down ephemeral environments |
| postgresql.primary.persistence.enabled | bool | `false` | Option to persist the dbs data. |
| release | string | `"production"` | Valid options are "production" or "dev". If invalid option is set- the value will default to "dev". |
| replicaCount | int | `1` | Number of desired replicas |
| resources | map | `{"limits":{"memory":"2Gi"},"requests":{"memory":"128Mi"}}` | Resource requests and limits for the containers in the pod |
| resources.limits | map | `{"memory":"2Gi"}` | The maximum amount of resources that the container is allowed to use |
| resources.limits.memory | string | `"2Gi"` | The maximum amount of memory the container can use |
| resources.requests | map | `{"memory":"128Mi"}` | The amount of resources that the container requests |
| resources.requests.memory | string | `"128Mi"` | The amount of memory requested |
| secrets | map | `{"awsAccessKeyId":null,"awsSecretAccessKey":null}` | Secret information for Usersync and External Secrets. |
| secrets.awsAccessKeyId | str | `nil` | AWS access key ID. Overrides global key. |
| secrets.awsSecretAccessKey | str | `nil` | AWS access key ID. Overrides global key. |
| securityContext | map | `{}` | Security context for the containers in the pod |
| selectorLabels | map | `nil` | Will completely override the selectorLabels defined in the common chart's _label_setup.tpl |
| service | map | `{"port":80,"type":"ClusterIP"}` | Kubernetes service information. |
| service.port | int | `80` | The port number that the service exposes. |
| service.type | string | `"ClusterIP"` | Type of service. Valid values are "ClusterIP", "NodePort", "LoadBalancer", "ExternalName". |
| serviceAccount | map | `{"annotations":{"eks.amazonaws.com/role-arn":null},"create":true,"name":"amanuensis-sa"}` | Service account to use or create. |
| serviceAccount.annotations | map | `{"eks.amazonaws.com/role-arn":null}` | Annotations to add to the service account. |
| serviceAccount.annotations."eks.amazonaws.com/role-arn" | string | `nil` | The Amazon Resource Name (ARN) of the role to associate with the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created. |
| serviceAccount.name | string | `"amanuensis-sa"` | The name of the service account |
| tolerations | list | `[]` | Tolerations for the pods |
| volumeMounts | list | `[{"mountPath":"/amanuensis/amanuensis/static/img/logo.svg","name":"logo-volume","readOnly":true,"subPath":"logo.svg"},{"mountPath":"/var/www/amanuensis/amanuensis-config.yaml","name":"config-volume","readOnly":true,"subPath":"amanuensis-config.yaml"},{"mountPath":"/var/www/amanuensis/yaml_merge.py","name":"yaml-merge","readOnly":true,"subPath":"yaml_merge.py"},{"mountPath":"/var/www/amanuensis/jwt_private_key.pem","name":"amanuensis-jwt-keys","readOnly":true,"subPath":"jwt_private_key.pem"}]` | Volumes to mount to the container. |
| volumes | list | `[{"configMap":{"name":"logo-config"},"name":"logo-volume"},{"name":"config-volume","secret":{"secretName":"amanuensis-config"}},{"name":"amanuensis-volume","secret":{"secretName":"amanuensis-creds"}},{"name":"amanuensis-jwt-keys","secret":{"items":[{"key":"jwt_private_key.pem","path":"jwt_private_key.pem"}],"secretName":"amanuensis-jwt-keys"}},{"configMap":{"name":"amanuensis-yaml-merge","optional":true},"name":"yaml-merge"}]` | Volumes to attach to the container. |
