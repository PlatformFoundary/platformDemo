{{/*
Expand the name of the chart.
*/}}
{{- define "socpoc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "socpoc.fullname" -}}
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
Chart label.
*/}}
{{- define "socpoc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "socpoc.labels" -}}
helm.sh/chart: {{ include "socpoc.chart" . }}
{{ include "socpoc.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "socpoc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "socpoc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Fully-qualified backend service name (used by the nginx ConfigMap for proxy_pass).
*/}}
{{- define "socpoc.backendServiceName" -}}
{{- printf "%s-backend" (include "socpoc.fullname" .) }}
{{- end }}

{{/*
Image reference helper – prepends the global registry when set.
Usage: {{ include "socpoc.image" (dict "registry" .Values.global.imageRegistry "image" .Values.frontend.image) }}
*/}}
{{- define "socpoc.image" -}}
{{- $registry := .registry | default "" }}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry .image.repository .image.tag }}
{{- else }}
{{- printf "%s:%s" .image.repository .image.tag }}
{{- end }}
{{- end }}
