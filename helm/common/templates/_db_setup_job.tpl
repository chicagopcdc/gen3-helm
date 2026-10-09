# DB Setup ServiceAccount
# Needs to update/ create secrets to signal that db is ready for use.
{{- define "common.db_setup_sa" -}}
{{- $ctx := . -}}
{{- if and (kindIs "map" .) (hasKey . "root") -}}
{{- $ctx = .root -}}
{{- end -}}
{{- $chartName := $ctx.Chart.Name -}}
{{- if and (kindIs "map" .) (hasKey . "chartNameOverride") .chartNameOverride -}}
{{- $chartName = .chartNameOverride -}}
{{- end -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $chartName }}-dbcreate-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $chartName }}-dbcreate-role
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["*"]
{{- if and $ctx.Values.global.externalSecrets.deploy (or $ctx.Values.global.externalSecrets.pushSecret $ctx.Values.externalSecrets.pushSecret) }}
- apiGroups: ["external-secrets.io"]
  resources: ["pushsecrets"]
  verbs: ["get", "list", "create", "patch", "update", "delete"]
{{- end }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ $chartName }}-dbcreate-rolebinding
subjects:
- kind: ServiceAccount
  name: {{ $chartName }}-dbcreate-sa
  namespace: {{ $ctx.Release.Namespace }}
roleRef:
  kind: Role
  name: {{ $chartName }}-dbcreate-role
  apiGroup: rbac.authorization.k8s.io
{{- end }}

# DB Setup Job
{{- define "common.db_setup_job" -}}
{{- $ctx := . -}}
{{- if and (kindIs "map" .) (hasKey . "root") -}}
{{- $ctx = .root -}}
{{- end -}}
{{- $chartName := $ctx.Chart.Name -}}
{{- if and (kindIs "map" .) (hasKey . "chartNameOverride") .chartNameOverride -}}
{{- $chartName = .chartNameOverride -}}
{{- end -}}
{{- if or $ctx.Values.global.postgres.dbCreate $ctx.Values.postgres.dbCreate }}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $chartName }}-dbcreate
spec:
  template:
    metadata:
      labels:
        app: gen3job
    spec:
      serviceAccountName: {{ $chartName }}-dbcreate-sa
      {{- if $ctx.Values.podSecurityContext }}
      securityContext:
      {{- range $k, $v := $ctx.Values.podSecurityContext }}
        {{ $k }}: {{ $v  }}
      {{- end }}
      {{- end }}
      restartPolicy: Never
      containers:
      - name: db-setup
        # TODO: READ THIS IMAGE FROM GLOBAL VALUES?
        # image: '{{ .Values.global.awshelper_container_image | default "quay.io/cdis/awshelper:master" }}'
        image: '{{ $ctx.Values.global.awshelper_container_image | default "quay.io/cdis/awshelper:master" }}'
        imagePullPolicy: Always
        command: ["/bin/bash", "-c"]
        env:
          - name: PGPASSWORD
            {{- if $ctx.Values.global.dev }}
            valueFrom:
              secretKeyRef:
                name: {{ $ctx.Values.postgres.host | default (printf "%s-postgresql" $ctx.Release.Name) }}
                key: postgres-password
                optional: false
            {{- else if $ctx.Values.global.postgres.externalSecret }}
            valueFrom:
              secretKeyRef:
                name: {{ $ctx.Values.global.postgres.externalSecret }}
                key: password
                optional: false
            {{- else }}
            value: {{ $ctx.Values.global.postgres.master.password | quote }}
            {{- end }}
          - name: PGUSER
          {{- if $ctx.Values.global.postgres.externalSecret }}
            valueFrom:
              secretKeyRef:
                name: {{ $ctx.Values.global.postgres.externalSecret }}
                key: username
                optional: false
          {{- else }}
            value: {{ $ctx.Values.global.postgres.master.username | quote }}
          {{- end }}
          - name: PGPORT
          {{- if $ctx.Values.global.postgres.externalSecret }}
            valueFrom:
              secretKeyRef:
                name: {{ $ctx.Values.global.postgres.externalSecret }}
                key: port
                optional: false
          {{- else }}
            value: {{ $ctx.Values.global.postgres.master.port | quote }}
          {{- end }}
          - name: PGHOST
            {{- if $ctx.Values.global.dev }}
            value: {{ $ctx.Values.postgres.host | default (printf "%s-postgresql" $ctx.Release.Name) }}
            {{- else if $ctx.Values.global.postgres.externalSecret }}
            valueFrom:
              secretKeyRef:
                name: {{ $ctx.Values.global.postgres.externalSecret }}
                key: host
                optional: false
            {{- else }}
            value: {{ $ctx.Values.global.postgres.master.host | quote }}
            {{- end }}
          - name: SERVICE_PGUSER
            valueFrom:
              secretKeyRef:
                name: {{ $chartName }}-dbcreds
                key: username
                optional: false
          - name: SERVICE_PGDB
            valueFrom:
              secretKeyRef:
                name: {{ $chartName }}-dbcreds
                key: database
                optional: false
          - name: SERVICE_PGPASS
            valueFrom:
              secretKeyRef:
                name: {{ $chartName }}-dbcreds
                key: password
                optional: false
          - name: GEN3_HOME
            value: /home/ubuntu/cloud-automation
        args:
          - |
            #!/bin/bash
            set -e

            # source "${GEN3_HOME}/gen3/lib/utils.sh"
            # gen3_load "gen3/gen3setup"

            echo "PGHOST=$PGHOST"
            echo "PGPORT=$PGPORT"
            echo "PGUSER=$PGUSER"

            echo "SERVICE_PGDB=$SERVICE_PGDB"
            echo "SERVICE_PGUSER=$SERVICE_PGUSER"

            until pg_isready -h $PGHOST -p $PGPORT -U $SERVICE_PGUSER -d template1
            do
              >&2 echo "Postgres is unavailable - sleeping"
              sleep 5
            done
            >&2 echo "Postgres is up - executing command"

            if psql -lqt | cut -d \| -f 1 | grep -qw $SERVICE_PGDB; then
              # gen3_log_info "Database exists"
              echo "Database exists"
              PGPASSWORD=$SERVICE_PGPASS psql -d $SERVICE_PGDB -h $PGHOST -p $PGPORT -U $SERVICE_PGUSER -c "\conninfo"
              kubectl patch secret/{{ $chartName }}-dbcreds -p '{"data":{"dbcreated":"dHJ1ZQo="}}'
            else
              echo "Database does not exist — creating..."
              psql -tc "SELECT 1 FROM pg_database WHERE datname = '$SERVICE_PGDB'" | grep -q 1 || \
                psql -c "CREATE DATABASE \"$SERVICE_PGDB\";"
              psql -tc "SELECT 1 FROM pg_user WHERE usename = '$SERVICE_PGUSER'" | grep -q 1 || \
                psql -c "CREATE USER \"$SERVICE_PGUSER\" WITH PASSWORD '$SERVICE_PGPASS';"

              echo "Granting privileges to $SERVICE_PGUSER..."
              psql -c "GRANT ALL PRIVILEGES ON DATABASE \"$SERVICE_PGDB\" TO \"$SERVICE_PGUSER\";"
              psql -d $SERVICE_PGDB -c "ALTER SCHEMA public OWNER TO \"$SERVICE_PGUSER\";"
              psql -d $SERVICE_PGDB -c "GRANT ALL ON SCHEMA public TO \"$SERVICE_PGUSER\";"
              psql -d $SERVICE_PGDB -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO \"$SERVICE_PGUSER\";"
              psql -d $SERVICE_PGDB -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO \"$SERVICE_PGUSER\";"
              psql -d $SERVICE_PGDB -c "ALTER ROLE \"$SERVICE_PGUSER\" WITH LOGIN;"

              echo "Creating ltree extension..."
              psql -d $SERVICE_PGDB -c "CREATE EXTENSION IF NOT EXISTS ltree;"

              echo "Creating pgvector extension..."
              psql -d $SERVICE_PGDB -c "CREATE EXTENSION IF NOT EXISTS vector;"

              PGPASSWORD=$SERVICE_PGPASS psql -d $SERVICE_PGDB -h $PGHOST -p $PGPORT -U $SERVICE_PGUSER -c "\conninfo"
              kubectl patch secret/{{ $chartName }}-dbcreds -p '{"data":{"dbcreated":"dHJ1ZQo="}}'
            fi
{{- if and $ctx.Values.global.externalSecrets.deploy (or $ctx.Values.global.externalSecrets.pushSecret $ctx.Values.externalSecrets.pushSecret) }}

            # Create the PushSecret from within this job (instead of having helm create it as part of
            # the release) and wait until the remote secret is populated. This avoids the race condition
            # where the job completes before helm/external-secrets has created and processed the
            # PushSecret, leaving consumers with an unpopulated remote secret.
            echo "Waiting for bootstrap secret {{ $chartName }}-dbcreds-bootstrap ..."
            for i in $(seq 1 60); do
              kubectl -n {{ $ctx.Release.Namespace }} get secret {{ $chartName }}-dbcreds-bootstrap >/dev/null 2>&1 && break
              sleep 5
            done
            kubectl -n {{ $ctx.Release.Namespace }} get secret {{ $chartName }}-dbcreds-bootstrap

            # PGHOST is sourced from the Aurora master secret when
            # global.postgres.externalSecret is configured. Copy that resolved value into the
            # bootstrap secret immediately before creating the PushSecret so the hostname does
            # not need to be duplicated in Helm values or rendered into the bootstrap manifest.
            if [ -z "$PGHOST" ]; then
              echo "ERROR: PGHOST is empty; cannot populate {{ $chartName }}-dbcreds-bootstrap"
              exit 1
            fi
            BOOTSTRAP_PGHOST_B64="$(printf '%s' "$PGHOST" | base64 | tr -d '\n')"
            kubectl -n {{ $ctx.Release.Namespace }} patch secret {{ $chartName }}-dbcreds-bootstrap \
              --type merge \
              -p "{\"data\":{\"host\":\"${BOOTSTRAP_PGHOST_B64}\"}}"

            echo "Creating PushSecret {{ $chartName }}-dbcreds ..."
            # kubectl apply is idempotent: on subsequent runs the existing PushSecret is kept as-is
            # (updatePolicy is IfNotExists, so the remote secret is never overwritten).
            echo '{{ include "common.db-push-secret" . | b64enc }}' | base64 --decode | kubectl -n {{ $ctx.Release.Namespace }} apply -f -
            echo "Waiting for PushSecret to sync to the remote secret store ..."
            kubectl -n {{ $ctx.Release.Namespace }} wait --for=condition=Ready pushsecret/{{ $chartName }}-dbcreds --timeout=300s
            echo "PushSecret is Ready - remote secret has been populated"
{{- end }}
{{- end }}
{{- end }}


{{/*
Create k8s secrets for connecting to postgres
*/}}
# DB Secrets
{{- define "common.db-secret" -}}
{{- $ctx := . -}}
{{- if and (kindIs "map" .) (hasKey . "root") -}}
{{- $ctx = .root -}}
{{- end -}}
{{- $chartName := $ctx.Chart.Name -}}
{{- if and (kindIs "map" .) (hasKey . "chartNameOverride") .chartNameOverride -}}
{{- $chartName = .chartNameOverride -}}
{{- end -}}
{{- if or (not $ctx.Values.global.externalSecrets.deploy) (and $ctx.Values.global.externalSecrets.deploy $ctx.Values.global.externalSecrets.createLocalK8sSecret) }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ $chartName }}-dbcreds
data:
  {{- $existingSecret := (lookup "v1" "Secret" $ctx.Release.Namespace (printf "%s-dbcreds" $chartName)) }}
  {{- if $existingSecret }}
    database: {{ index $existingSecret.data "database" | quote }}
    username: {{ index $existingSecret.data "username" | quote }}
    port: {{ index $existingSecret.data "port" | quote }}
    password: {{ index $existingSecret.data "password" | quote }}
    host: {{ index $existingSecret.data "host" | quote }}
    {{- if index $existingSecret.data "dbcreated" }}
    dbcreated: {{ index $existingSecret.data "dbcreated" | quote }}
    {{- end }}
  {{- else }}
    database: {{ ( $ctx.Values.postgres.database | default (printf "%s_%s" $chartName $ctx.Release.Name)  ) | b64enc | quote }}
    username: {{ ( $ctx.Values.postgres.username | default (printf "%s_%s" $chartName $ctx.Release.Name)  ) | b64enc | quote }}
    port: {{ $ctx.Values.postgres.port | b64enc | quote }}
    password: {{ include "gen3.service-postgres" (dict "key" "password" "service" $chartName "context" $ctx) | b64enc | quote }}
    {{- if $ctx.Values.global.dev }}
    host: {{ ($ctx.Values.postgres.host | default (printf "%s-%s.%s" $ctx.Release.Name "postgresql" $ctx.Release.Namespace ) ) | b64enc | quote }}
    {{- else }}
    host: {{ ( $ctx.Values.postgres.host | default ( $ctx.Values.global.postgres.master.host)) | b64enc | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
  Bootstrap Secret for PushSecret to populate External Secret
*/}}
{{- define "common.secret.db.bootstrap" -}}
{{- $ctx := . -}}
{{- if and (kindIs "map" .) (hasKey . "root") -}}
{{- $ctx = .root -}}
{{- end -}}
{{- $chartName := $ctx.Chart.Name -}}
{{- if and (kindIs "map" .) (hasKey . "chartNameOverride") .chartNameOverride -}}
{{- $chartName = .chartNameOverride -}}
{{- end -}}
{{- if and $ctx.Values.global.externalSecrets.deploy (or $ctx.Values.global.externalSecrets.pushSecret $ctx.Values.externalSecrets.pushSecret) }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ $chartName }}-dbcreds-bootstrap
  labels:
    app.kubernetes.io/name: {{ $chartName }}
type: Opaque
data:
  database: {{ ( $ctx.Values.postgres.database | default (printf "%s_%s" $chartName $ctx.Release.Name)  ) | b64enc | quote}}
  username: {{ ( $ctx.Values.postgres.username | default (printf "%s_%s" $chartName $ctx.Release.Name)  ) | b64enc | quote}}
  port: {{ $ctx.Values.postgres.port | b64enc | quote }}
  password: {{ include "gen3.service-postgres" (dict "key" "password" "service" $chartName "context" $ctx) | b64enc | quote }}
  dbcreated: {{ "true" | b64enc | quote }}
{{- end }}
{{- end -}}


{{/*
  PushSecret manifest for the dbcreds bootstrap secret.
  NOTE: this is no longer rendered as a standalone helm resource. It is applied by the
  <chart>-dbcreate job (see common.db_setup_job) so that the job only completes
  after the remote secret has been populated.
*/}}
{{- define "common.db-push-secret" -}}
{{- $ctx := . -}}
{{- if and (kindIs "map" .) (hasKey . "root") -}}
{{- $ctx = .root -}}
{{- end -}}
{{- $chartName := $ctx.Chart.Name -}}
{{- if and (kindIs "map" .) (hasKey . "chartNameOverride") .chartNameOverride -}}
{{- $chartName = .chartNameOverride -}}
{{- end -}}
{{- if and $ctx.Values.global.externalSecrets.deploy (or $ctx.Values.global.externalSecrets.pushSecret $ctx.Values.externalSecrets.pushSecret) }}
apiVersion: external-secrets.io/v1alpha1
kind: PushSecret
metadata:
  name: {{ $chartName }}-dbcreds
spec:
  updatePolicy: IfNotExists
  refreshInterval: 2m
  secretStoreRefs:
    {{- if ne $ctx.Values.global.externalSecrets.clusterSecretStoreRef "" }}
    - name: {{ $ctx.Values.global.externalSecrets.clusterSecretStoreRef }}
      kind: ClusterSecretStore
    {{- else }}
    - name: {{include "common.SecretStore" $ctx}}
      kind: SecretStore
    {{- end }}
  selector:
    secret:
      name: {{ $chartName }}-dbcreds-bootstrap
  data:
    - match:
        remoteRef:
          remoteKey: {{ include "common.externalSecret.dbcreds.name" $ctx }}
{{- end }}
{{- end -}}
