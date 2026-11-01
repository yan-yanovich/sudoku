// Данные уроков: теория, пример (схема с подсветкой) и практика.

enum LessonCategory { basics, simple, medium, advanced }

extension LessonCategoryX on LessonCategory {
  String get title => switch (this) {
        LessonCategory.basics => 'Основы судоку',
        LessonCategory.simple => 'Простые техники',
        LessonCategory.medium => 'Средние техники',
        LessonCategory.advanced => 'Сложные техники',
      };

  String get icon => switch (this) {
        LessonCategory.basics => '📚',
        LessonCategory.simple => '🎯',
        LessonCategory.medium => '🔥',
        LessonCategory.advanced => '💎',
      };

  String get subtitle => switch (this) {
        LessonCategory.basics => 'Правила, первые ходы, заметки',
        LessonCategory.simple => 'Одиночки, пары, исключения',
        LessonCategory.medium => 'Тройки, скрытые пары, X-Wing',
        LessonCategory.advanced => 'Крылья, цепочки, перебор',
      };
}

/// Цвет подсветки клетки в примере.
enum MarkColor { focus, related, pattern, remove, success }

extension MarkColorX on MarkColor {
  String get legend => switch (this) {
        MarkColor.focus => 'Главная клетка',
        MarkColor.related => 'Влияющие клетки',
        MarkColor.pattern => 'Паттерн',
        MarkColor.remove => 'Исключаем',
        MarkColor.success => 'Ответ',
      };
}

/// Подсветка клетки в примере: цвет, надпись или кандидаты.
class Mark {
  const Mark(this.row, this.col, {this.color, this.text, this.notes});

  final int row;
  final int col;
  final MarkColor? color;
  final String? text;
  final List<int>? notes;
}

class LessonExample {
  const LessonExample({
    required this.rows,
    required this.marks,
    required this.caption,
  });

  /// 9 строк по 9 символов: цифра или '.' для пустой клетки.
  final List<String> rows;
  final List<Mark> marks;
  final String caption;

  List<List<int>> get board => parseRows(rows);
}

class LessonPractice {
  const LessonPractice({
    required this.mask,
    required this.task,
    this.relabel = '123456789',
    this.transpose = false,
    this.startWithCandidates = false,
  });

  /// 9 строк по 9 символов: 'x' — цифра дана, '.' — клетку решает игрок.
  final List<String> mask;

  /// Текст задания.
  final String task;

  /// Перестановка цифр: цифра d заменяется на relabel[d - 1].
  final String relabel;

  /// Отразить поле по диагонали (для разнообразия).
  final bool transpose;

  /// Сразу расставить кандидатов во всех пустых клетках.
  final bool startWithCandidates;

  List<List<int>> get solution => _transform(parseRows(baseSolution));

  List<List<int>> get puzzle {
    final base = parseRows(baseSolution);
    return _transform([
      for (var r = 0; r < 9; r++)
        [for (var c = 0; c < 9; c++) mask[r][c] == 'x' ? base[r][c] : 0],
    ]);
  }

  List<List<int>> _transform(List<List<int>> grid) {
    final mapped = [
      for (final row in grid)
        [for (final v in row) v == 0 ? 0 : int.parse(relabel[v - 1])],
    ];
    if (!transpose) return mapped;
    return [
      for (var r = 0; r < 9; r++) [for (var c = 0; c < 9; c++) mapped[c][r]],
    ];
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.category,
    required this.theory,
    required this.example,
    required this.practice,
  });

  final String id;
  final String title;
  final LessonCategory category;
  final String theory;
  final LessonExample example;
  final LessonPractice practice;
}

// ========== Базовые поля ==========

List<List<int>> parseRows(List<String> rows) => [
      for (final row in rows)
        [for (final ch in row.split('')) ch == '.' ? 0 : int.parse(ch)],
    ];

/// Проверенное решённое поле, из него строятся все практики.
const List<String> baseSolution = [
  '534678912',
  '672195348',
  '198342567',
  '859761423',
  '426853791',
  '713924856',
  '961537284',
  '287419635',
  '345286179',
];

/// Классическая головоломка с единственным решением (baseSolution).
const List<String> wikiPuzzle = [
  '53..7....',
  '6..195...',
  '.98....6.',
  '8...6...3',
  '4..8.3..1',
  '7...2...6',
  '.6....28.',
  '...419..5',
  '....8..79',
];

/// Маска подсказок wikiPuzzle. Любая маска практики содержит все эти 'x',
/// поэтому решение практики всегда единственное.
const List<String> wikiMask = [
  'xx..x....',
  'x..xxx...',
  '.xx....x.',
  'x...x...x',
  'x..x.x..x',
  'x...x...x',
  '.x....xx.',
  '...xxx..x',
  '....x..xx',
];

const String _full = 'xxxxxxxxx';

const List<String> _emptyBoard = [
  '.........',
  '.........',
  '.........',
  '.........',
  '.........',
  '.........',
  '.........',
  '.........',
  '.........',
];

/// Маска wikiMask, в которой строки [fullRows] открыты полностью.
List<String> _maskFullRows(Set<int> fullRows) => [
      for (var r = 0; r < 9; r++) fullRows.contains(r) ? _full : wikiMask[r],
    ];

List<Mark> _rowMarks(int r, MarkColor color) =>
    [for (var c = 0; c < 9; c++) Mark(r, c, color: color)];

List<Mark> _colMarks(int c, MarkColor color) =>
    [for (var r = 0; r < 9; r++) Mark(r, c, color: color)];

List<Mark> _boxMarks(int b, MarkColor color) => [
      for (var i = 0; i < 9; i++)
        Mark(b ~/ 3 * 3 + i ~/ 3, b % 3 * 3 + i % 3, color: color),
    ];

/// Клетки, влияющие на центральную клетку wikiPuzzle (строка 5, столбец 5).
const List<Mark> _centerRelated = [
  Mark(4, 0, color: MarkColor.related),
  Mark(4, 3, color: MarkColor.related),
  Mark(4, 5, color: MarkColor.related),
  Mark(4, 8, color: MarkColor.related),
  Mark(0, 4, color: MarkColor.related),
  Mark(1, 4, color: MarkColor.related),
  Mark(3, 4, color: MarkColor.related),
  Mark(5, 4, color: MarkColor.related),
  Mark(7, 4, color: MarkColor.related),
  Mark(8, 4, color: MarkColor.related),
];

// ========== Уроки ==========

final List<Lesson> allLessons = [
  // ===== ОСНОВЫ =====
  Lesson(
    id: 'basics-1',
    title: '1. Что такое судоку',
    category: LessonCategory.basics,
    theory: '''
Судоку — логическая головоломка. Поле 9×9 разделено на 9 квадратов 3×3.

**Цель:** заполнить пустые клетки цифрами от 1 до 9 так, чтобы цифры не повторялись:
• в каждой **строке**;
• в каждом **столбце**;
• в каждом **квадрате 3×3**.

Получается, что в каждой строке, столбце и квадрате каждая цифра от 1 до 9 встречается ровно один раз.

Часть клеток заполнена заранее — это **подсказки**, их менять нельзя.

У правильной головоломки **одно решение**, и до него можно дойти чистой логикой, без угадывания.
''',
    example: LessonExample(
      rows: baseSolution,
      marks: [
        ..._boxMarks(4, MarkColor.pattern),
        ..._colMarks(0, MarkColor.related),
        ..._rowMarks(0, MarkColor.focus),
      ],
      caption:
          'Решённое судоку. Выделены первая строка, первый столбец и центральный квадрат: в каждом из них цифры от 1 до 9 стоят ровно по одному разу.',
    ),
    practice: LessonPractice(
      mask: [
        'xx.xxxxxx',
        _full,
        _full,
        'xxxxx.xxx',
        _full,
        _full,
        '.xxxxxxxx',
        _full,
        'xxx.xxxxx',
      ],
      task:
          'В четырёх строках не хватает по одной цифре. Выберите пустую клетку и поставьте недостающую цифру.',
    ),
  ),

  Lesson(
    id: 'basics-2',
    title: '2. Первые шаги',
    category: LessonCategory.basics,
    theory: '''
Как понять, какая цифра стоит в пустой клетке?

**Метод исключения:**
1. Посмотрите на **строку** клетки — какие цифры там уже есть?
2. Посмотрите на **столбец**.
3. Посмотрите на **квадрат 3×3**.
4. Мысленно вычеркните все эти цифры из ряда 1–9.
5. Если осталась одна цифра — это ответ.

**Совет:** начинайте с клеток, у которых в строке, столбце и квадрате много заполненных клеток: там вариантов меньше всего.
''',
    example: LessonExample(
      rows: wikiPuzzle,
      marks: [
        ..._centerRelated,
        Mark(4, 4, color: MarkColor.success, text: '5'),
      ],
      caption:
          'Центральная клетка. В её строке есть 4, 8, 3, 1; в столбце — 7, 9, 6, 2, 1, 8; в квадрате — 6, 8, 3, 2. Не встречается только 5 — она и стоит в этой клетке.',
    ),
    practice: LessonPractice(
      mask: [
        _full,
        'x.xxxxx.x',
        '.xxx.xxxx',
        _full,
        _full,
        'xx.xxx.xx',
        _full,
        '.xxxxx.xx',
        _full,
      ],
      task:
          'В некоторых строках не хватает двух цифр. Чтобы понять, какая куда, проверьте ещё столбец и квадрат каждой клетки.',
    ),
  ),

  Lesson(
    id: 'basics-3',
    title: '3. Заметки (кандидаты)',
    category: LessonCategory.basics,
    theory: '''
Часто в клетку подходит сразу несколько цифр. Тогда их записывают маленькими цифрами — это **заметки**, или **кандидаты**.

**Как пользоваться в приложении:**
• Кнопка **«Заметки»** включает режим карандаша: цифры ставятся маленькими.
• Кнопка **«Кандидаты»** автоматически расставит все возможные цифры во всех пустых клетках.
• Когда вы ставите правильную цифру, она сама исчезает из заметок соседних клеток.

**Пример:** в клетку подходят 1, 2 и 4. Позже в той же строке появляется 4 — остаются 1 и 2. Потом в столбце появляется 1 — остаётся 2, это ответ.

**Совет:** заметки — главный инструмент для средних и сложных головоломок. Все техники из следующих разделов работают именно с кандидатами.
''',
    example: LessonExample(
      rows: wikiPuzzle,
      marks: [
        Mark(0, 2, color: MarkColor.focus, notes: [1, 2, 4]),
        Mark(0, 3, color: MarkColor.focus, notes: [2, 6]),
      ],
      caption:
          'В первой строке: в 3-ю клетку подходят 1, 2 и 4, в 4-ю — 2 и 6. Записываем их заметками и вычёркиваем по мере решения.',
    ),
    practice: LessonPractice(
      mask: _maskFullRows({3, 4, 5, 6, 7, 8}),
      relabel: '372984165',
      task:
          'Решите верхнюю часть поля. Включите «Заметки» и запишите варианты сами — или нажмите «Кандидаты».',
    ),
  ),

  Lesson(
    id: 'basics-4',
    title: '4. Стратегия решения',
    category: LessonCategory.basics,
    theory: '''
**Общий порядок действий:**

1. **Начните с самых заполненных мест.** Ищите строки, столбцы и квадраты, где больше всего цифр.

2. **Проверяйте цифры по очереди.** Возьмите, например, все единицы на поле и посмотрите, куда ещё можно поставить 1.

3. **Используйте заметки,** когда очевидных ходов не осталось.

4. **Каждый ход открывает новые.** После каждой поставленной цифры снова проверьте её строку, столбец и квадрат.

5. **Не угадывайте.** Если сомневаетесь — значит, ещё не нашли нужную логику.

**Порядок техник:**
• сначала голые одиночки — клетки с одним кандидатом;
• затем скрытые одиночки — цифры, которым в области осталось одно место;
• и только потом более сложные приёмы.

Теперь решите головоломку целиком!
''',
    example: LessonExample(
      rows: wikiPuzzle,
      marks: [
        ..._colMarks(4, MarkColor.pattern),
        Mark(4, 4, color: MarkColor.success, text: '5'),
      ],
      caption:
          'В 5-м столбце уже 6 цифр из 9 — больше, чем в любой другой строке, столбце или квадрате. Отличное место для старта: в центральной клетке подходит только 5.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      task:
          'Решите головоломку целиком. Если застряли — кнопка «Подсказка» покажет следующий логичный ход.',
    ),
  ),

  // ===== ПРОСТЫЕ ТЕХНИКИ =====
  Lesson(
    id: 'simple-1',
    title: '1. Голая одиночка',
    category: LessonCategory.simple,
    theory: '''
**Голая одиночка (Naked Single)** — самая простая техника.

Если в клетке остался **только один кандидат**, он и есть ответ.

**Как найти:**
1. Расставьте кандидатов.
2. Найдите клетку, где осталась одна маленькая цифра.
3. Поставьте её.

После каждой поставленной цифры кандидаты в соседних клетках уменьшаются, и появляются новые голые одиночки.

**Совет:** это первое, что стоит искать на поле.
''',
    example: LessonExample(
      rows: wikiPuzzle,
      marks: [
        ..._centerRelated,
        Mark(4, 4, color: MarkColor.success, notes: [5]),
      ],
      caption:
          'Цифры в строке, столбце и квадрате (выделены) исключают всё, кроме 5. У клетки один кандидат — это голая одиночка.',
    ),
    practice: LessonPractice(
      mask: _maskFullRows({6, 7, 8}),
      relabel: '913725864',
      startWithCandidates: true,
      task:
          'Кандидаты уже расставлены. Ищите клетки, где осталась одна цифра, и ставьте её.',
    ),
  ),

  Lesson(
    id: 'simple-2',
    title: '2. Скрытая одиночка',
    category: LessonCategory.simple,
    theory: '''
**Скрытая одиночка (Hidden Single):** цифре в строке, столбце или квадрате осталось **только одно место**.

В самой клетке при этом может быть несколько кандидатов — но цифру больше некуда поставить, значит, она стоит здесь.

**Как найти:**
1. Выберите область — строку, столбец или квадрат.
2. Выберите цифру, которой там ещё нет.
3. Посчитайте, в скольких клетках области она может стоять.
4. Если в одной — это скрытая одиночка.

**Отличие от голой одиночки:**
• голая — в **клетке** один кандидат;
• скрытая — у **цифры** в области одно место.
''',
    example: LessonExample(
      rows: wikiPuzzle,
      marks: [
        Mark(4, 8, color: MarkColor.related),
        Mark(7, 4, color: MarkColor.related),
        Mark(6, 8, color: MarkColor.remove, text: '✗1'),
        Mark(7, 6, color: MarkColor.remove, text: '✗1'),
        Mark(7, 7, color: MarkColor.remove, text: '✗1'),
        Mark(8, 6, color: MarkColor.success, notes: [1, 3, 4, 6]),
      ],
      caption:
          'Правый нижний квадрат. В 8-й строке уже есть 1, в 9-м столбце тоже (в 5-й строке). Для единицы в квадрате остаётся одна клетка. В ней кандидаты 1, 3, 4, 6, но 1 обязана стоять именно здесь.',
    ),
    practice: LessonPractice(
      mask: _maskFullRows({0, 1, 2}),
      relabel: '246813579',
      transpose: true,
      startWithCandidates: true,
      task:
          'Найдите цифры, которым в строке, столбце или квадрате осталось одно место.',
    ),
  ),

  Lesson(
    id: 'simple-3',
    title: '3. Голая пара',
    category: LessonCategory.simple,
    theory: '''
**Голая пара (Naked Pair):** две клетки одной области, в которых кандидаты — одни и те же **две цифры**.

Например, две клетки строки содержат только {3, 7}. Значит, 3 и 7 займут именно эти две клетки (пока неизвестно, какая где).

**Вывод:** вычеркните 3 и 7 из всех **остальных** клеток этой области.

**Как найти:**
1. Ищите клетки ровно с двумя кандидатами.
2. Найдите две одинаковые в одной строке, столбце или квадрате.
3. Вычеркните эти цифры из соседей по области.

Если пара стоит и в одной строке, и в одном квадрате — вычёркивать можно в обеих областях.
''',
    example: LessonExample(
      rows: [
        '.1.24.569',
        '.........',
        '.........',
        '.........',
        '.........',
        '8........',
        '.........',
        '..8......',
        '.........',
      ],
      marks: [
        Mark(0, 0, color: MarkColor.pattern, notes: [3, 7]),
        Mark(0, 2, color: MarkColor.pattern, notes: [3, 7]),
        Mark(0, 5, color: MarkColor.remove, notes: [3, 7, 8]),
      ],
      caption:
          'В первой строке не хватает 3, 7 и 8. В 1-ю и 3-ю клетки восьмёрку не пускают столбцы — там остаётся {3, 7}. Это голая пара: из 6-й клетки вычёркиваем 3 и 7, остаётся 8.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '857193462',
      startWithCandidates: true,
      task:
          'Решите головоломку с кандидатами. Ищите две клетки с одинаковой парой цифр и вычёркивайте эти цифры у соседей (режим «Заметки»).',
    ),
  ),

  Lesson(
    id: 'simple-4',
    title: '4. Указывающая пара',
    category: LessonCategory.simple,
    theory: '''
**Указывающая пара (Pointing Pair):** внутри квадрата цифра может стоять только в **одной строке** (или одном столбце).

Тогда цифра точно окажется в этой строке внутри квадрата. Значит, в остальной части строки — **за пределами квадрата** — её быть не может.

**Как найти:**
1. Выберите квадрат и цифру.
2. Посмотрите, где эта цифра может стоять внутри квадрата.
3. Если все варианты лежат на одной линии — вычеркните цифру из этой линии вне квадрата.

Кандидаты в квадрате как бы «указывают» на строку — отсюда название.
''',
    example: LessonExample(
      rows: [
        '.........',
        '123......',
        '56.......',
        '.........',
        '.........',
        '..4......',
        '.........',
        '.........',
        '.........',
      ],
      marks: [
        Mark(5, 2, color: MarkColor.related),
        Mark(0, 0, color: MarkColor.pattern, text: '4?'),
        Mark(0, 1, color: MarkColor.pattern, text: '4?'),
        Mark(0, 3, color: MarkColor.remove, text: '✗4'),
        Mark(0, 4, color: MarkColor.remove, text: '✗4'),
        Mark(0, 5, color: MarkColor.remove, text: '✗4'),
        Mark(0, 6, color: MarkColor.remove, text: '✗4'),
        Mark(0, 7, color: MarkColor.remove, text: '✗4'),
        Mark(0, 8, color: MarkColor.remove, text: '✗4'),
      ],
      caption:
          'В левом верхнем квадрате 2-я и 3-я строки почти заполнены, а 3-й столбец «закрыт» четвёркой ниже. Для 4 остаются только две клетки 1-й строки. Значит, в остальной части 1-й строки четвёрки быть не может.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '619248357',
      transpose: true,
      startWithCandidates: true,
      task:
          'Решите головоломку с кандидатами. Ищите квадраты, где цифра «лежит» на одной линии, и вычёркивайте её на этой линии за пределами квадрата.',
    ),
  ),

  Lesson(
    id: 'simple-5',
    title: '5. Исключение по линии',
    category: LessonCategory.simple,
    theory: '''
**Исключение по линии (Box/Line Reduction)** — обратная сторона указывающей пары.

Если в **строке** (или столбце) цифра может стоять только внутри **одного квадрата**, то в этом квадрате она обязана оказаться на этой строке.

**Вывод:** вычеркните цифру из остальных клеток квадрата.

**Сравнение:**
• указывающая пара: квадрат → линия;
• исключение по линии: линия → квадрат.

**Совет:** эти две техники часто работают по очереди — проверяйте обе.
''',
    example: LessonExample(
      rows: [
        '123456...',
        '.........',
        '.........',
        '.........',
        '.........',
        '........9',
        '.........',
        '.........',
        '.........',
      ],
      marks: [
        Mark(5, 8, color: MarkColor.related),
        Mark(0, 6, color: MarkColor.pattern, text: '9?'),
        Mark(0, 7, color: MarkColor.pattern, text: '9?'),
        Mark(1, 6, color: MarkColor.remove, text: '✗9'),
        Mark(1, 7, color: MarkColor.remove, text: '✗9'),
        Mark(2, 6, color: MarkColor.remove, text: '✗9'),
        Mark(2, 7, color: MarkColor.remove, text: '✗9'),
      ],
      caption:
          'В 1-й строке девятка может стоять только в двух клетках (последнюю «закрывает» 9 в 9-м столбце). Обе они в правом верхнем квадрате, поэтому из остальных клеток квадрата 9 вычёркиваем.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '471395286',
      startWithCandidates: true,
      task:
          'Решите головоломку с кандидатами. Ищите строки и столбцы, где цифра помещается только в одном квадрате.',
    ),
  ),

  // ===== СРЕДНИЕ ТЕХНИКИ =====
  Lesson(
    id: 'medium-1',
    title: '1. Голая тройка',
    category: LessonCategory.medium,
    theory: '''
**Голая тройка (Naked Triple)** — голая пара, расширенная на три клетки.

Если три клетки одной области вместе содержат только **три разные цифры**, эти цифры займут именно эти три клетки.

**Вывод:** вычеркните эти три цифры из остальных клеток области.

**Важно:** в каждой клетке не обязательно все три цифры. Подходят, например:
• {2, 5, 8}, {2, 5, 8}, {2, 5, 8}
• {2, 5}, {5, 8}, {2, 8}
• {2, 5, 8}, {2, 5}, {8}

Главное — вместе у трёх клеток ровно три цифры.
''',
    example: LessonExample(
      rows: [
        '.1.3.4.69',
        '.........',
        '.........',
        '7...5....',
        '..2......',
        '....7....',
        '8........',
        '..7......',
        '.........',
      ],
      marks: [
        Mark(0, 0, color: MarkColor.pattern, notes: [2, 5]),
        Mark(0, 2, color: MarkColor.pattern, notes: [5, 8]),
        Mark(0, 4, color: MarkColor.pattern, notes: [2, 8]),
        Mark(0, 6, color: MarkColor.remove, notes: [2, 5, 7, 8]),
      ],
      caption:
          'Клетки {2,5}, {5,8} и {2,8} в первой строке вместе содержат только 2, 5 и 8. Эти цифры займут именно эти клетки. Вычёркиваем 2, 5 и 8 из последней пустой клетки строки — остаётся 7.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '328761945',
      transpose: true,
      startWithCandidates: true,
      task:
          'Тренировка с кандидатами. Поищите три клетки области, у которых вместе ровно три цифры. Если такой тройки нет — решайте простыми техниками.',
    ),
  ),

  Lesson(
    id: 'medium-2',
    title: '2. Скрытая пара',
    category: LessonCategory.medium,
    theory: '''
**Скрытая пара (Hidden Pair):** две цифры в области встречаются среди кандидатов **только в двух клетках**.

Значит, эти две цифры займут именно эти клетки. Все **остальные** кандидаты из этих двух клеток можно вычеркнуть.

**Пример:**
• клетка A: {2, 3, 5, 7}
• клетка B: {3, 6, 7, 8}
• больше нигде в строке нет ни 3, ни 7.

Убираем лишнее: A = {3, 7}, B = {3, 7}. Скрытая пара превратилась в голую.

**Отличие от голой пары:**
• голая — в клетках **только** эти две цифры;
• скрытая — эти цифры есть **только** в этих клетках.
''',
    example: LessonExample(
      rows: _emptyBoard,
      marks: [
        Mark(0, 0, notes: [1, 2, 5]),
        Mark(0, 1, color: MarkColor.pattern, notes: [2, 3, 5, 7]),
        Mark(0, 2, notes: [1, 4, 5]),
        Mark(0, 3, notes: [4, 6]),
        Mark(0, 4, color: MarkColor.pattern, notes: [3, 6, 7, 8]),
        Mark(0, 5, notes: [1, 8]),
        Mark(0, 6, notes: [2, 9]),
        Mark(0, 7, notes: [4, 9]),
        Mark(0, 8, notes: [6, 8, 9]),
      ],
      caption:
          'Схема строки с кандидатами. Цифры 3 и 7 встречаются только в двух выделенных клетках. Значит, они там и стоят: из 2-й клетки вычёркиваем 2 и 5, из 5-й — 6 и 8.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '795624138',
      startWithCandidates: true,
      task:
          'Тренировка с кандидатами. Выберите область и проверьте пары цифр: не встречаются ли две из них только в двух клетках?',
    ),
  ),

  Lesson(
    id: 'medium-3',
    title: '3. X-Wing',
    category: LessonCategory.medium,
    theory: '''
**X-Wing** — паттерн одной цифры в двух строках и двух столбцах.

**Условие:** в двух строках цифра может стоять только в **одних и тех же двух столбцах**. Четыре клетки образуют прямоугольник.

**Логика:** в каждой из двух строк цифра встанет в один из двух углов. Если в верхней строке она слева, то в нижней — справа, и наоборот. В любом случае оба столбца заняты этой цифрой именно в этих строках.

**Вывод:** вычеркните цифру из этих двух столбцов во **всех остальных строках**.

Работает и наоборот: два столбца, где цифра стоит в одних и тех же двух строках.

Название — от диагоналей прямоугольника, похожих на букву X.
''',
    example: LessonExample(
      rows: _emptyBoard,
      marks: [
        Mark(1, 2, color: MarkColor.pattern, notes: [5]),
        Mark(1, 7, color: MarkColor.pattern, notes: [5]),
        Mark(6, 2, color: MarkColor.pattern, notes: [5]),
        Mark(6, 7, color: MarkColor.pattern, notes: [5]),
        Mark(3, 2, color: MarkColor.remove, notes: [5]),
        Mark(8, 2, color: MarkColor.remove, notes: [5]),
        Mark(4, 7, color: MarkColor.remove, notes: [5]),
        Mark(3, 5, notes: [5]),
        Mark(4, 0, notes: [5]),
      ],
      caption:
          'Схема: показаны только кандидаты 5. Во 2-й и 7-й строках пятёрка может стоять лишь в 3-м и 8-м столбцах (жёлтые углы). Значит, в этих столбцах в других строках 5 вычёркиваем (красные). Кандидаты в других столбцах не затрагиваются.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '164937852',
      transpose: true,
      startWithCandidates: true,
      task:
          'Тренировка с кандидатами. Выберите цифру и найдите строки, где она стоит ровно в двух клетках. Совпадают ли столбцы у двух таких строк?',
    ),
  ),

  Lesson(
    id: 'medium-4',
    title: '4. Swordfish',
    category: LessonCategory.medium,
    theory: '''
**Swordfish («рыба-меч»)** — X-Wing на три строки и три столбца.

**Условие:** в трёх строках цифра может стоять только внутри **одних и тех же трёх столбцов** (в каждой строке — в двух или трёх из них).

**Логика:** три строки должны получить по одной такой цифре, и все они окажутся в этих трёх столбцах — по одной на столбец.

**Вывод:** вычеркните цифру из этих трёх столбцов во всех остальных строках.

**Совет:** встречается редко. Ищите после того, как X-Wing не нашёлся.
''',
    example: LessonExample(
      rows: _emptyBoard,
      marks: [
        Mark(0, 1, color: MarkColor.pattern, notes: [7]),
        Mark(0, 4, color: MarkColor.pattern, notes: [7]),
        Mark(4, 4, color: MarkColor.pattern, notes: [7]),
        Mark(4, 8, color: MarkColor.pattern, notes: [7]),
        Mark(7, 1, color: MarkColor.pattern, notes: [7]),
        Mark(7, 8, color: MarkColor.pattern, notes: [7]),
        Mark(2, 4, color: MarkColor.remove, notes: [7]),
        Mark(5, 1, color: MarkColor.remove, notes: [7]),
        Mark(3, 8, color: MarkColor.remove, notes: [7]),
      ],
      caption:
          'Схема: показаны только кандидаты 7. В 1-й, 5-й и 8-й строках семёрка стоит только в столбцах 2, 5 и 9 (жёлтые). Каждый столбец получит одну семёрку из этих строк, поэтому в остальных строках этих столбцов 7 вычёркиваем (красные).',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '582413697',
      startWithCandidates: true,
      task:
          'Тренировка с кандидатами. Выберите цифру и выпишите для каждой строки, в каких столбцах она может стоять. Есть ли три строки на трёх общих столбцах?',
    ),
  ),

  // ===== СЛОЖНЫЕ ТЕХНИКИ =====
  Lesson(
    id: 'advanced-1',
    title: '1. XY-Wing',
    category: LessonCategory.advanced,
    theory: '''
**XY-Wing** — три клетки, в каждой ровно два кандидата.

• **Центр:** {X, Y}
• **Крыло 1:** {X, Z} — видит центр (общая строка, столбец или квадрат)
• **Крыло 2:** {Y, Z} — тоже видит центр

**Логика:**
• если в центре X, то в крыле 1 не X, значит там Z;
• если в центре Y, то в крыле 2 не Y, значит там Z.

В любом случае Z стоит в одном из крыльев. Значит, из любой клетки, которая **видит оба крыла**, цифру Z можно вычеркнуть.

**Пример:** центр {2, 5}, крылья {2, 7} и {5, 7}. Если в центре 2 — в первом крыле 7. Если 5 — во втором крыле 7. Клетка, видящая оба крыла, не может содержать 7.
''',
    example: LessonExample(
      rows: _emptyBoard,
      marks: [
        Mark(3, 3, color: MarkColor.focus, notes: [2, 5]),
        Mark(3, 6, color: MarkColor.pattern, notes: [2, 7]),
        Mark(6, 3, color: MarkColor.pattern, notes: [5, 7]),
        Mark(6, 6, color: MarkColor.remove, notes: [1, 7]),
      ],
      caption:
          'Центр {2,5} (синий), крылья {2,7} и {5,7} (жёлтые): одно в той же строке, другое в том же столбце. Красная клетка видит оба крыла, поэтому 7 в ней быть не может — остаётся 1.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '943158276',
      transpose: true,
      startWithCandidates: true,
      task:
          'Тренировка с кандидатами. Найдите клетку с двумя кандидатами и проверьте, нет ли у неё двух подходящих «крыльев».',
    ),
  ),

  Lesson(
    id: 'advanced-2',
    title: '2. XYZ-Wing',
    category: LessonCategory.advanced,
    theory: '''
**XYZ-Wing** — вариант XY-Wing, где в центре три кандидата.

• **Центр:** {X, Y, Z}
• **Крыло 1:** {X, Z}, видит центр
• **Крыло 2:** {Y, Z}, видит центр

**Логика:**
• если в центре Z — Z в центре;
• если в центре X — в крыле 1 стоит Z;
• если в центре Y — в крыле 2 стоит Z.

Z точно стоит в одной из трёх клеток. Вычеркнуть Z можно только из клеток, которые видят **все три** клетки сразу. Обычно это клетки того же квадрата, что и центр.
''',
    example: LessonExample(
      rows: _emptyBoard,
      marks: [
        Mark(3, 3, color: MarkColor.focus, notes: [2, 5, 7]),
        Mark(3, 5, color: MarkColor.pattern, notes: [2, 7]),
        Mark(5, 3, color: MarkColor.pattern, notes: [5, 7]),
        Mark(5, 5, color: MarkColor.remove, notes: [4, 7]),
      ],
      caption:
          'Центр {2,5,7}, крылья {2,7} и {5,7} — все в центральном квадрате. Семёрка точно стоит в одной из этих трёх клеток. Красная клетка видит все три, поэтому 7 в ней вычёркиваем.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '237586914',
      startWithCandidates: true,
      task:
          'Тренировка с кандидатами. Ищите клетку с тремя кандидатами и две клетки рядом, у которых пары из этих же цифр.',
    ),
  ),

  Lesson(
    id: 'advanced-3',
    title: '3. Простые цепочки',
    category: LessonCategory.advanced,
    theory: '''
**Простые цепочки (раскраска)** — работаем с одной цифрой.

**Сильная связь:** в области цифра может стоять ровно в **двух** клетках. Тогда в одной из них она точно есть, а в другой точно нет.

**Цепочка:** соединяем сильные связи друг за другом: A — B — C — D. Раскрашиваем клетки по очереди в два цвета: A и C — первый цвет, B и D — второй.

**Главное правило:** верен ровно один цвет. Либо цифра стоит во всех клетках первого цвета, либо во всех клетках второго.

**Вывод:** клетка, которая видит две клетки **разных цветов**, не может содержать эту цифру — одна из тех двух клеток её точно займёт.
''',
    example: LessonExample(
      rows: _emptyBoard,
      marks: [
        Mark(0, 0, color: MarkColor.focus, text: 'A'),
        Mark(1, 2, color: MarkColor.pattern, text: 'B'),
        Mark(1, 7, color: MarkColor.focus, text: 'C'),
        Mark(5, 7, color: MarkColor.pattern, text: 'D'),
        Mark(5, 0, color: MarkColor.remove, text: '✗5'),
      ],
      caption:
          'Цепочка для цифры 5: A–B в квадрате, B–C в строке, C–D в столбце (в каждой области пятёрке два места). A и C — один цвет, B и D — другой. Значит, 5 стоит либо в A, либо в D. Красная клетка видит A (по столбцу) и D (по строке), поэтому 5 в ней нет.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '816342759',
      transpose: true,
      startWithCandidates: true,
      task:
          'Тренировка с кандидатами. Выберите цифру и найдите области, где у неё ровно два места. Получается ли из них цепочка?',
    ),
  ),

  Lesson(
    id: 'advanced-4',
    title: '4. Вынужденные цепочки',
    category: LessonCategory.advanced,
    theory: '''
**Вынужденные цепочки (Forcing Chains)** — проверяем все варианты клетки.

**Идея:** возьмите клетку с двумя кандидатами, например {3, 7}.
• Предположите, что там 3, и проследите последствия.
• Затем предположите 7 и проследите последствия.

Если **оба** пути приводят к одному и тому же выводу (например, «в клетке Z стоит 5»), этот вывод верен при любом раскладе.

**Чем отличается от угадывания:** вы не выбираете один вариант, а доказываете, что результат одинаков для всех.

**Когда применять:** на очень сложных головоломках, когда остальные техники не помогают.
''',
    example: LessonExample(
      rows: _emptyBoard,
      marks: [
        Mark(2, 2, color: MarkColor.focus, notes: [3, 7]),
        Mark(6, 6, color: MarkColor.success, text: '5'),
      ],
      caption:
          'Схема. Из клетки {3,7} строим две цепочки: «если здесь 3…» и «если здесь 7…». Если обе приводят к 5 в зелёной клетке, 5 стоит там при любом раскладе.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '459762381',
      startWithCandidates: true,
      task:
          'Тренировка с кандидатами. Выберите клетку с двумя кандидатами и мысленно проследите оба варианта на 2–3 хода вперёд.',
    ),
  ),

  Lesson(
    id: 'advanced-5',
    title: '5. Перебор с откатом',
    category: LessonCategory.advanced,
    theory: '''
**Перебор с откатом (Trial and Error)** — крайний метод.

**Как работает:**
1. Выберите клетку с наименьшим числом кандидатов — лучше с двумя.
2. Предположите один из них.
3. Решайте дальше.
4. Получили противоречие (повтор цифры или клетку без кандидатов)? Значит, предположение неверно — вернитесь и поставьте другой кандидат.

**В приложении:** в обычной игре для этого есть кнопка **«Отмена»**.

**Важно:** хорошо составленное судоку решается логикой. Перебор — запасной вариант, когда логический ход не находится.

🎉 Это последний урок. Вы прошли путь от правил до продвинутых техник!
''',
    example: LessonExample(
      rows: _emptyBoard,
      marks: [
        Mark(4, 4, color: MarkColor.pattern, notes: [3, 8]),
        Mark(4, 7, color: MarkColor.remove, text: '✗'),
      ],
      caption:
          'Схема. Пробуем поставить 3 в жёлтую клетку и решаем дальше. Если в какой-то клетке (красная) не осталось ни одного кандидата — предположение неверно, значит, в жёлтой клетке 8.',
    ),
    practice: LessonPractice(
      mask: wikiMask,
      relabel: '671829534',
      transpose: true,
      startWithCandidates: true,
      task:
          'Итоговая тренировка: решите головоломку, используя всё, что изучили.',
    ),
  ),
];
