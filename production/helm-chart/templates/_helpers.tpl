{{/*
Expand the name of the chart.
*/}}
{{- define "mlops-scoring-platform.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mlops-scoring-platform.fullname" -}}
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
{{- define "mlops-scoring-platform.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mlops-scoring-platform.labels" -}}
helm.sh/chart: {{ include "mlops-scoring-platform.chart" . }}
{{ include "mlops-scoring-platform.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mlops-scoring-platform.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mlops-scoring-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mlops-scoring-platform.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mlops-scoring-platform.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "mlops-scoring-platform.image" -}}
{{- $registryName := .Values.image.registry -}}
{{- $repositoryName := .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion | default .Chart.Version -}}
{{- if $registryName -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end -}}
{{- end }}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "mlops-scoring-platform.imagePullSecrets" -}}
{{- if .Values.global }}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- else if .Values.image.pullSecrets }}
imagePullSecrets:
{{- range .Values.image.pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified postgresql name.
*/}}
{{- define "mlops-scoring-platform.postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified redis name.
*/}}
{{- define "mlops-scoring-platform.redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "redis" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified kafka name.
*/}}
{{- define "mlops-scoring-platform.kafka.fullname" -}}
{{- printf "%s-%s" .Release.Name "kafka" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified minio name.
*/}}
{{- define "mlops-scoring-platform.minio.fullname" -}}
{{- printf "%s-%s" .Release.Name "minio" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified prometheus name.
*/}}
{{- define "mlops-scoring-platform.prometheus.fullname" -}}
{{- printf "%s-%s" .Release.Name "prometheus" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified grafana name.
*/}}
{{- define "mlops-scoring-platform.grafana.fullname" -}}
{{- printf "%s-%s" .Release.Name "grafana" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified loki name.
*/}}
{{- define "mlops-scoring-platform.loki.fullname" -}}
{{- printf "%s-%s" .Release.Name "loki" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Renders a value that contains template.
Usage:
{{ include "mlops-scoring-platform.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "mlops-scoring-platform.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "mlops-scoring-platform.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "mlops-scoring-platform.validateValues.database" .) -}}
{{- $messages := append $messages (include "mlops-scoring-platform.validateValues.redis" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/*
Validate database values
*/}}
{{- define "mlops-scoring-platform.validateValues.database" -}}
{{- if and .Values.postgresql.enabled .Values.externalDatabase.host -}}
mlops-scoring-platform: database
    You cannot use both postgresql.enabled and externalDatabase.host. Please choose one.
{{- end -}}
{{- end -}}

{{/*
Validate redis values
*/}}
{{- define "mlops-scoring-platform.validateValues.redis" -}}
{{- if and .Values.redis.enabled .Values.externalRedis.host -}}
mlops-scoring-platform: redis
    You cannot use both redis.enabled and externalRedis.host. Please choose one.
{{- end -}}
{{- end -}}