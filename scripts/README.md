# Скрипты проверки harness — как запускать

Три вида проверок: **аудит структуры** (bash), **оценка подсистем** (Node.js) и **рабочие гейты** (verify-feature, clean-state-check). Все команды выполняются **из корня этой папки** (путь с пробелами — не проблема, если брать в кавычки).

Требования:

- Bash: Git Bash (есть на Windows), WSL, Linux, macOS.
- Node.js ≥ 18 — только для `validate-harness.mjs` и `verify-feature.sh` (разбор JSON). В этой системе установлен Node v24.

## 1. audit-harness.sh — аудит по пяти подсистемам (из курса, bash, без зависимостей)

```bash
bash scripts/audit-harness.sh .
```

- Можно передать путь к другому репозиторию: `bash scripts/audit-harness.sh /path/to/project`.
- Вывод: проверки `[PASS]/[FAIL]/[WARN]` с пометками `[CRITICAL]` (обязательные) и `[RECOMMENDED]` (best practice), затем Summary и блок «What to fix» с конкретными исправлениями.
- Коды выхода: `0` — все CRITICAL зелёные, `1` — есть проваленные CRITICAL.
- Вариант без скачивания (для любого репозитория):

```bash
curl -fsSL https://raw.githubusercontent.com/walkinglabs/learn-harness-engineering/main/tools/audit-harness.sh | bash -s -- /path/to/project
```

## 2. validate-harness.mjs — оценка 5 подсистем от 0 до 100 (Node.js)

```bash
node scripts/validate-harness.mjs .
```

- Флаги:
  - `--json` — результат в JSON;
  - `--html report.html` — сохранить HTML-отчёт;
  - `--min-score N` — порог (по умолчанию 70), влияет на код выхода.
- Как читать: `Overall: N/100`, узкое место (`bottleneck`) и по каждой подсистеме `score/5` со списком `PASS/FAIL`. Каждая подсистема = 5 проверок (инструкции, state, verification, scope, lifecycle).
- Коды выхода: `0` — Overall ≥ порога, `1` — ниже.

## 3. Рабочие гейты (используются в повседневной работе)

```bash
bash scripts/verify-feature.sh feat-001   # гейт фичи: state=active → верификация → passing + evidence
bash scripts/clean-state-check.sh         # чистое состояние перед коммитом (или: make clean-check)
bash scripts/clean-state-check.sh . feat-002   # многосессионная фича: feat-002 сознательно остаётся active (продолжение запланировано)
make check                                # полная верификация (вызывает ./init.sh)
make vcr                                  # VCR = passing / активированные (цель 1.0)
```

## Что ожидать на пустом (незаполненном) шаблоне

- `validate-harness.mjs` — высокий балл: все структурные маркеры уже расставлены.
- `audit-harness.sh` — единственный ожидаемый провал CRITICAL: **«Dependency lockfile present»**. Это проверка проекта, а не harness: скрипт ждёт `package-lock.json`, `poetry.lock`, `go.sum` и т.п. Она позеленеет, когда в вашем проекте появится lockfile. Для Java (`pom.xml`/Gradle) скрипт lockfile не распознаёт — эту проверку можно игнорировать.
- `clean-state-check.sh` — один ожидаемый FAIL: «progress.md has been updated» — журнал сессий ещё не заполнялся ни разу. Он станет PASS после первой рабочей сессии, когда в `progress.md` будет вписана реальная дата.
- `RECOMMENDED`-замечания — подсказки по опциональным усилениям; добавляйте по мере роста проекта.

## Устранение неполадок

- **`$'\r': command not found`** или «bad interpreter» — файлы сохранены с CRLF. Лечится переводом в LF:

```bash
sed -i 's/\r$//' scripts/*.sh init.sh Makefile
```

  (В репозитории это уже сделано; `.gitattributes` не даст проблеме вернуться.)

- **`node: command not found`** — установите Node.js ≥ 18; для `audit-harness.sh` он не нужен.
- **Скрипты не находят файлы** — запускайте из корня этой папки (`cd <путь к harness_template>`), а путь к проверяемому репозиторию передавайте первым аргументом.
- **`make: command not found`** (типично для «голого» Git Bash) — используйте команды напрямую: `bash scripts/verify-feature.sh feat-001`, `bash init.sh`.
- **Права на запуск** — если предпочитаете `./scripts/audit-harness.sh`: один раз выполните `chmod +x scripts/*.sh init.sh`.
