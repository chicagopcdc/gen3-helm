{{/*
Expand the name of the chart.
*/}}
{{- define "metadata.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "metadata.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "metadata.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

Common labels
*/}}
{{- define "metadata.labels" -}}
{{- if .Values.commonLabels }}
    {{- with .Values.commonLabels }}
    {{- toYaml . }}
    {{- end }}
{{- else }}
  {{- (include "common.commonLabels" .)}}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "metadata.selectorLabels" -}}
{{- if .Values.selectorLabels }}
    {{- with .Values.selectorLabels }}
    {{- toYaml . }}
    {{- end }}
{{- else }}
  {{- (include "common.selectorLabels" .)}}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "metadata.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "metadata.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
 Postgres Password lookup
*/}}
{{- define "metadata.postgres.password" -}}
{{- $localpass := (lookup "v1" "Secret" "postgres" "postgres-postgresql" ) -}}
{{- if $localpass }}
{{- default (index $localpass.data "postgres-password" | b64dec) }}
{{- else }}
{{- default .Values.postgres.password }}
{{- end }}
{{- end }}

{{/*
  Metadata g3 Auto Secrets Manager Name
*/}}
{{- define "metadata-g3auto" -}}
{{- default "metadata-g3auto" .Values.externalSecrets.metadataG3auto }}
{{- end }}