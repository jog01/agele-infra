{{- define "agele.labels" -}}
app.kubernetes.io/part-of: agele
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{- define "agele.selector" -}}
app.kubernetes.io/name: agele-{{ . }}
{{- end }}

{{- define "agele.backendImage" -}}
{{- $tag := required "image.backendTag is required" .root.Values.image.backendTag -}}
{{- printf "%s-%s:%s" .root.Values.image.backendRepository .target $tag -}}
{{- end }}

{{/* Env shared by every backend process: config, secrets, Postgres and Redis. */}}
{{- define "agele.backendEnv" -}}
- name: PG_URI
  valueFrom:
    secretKeyRef:
      name: {{ .Values.postgres.appSecret }}
      key: uri
- name: DATABASE_URL
  value: "$(PG_URI)?sslmode={{ .Values.postgres.sslmode }}"
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.redis.passwordSecret }}
      key: password
- name: REDIS_URL
  value: "redis://:$(REDIS_PASSWORD)@{{ .Values.redis.host }}:6379"
- name: CORS_ORIGINS
  value: "https://{{ .Values.domain }}"
- name: HELIUS_WEBHOOK_URL
  value: "https://api.{{ .Values.domain }}/v1/webhooks/helius"
{{- end }}

{{- define "agele.backendEnvFrom" -}}
- configMapRef:
    name: agele-config
{{- if .Values.secrets.keys }}
- secretRef:
    name: agele-secrets
{{- end }}
{{- end }}
