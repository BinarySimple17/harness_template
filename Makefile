# Makefile — все операции репозитория одной командой (см. AGENTS.md).
# ЗАПОЛНИТЬ: в таргетах dev/verify-feature/e2e впишите команды вашего проекта.
# Требуется make (в Git Bash может отсутствовать — тогда используйте команды напрямую).

SHELL := /bin/bash

.PHONY: setup dev check test verify-feature vcr session-start session-end clean-check

# Полная установка + верификация с чистого состояния
setup:
	./init.sh

# Локальный запуск dev-сервера
dev:
	@echo "ЗАПОЛНИТЬ: команда локального запуска (например: mvn spring-boot:run / npm run dev)"

# Полная верификация (единый критерий консистентности репозитория)
check:
	./init.sh

# Только тесты
test:
	./init.sh

# Верификация одной фичи с записью evidence: make verify-feature F=feat-001
verify-feature:
	bash scripts/verify-feature.sh $(F)

# VCR — доля passing среди активированных фич (WIP=1 → VCR должен быть 1.0)
vcr:
	node -e "const f=require('./feature_list.json').features||[];const a=f.filter(function(x){return x.state==='active'}).length;const p=f.filter(function(x){return x.state==='passing'}).length;const t=a+p;console.log(t===0?'VCR: no activated features yet - OK to activate the first':'VCR = '+p+'/'+t+' = '+(p/t).toFixed(2));"

# Ритуалы начала/конца сессии (см. AGENTS.md: Startup Workflow / End of Session)
session-start:
	@echo "Clock-in: 1) pwd  2) прочитать AGENTS.md  3) прочитать progress.md  4) запустить make check  5) выбрать ОДНУ фичу из feature_list.json"

session-end:
	bash scripts/clean-state-check.sh .

# Протокол чистого состояния перед коммитом; многосессионная фича:
#   bash scripts/clean-state-check.sh . feat-0XX  (фича сознательно остаётся active до финальной сессии)
clean-check:
	bash scripts/clean-state-check.sh .
