## LESSON 1


++windows termanal
> **ACID** - Atomic, Consistency, Isolation,Durabality
> **ARIES** - Algoritms of Recovery and Isolation Exploting Semantics
-logging
-undo
-redo
-checkpoings
> **MVCC** - Multiversion Concurrence Control

**pg_lsclusters** - запущенные экземпляры

### Уровни изоляции

***read uncommited (dirty read)*** - чтение незафиксированной транзакции

***read commited(неповторящееся чтение)*** - чтение несколько раз разных данных в рамках одной транзакции

***repeateble read(фантомное чтение)*** - разные наборы строк при перечитывании данных транзакции (не в PG)

***serializeble (аномалия сериализации)*** - добавление строк выстраивается в последовательность. при конфликтах последняя транзакция роллбечится

```
\echo :AUTOCOMMIT - сессионный параметр AUTOCOMMIT
\set AUTOCOMMIT OFF - установка сессионного параметра
```
