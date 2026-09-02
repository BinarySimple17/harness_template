# Decision Log (DECISIONS.md)

<!-- ЗАПОЛНЯЕТСЯ ПО ХОДУ РАБОТЫ: журнал значимых решений (архитектура,
     зависимости, процессы). Правило из AGENTS.md: кросс-сессионные знания
     живут в трекаемых файлах, а не в контексте чата. Одна запись — одно решение.
     Архитектурно значимые решения (выбор технологий, модель данных, границы
     сервисов) оформляются полноценным ADR — см. docs/adr/README.md, — а здесь
     остаётся оперативный журнал сессий. -->

## D-001: [Decision title]

- Date: YYYY-MM-DD
- Status: accepted <!-- accepted | superseded by D-XXX | rejected -->
- Decision: [что решили — одной фразой, повелительным наклонением]
- Context: [почему: какую проблему решаем, какие ограничения]
- Alternatives considered: [что ещё обсуждали и почему отвергли]
- Consequences: [что это означает для будущих сессий: новые правила, риски, работа]

<!-- Пример:
## D-002: Use Gradle as the single build tool
- Date: 2026-01-15
- Status: accepted
- Decision: All verification goes through ./gradlew; Maven is removed.
- Context: Two build systems drifted and ./init.sh was flaky.
- Alternatives considered: Keeping both (rejected: doubles verification cost).
- Consequences: ./init.sh uses ./gradlew test; docs must not mention mvn.
-->
