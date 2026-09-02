# Harness Template — шаблон harness для ИИ-агентов

Шаблон собран для себя по материалам курса [walkinglabs/learn-harness-engineering](https://github.com/walkinglabs/learn-harness-engineering) (лицензия MIT) и рассчитан на то, чтобы его копировать в корень.

Ключевая идея курса: **модель решает, какой код писать; harness решает, когда, где и как она его пишет.** Harness — это среда из пяти подсистем, которая делает работу ИИ-агента воспроизводимой:

| Подсистема | Что делает | Файлы в шаблоне |
|---|---|---|
| Instructions | Правила работы, стартовый маршрут, критерий готовности | `AGENTS.md`, `CLAUDE.md` |
| State | Где живёт текущее состояние — не в чате, а в файлах | `feature_list.json`, `progress.md`, `DECISIONS.md`, `session-handoff.md` |
| Verification | Что должно реально выполниться, прежде чем считать работу сделанной | `init.sh`, `Makefile`, `scripts/verify-feature.sh` |
| Scope | Одна фича за раз, явный Definition of Done | правила в `AGENTS.md` + поля `dependencies`/`state` |
| Session Lifecycle | Ритуалы начала и конца сессии | `Startup Workflow` / `End of Session` в `AGENTS.md`, `scripts/clean-state-check.sh` |

## Структура

```
harness_template/
├── README.md                      ← этот файл
├── AGENTS.md                      ← главный файл: инструкция для агента (заполнить)
├── CLAUDE.md                      ← роутер на AGENTS.md для Claude Code (можно удалить)
├── feature_list.json              ← трекер фич: единый источник правды по состоянию
├── progress.md                    ← журнал сессий (заполняется в конце каждой сессии)
├── session-handoff.md             ← снимок для передачи крупной сессии
├── DECISIONS.md                   ← журнал решений (что решили и почему)
├── init.sh                        ← стандартный путь «установка + верификация»
├── Makefile                       ← все операции одной командой (make check и др.)
├── docs/
│   ├── README.md                  ← карта документации и приоритеты источников
│   ├── ARCHITECTURE.md            ← архитектура: компоненты, границы, инварианты
│   ├── PRODUCT.md                 ← продукт: что, зачем, для кого, non-goals
│   ├── quality-document.md        ← оценка модулей A/B/C/D по 4 измерениям
│   ├── adr/                       ← ADR: ключевые решения (реестр + шаблон ADR-TEMPLATE.md)
│   ├── api/                       ← контракт API: openapi.yaml + правила работы
│   └── diagrams/                  ← диаграммы: er-data-model.md (модель данных, ER),
│                                    c4-context.md (контекст/контейнеры), sequence-*
├── templates/
│   ├── sprint-contract.md         ← договор о скоупе перед началом фичи
│   ├── evaluator-rubric.md        ← rubric приёмки (A/B/C/D по 6 измерениям)
│   └── clean-state-checklist.md   ← чеклист чистого состояния перед коммитом
├── solution/
│   ├── README.md                  ← уровень планирования: жизненный цикл сессий
│   ├── sessions.md                ← индекс: план-сессий, владельцы, владение файлами, вехи
│   ├── FIXES.md                   ← журнал устранения противоречий канона
│   └── sessions/
│       ├── S00_session.md         ← КАНОН проекта: стек, порты, контракты стыков, запреты
│       └── TEMPLATE_session.md    ← шаблон рабочей сессии (копируется под ID)
└── scripts/
    ├── README.md                  ← ИНСТРУКЦИЯ: как запускать проверки harness
    ├── audit-harness.sh           ← проверка из курса (bash, без зависимостей)
    ├── validate-harness.mjs       ← оценка 5 подсистем 0–100 (Node.js)
    ├── lib/harness-utils.mjs      ← библиотека к validate-harness.mjs
    ├── verify-feature.sh          ← гейт: фича → passing только через верификацию
    └── clean-state-check.sh       ← автопроверка чистого состояния сессии
```

## Быстрый старт

1. **Скопируйте содержимое** этой папки в корень вашего проекта (или начните проект прямо здесь).
2. **Заполните заготовки** — ищите подсказки `<!-- ЗАПОЛНИТЬ: ... -->` в `.md`-файлах и `# ЗАПОЛНИТЬ:` в `.sh`/`Makefile`. Заголовки секций на английском **не переименовывайте**: по ним работают скрипты проверки.
3. **Проверьте harness** (подробности в [scripts/README.md](scripts/README.md)):

```bash
bash scripts/audit-harness.sh .
node scripts/validate-harness.mjs .
```

4. Дальше работайте по `AGENTS.md`: агент читает его в начале каждой сессии.

## Как заполнять по файлам

- **`AGENTS.md`** — опишите проект в первых строках, впишите реальные команды верификации и ограничения проекта (MUST/MUST NOT с пометкой `why:`).
- **`feature_list.json`** — замените фичи-заглушки. Каждая фича: `id`, `name`, `description`, `behavior` (наблюдаемое поведение), `verification` (команда-доказательство), `dependencies` (id других фич), `state` + `status`, `evidence`, `layers` (проверки по слоям с подсказкой `repair`).
  - Машина состояний: `not_started` → `active` → `passing`, перескакивать нельзя.
  - `state` — машинное поле (его используют скрипты/аудит); `status` — человекочитаемое зеркало: `not-started` / `in-progress` / `done`.
- **`init.sh`** — автодетект стека уже настроен (Maven, Gradle, npm/pnpm/yarn/bun, Python, Go, Rust, .NET). Если стек не распознался — впишите команды в ветку `else`.
- **`docs/`** — архитектурная документация: значимые решения — как ADR ([docs/adr/](docs/adr/README.md), по шаблону `ADR-TEMPLATE.md`), внешний API — spec-first через [docs/api/openapi.yaml](docs/api/openapi.yaml), данные — каноническая [ER-модель](docs/diagrams/er-data-model.md); схема/контракт меняются в том же коммите, что и миграция/код. Карта разделов — [docs/README.md](docs/README.md).
- **`solution/`** — для многосессионной разработки: заполните канон [S00_session.md](solution/sessions/S00_session.md) (стек, порты, контракты стыков, запреты), разбейте фичи на сессии в индексе [sessions.md](solution/sessions.md), исполняйте по шаблону [TEMPLATE_session.md](solution/sessions/TEMPLATE_session.md); противоречия — через [FIXES.md](solution/FIXES.md). Для коротких проектов подсистему можно не трогать.
- **`progress.md` / `session-handoff.md` / `DECISIONS.md`** — заполняются по ходу работы, не заранее.
- **`docs/` и `templates/`** — по подсказкам внутри; это справочники для агента.

## Управление фичами

```bash
# начать фичу: в feature_list.json поставить state=active (только ОДНА активная)
make vcr                          # доля passing среди активированных (цель — 1.0)
make verify-feature F=feat-001    # прогнать верификацию фичи и записать evidence
make clean-check                  # чистое состояние перед коммитом
make check                        # полная верификация репозитория
```

## Что покажут проверки на пустом (незаполненном) шаблоне

- `validate-harness.mjs` — высокий балл: все структурные маркеры уже на месте.
- `audit-harness.sh` — все CRITICAL-проверки зелёные, кроме **«Dependency lockfile present»**: это проверка вашего проекта, а не harness. Она позеленеет, когда в проекте появится lockfile (`package-lock.json`, `poetry.lock`, `go.sum`, …). Для Java-проектов учтите: скрипт знает только web-стеки и не считает `pom.xml`/Gradle-lockfile — эту проверку можно игнорировать.
- Остальные замечания (`RECOMMENDED`) — подсказки по опциональным усилениям (`.claude/settings.json`, `scripts/check-arch.sh`, `.harness/arch-rules.json` и т.п.); добавляйте по мере роста проекта.

## Источник

- Курс: <https://github.com/walkinglabs/learn-harness-engineering> (MIT), документация: <https://walkinglabs.github.io/learn-harness-engineering/en/>
- Скрипты `scripts/audit-harness.sh`, `scripts/validate-harness.mjs`, `scripts/lib/harness-utils.mjs`, `templates/evaluator-rubric.md`, `templates/clean-state-checklist.md` взяты из репозитория курса без изменений; остальное адаптировано из его шаблонов.
