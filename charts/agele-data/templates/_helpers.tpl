{{- define "agele-data.labels" -}}
app.kubernetes.io/part-of: agele
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{- define "agele-data.redisSecret" -}}
{{- .Values.redis.auth.existingSecret | default (printf "%s-auth" .Values.redis.name) -}}
{{- end }}
