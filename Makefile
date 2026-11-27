ENVS := staging production
CHARTS := agele agele-data platform-config argocd-apps
KUBE_VERSION := 1.34.0
OUT := .render

.PHONY: check lint render kubeconform terraform

check: lint kubeconform terraform

lint:
	@for c in $(CHARTS); do \
	  helm lint --strict charts/$$c $$( [ -f charts/$$c/ci-values.yaml ] && echo -f charts/$$c/ci-values.yaml ) || exit 1; \
	done

render:
	@rm -rf $(OUT) && mkdir -p $(OUT)
	@for e in $(ENVS); do \
	  helm template agele charts/agele -n agele -f environments/$$e/agele.yaml > $(OUT)/$$e-agele.yaml && \
	  helm template agele-data charts/agele-data -n agele -f environments/$$e/agele-data.yaml > $(OUT)/$$e-agele-data.yaml && \
	  helm template platform-config charts/platform-config -f environments/$$e/platform-config.yaml > $(OUT)/$$e-platform-config.yaml && \
	  helm template root charts/argocd-apps --set environment=$$e > $(OUT)/$$e-argocd-apps.yaml || exit 1; \
	done

kubeconform: render
	kubeconform -strict -summary -kubernetes-version $(KUBE_VERSION) \
	  -schema-location default \
	  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
	  $(OUT)/*.yaml bootstrap/*.yaml

terraform:
	terraform fmt -check -recursive terraform
	@for d in terraform/global terraform/envs/staging terraform/envs/production; do \
	  (cd $$d && terraform init -backend=false -input=false >/dev/null && terraform validate) || exit 1; \
	done
