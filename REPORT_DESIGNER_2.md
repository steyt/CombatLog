# CombatLog MAX 2.9.2 — Report Designer / RQL

## 1. Інтерфейс
Designer має дві основні області: зліва список визначень, справа єдина робоча область. У робочій області три вкладки:

- **ЗМІННІ** — read-only вибірки та розрахунки;
- **ШАБЛОН** — текст/розмітка звіту;
- **ПЕРЕГЛЯД** — живий результат на поточних даних/фільтрі та кнопки копіювання.

Окремої кнопки **«Сформувати»** немає: результат перераховується автоматично після зміни змінних, dataset-ів або шаблону. Саме визначення звіту зберігається тільки кнопкою **«Зберегти»**; індикатор зверху показує незбережені зміни. Дерево полів і довідка мови згортані, щоб не забирати робочу площу.

## 2. Read-only модель БД
Доступні корені:

```text
db.flights
db.selectedFlights
db.events
db.positions
db.pilots
db.assets
db.ammo
db.references
db.settings
period
```

Вкладені Flight/Episode дані містять Position, Pilot, Asset, actions, ammo, damages та `extra` користувацькі поля. Дерево даних у Designer вставляє правильний path, тому stable ID/структуру не потрібно пам'ятати вручну.

## 3. Змінні
Приклад:

```text
@data flights = db.selectedFlights
@data vampire = flights | where(asset.name == "VAMPIRE")
@data impacts = flights | flatMap(episodes) | flatMap(damages)
@var total = count(flights)
@var ammoUsed = flights | flatMap(episodes) | flatMap(ammoItems) | sum(quantity)
@var names = flights | select(position.name) | unique() | sort()
```

Рядки виконуються зверху вниз. Наступна змінна може використовувати попередню.

## 4. Оператори

```text
+  -  *  /  %
==  !=  >  <  >=  <=
and  or  not
&&  ||  !
in  not in
```

Масиви:

```text
["position_uav", "position_reb"]
asset.id in ["asset_a", "asset_b"]
```

## 5. Колекції та функції

Основні pipeline-операції:

```text
where(...) / filter(...)
select(...) / map(...)
flatMap(...)
groupBy(...)
unique() / distinct()
sort()
reverse()
take()
skip()
count()
sum()
avg()
min()
max()
first()
last()
join()
```

Функції значень також включають `round`, `abs`, `exists`, `empty`, `coalesce`, `contains`, `startsWith`, `endsWith`.

## 6. Шаблон

```text
**Загальний підсумок**

Всього вильотів – {{ total }}
Позиції: {{ names | join(", ") }}

@if(total > 0)
Дані є.
@else
Даних немає.
@endif

@foreach(vampire as flight)
{{ flight.date }} · {{ flight.position.name }} · №{{ flight.sortie }}
@endforeach
```

Підтримуються:
- `{{ expression }}`;
- `@if/@elseif/@else/@endif`;
- `@foreach/@endforeach`;
- `@break`, `@continue`;
- `@empty/@endempty`;
- `@include`.

## 7. Форматування

Редактор має B / I / U. Внутрішня розмітка:

```text
**жирний**
*курсив*
__підкреслений__
```

Plain copy прибирає rich-форматування. Formatted copy зберігає його там, де це підтримується.

## 8. Безпека

RQL і template engine лише читають detached snapshot даних.

Недоступні:
- JavaScript / `eval` / `Function`;
- SQL / Go;
- файловий доступ;
- HTTP/API виклики;
- repository methods;
- assignment або будь-яке редагування БД.

`__proto__`, `prototype`, `constructor` блокуються. Синтаксичні/runtime помилки показуються з номером рядка.

## 9. Візуальні datasets
Існуючі managed reports можуть використовувати structured datasets/metrics. Вони залишаються необов'язковим візуальним helper-рівнем і можуть комбінуватися з власними `@data/@var`.


## Семантичний scope профілю

Метрика може мати `profileTags`, наприклад `profileTags: ["role.drop"]`. Такий scope відбирає вильоти за властивістю профілю, а не за конкретним ID засобу. Це використовується, зокрема, для сумарної категорії «Скиди» у проміжному звіті.
