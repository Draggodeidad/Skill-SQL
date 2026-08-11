[![skills.sh](https://skills.sh/b/Draggodeidad/Skill-SQL)](https://skills.sh/Draggodeidad/Skill-SQL)

# SQL Reviewer Skill

## Instalación

```bash
npx skills add Draggodeidad/Skill-SQL
```

## Qué hace esta skill

Revisa código SQL de forma técnica y determinista. Analiza sentencias, scripts y migraciones aplicando 24 reglas organizadas en tres categorías:

- **Seguridad** (8 reglas) — Detecta inyección SQL, DELETE/UPDATE sin WHERE, columnas sensibles expuestas, privilegios excesivos
- **Rendimiento** (10 reglas) — Identifica consultas sin LIMIT, índices faltantes, patrones N+1, coerción de tipos implícita
- **Convenciones** (6 reglas) — Valida nombres, comparaciones NULL, tipos de dato, estilo

Cada hallazgo se clasifica por severidad (CRITICAL → INFO) y se evalúa su _blast radius_ — el daño real que puede causar si se ejecuta.

## En qué ayuda

- **Previene errores costosos** — Un DELETE sin WHERE en producción puede borrar toda una tabla. Esta skill lo detecta antes de ejecutar.
- **Detecta problemas ocultos** — Un `WHERE 1=1` parece tener filtro pero no lo tiene. El blast radius identifica estas trampas.
- **Mejora el rendimiento** — Encuentra consultas que harán full table scan, JOINs con tipos incompatibles, y patrones N+1.
- **Estandariza código SQL** — Asegura que el equipo siga las mismas convenciones de nombres y estilos.

## Cuándo usarla

| Caso de uso | Ejemplo |
|-------------|---------|
| Revisar PR con cambios en base de datos | Migración nueva, stored procedure, cambio de schema |
| Auditar queries lentas | SELECT que tarda más de lo esperado |
| Validar migraciones antes de producción | Scripts DDL/DML que van a ejecutarse en prod |
| Revisar código con SQL embebido | Queries en string concatenation o template literals |
| Enseñar buenas prácticas de SQL | Feedback automatizado para junior developers |

## Inicio rápido

Proporcione SQL para revisar y obtenga un reporte estructurado:

```sql
-- Entrada
SELECT * FROM users WHERE deleted_at = NULL;
```

```markdown
-- Salida esperada
Veredicto: FAIL
Hallazgos: 1 CRITICAL, 1 HIGH, 1 MEDIUM

- CONV-003 (HIGH): NULL comparado con = siempre retorna UNKNOWN
- SEC-001 (MEDIUM): SELECT * expone todas las columnas
- PERF-001 (HIGH): SELECT sin LIMIT en conjunto potencialmente grande
```

## Cómo usar

### Parámetros de entrada

| Parámetro | Requerido | Descripción |
|-----------|-----------|-------------|
| `sql` | Sí | Sentencia(s) o script(s) SQL a revisar |
| `engine` | No | Motor de base de datos (MySQL, PostgreSQL, SQL Server, Oracle, SQLite) |
| `schema` | No | Definiciones de tablas, índices, restricciones |

### Ejemplos de uso

#### Ejemplo 1: SQL correcto — Veredicto PASS

**Entrada:**
```sql
SELECT user_id, full_name, email
FROM users
WHERE is_active = TRUE
ORDER BY created_at DESC
LIMIT 50;
```

**Resultado esperado:**
- Veredicto: **PASS**
- Hallazgos: 0 CRITICAL, 0 HIGH, 0 MEDIUM
- Solo observaciones INFO posibles (ej: verificación de índices pendiente si no se proporciona schema)

---

#### Ejemplo 2: SQL con errores críticos — Veredicto FAIL

**Entrada:**
```sql
SELECT * FROM users;

DELETE FROM audit_log;

UPDATE users SET is_admin = TRUE;

SELECT user_id, password, ssn FROM users;
```

**Resultado esperado:**
- Veredicto: **FAIL**
- Hallazgos: 2 CRITICAL, 4 HIGH, 1 MEDIUM
- Detalle:
  - `DELETE FROM audit_log`: SEC-002 CRITICAL (sin WHERE)
  - `UPDATE users SET is_admin = TRUE`: SEC-003 CRITICAL (sin WHERE)
  - `SELECT * FROM users`: SEC-001 MEDIUM + PERF-001 HIGH
  - `SELECT ... password, ssn`: SEC-008 HIGH (columnas sensibles expuestas)

---

#### Ejemplo 3: Casos borde — Blast radius detectado

**Entrada:**
```sql
DELETE FROM users WHERE 1 = 1;

SELECT * FROM events LIMIT 1000000000;

UPDATE users SET role = 'admin' WHERE email LIKE '%';
```

**Resultado esperado:**
- Veredicto: **FAIL**
- Hallazgos: 3 CRITICAL, 1 HIGH, 1 MEDIUM
- El blast radius detecta que:
  - `WHERE 1 = 1` es equivalente a no tener WHERE
  - `LIMIT 1000000000` es efectivamente sin límite
  - `LIKE '%'` coincide con todas las filas

---

#### Ejemplo 4: Información insuficiente — Sin suposiciones

**Entrada:**
```sql
SELECT * FROM t WHERE a = 1;

UPDATE t SET b = 2 WHERE c = 3;
```
*Sin contexto de motor ni schema.*

**Resultado esperado:**
- Veredicto: **PASS** (solo hallazgos INFO y MEDIUM)
- Hallazgos: 0 CRITICAL, 1 HIGH, 1 MEDIUM, 2 LOW, 3 INFO
- Comportamiento clave:
  - PERF-003 degrada a INFO: no puede verificar índices sin schema
  - PERF-008 no se evalúa: tipos de columna desconocidos
  - **Nunca inventa** tamaños de tabla, tipos de columna o conteos de filas

## Resultados esperados

### Veredictos

| Veredicto | Significado |
|-----------|-------------|
| **PASS** | Sin hallazgos por encima de LOW. SQL aceptable. |
| **WARN** | Hallazgos MEDIUM o HIGH presentes, sin CRITICAL. Requiere revisión. |
| **FAIL** | Al menos un hallazgo CRITICAL. No ejecutar sin corrección. |

### Niveles de severidad

| Nivel | Significado | Acción recomendada |
|-------|-------------|-------------------|
| **CRITICAL** | Pérdida de datos o acceso no autorizado seguro | Corregir antes de ejecutar |
| **HIGH** | Degradación significativa de rendimiento o resultados incorrectos | Corregir recomendación |
| **MEDIUM** | Problema de mantenibilidad con impacto moderado | Considerar corrección |
| **LOW** | Mejora menor de estilo o nombres | Opcional |
| **INFO** | Observación o sugerencia — no es defecto | Solo informativo |

### Resumen por tipo de entrada

| Tipo de entrada | Veredicto esperado | Hallazgos típicos |
|----------------|-------------------|-------------------|
| SQL correcto con buenas prácticas | PASS | 0 findings significativos |
| DELETE/UPDATE sin WHERE | FAIL | SEC-002 o SEC-003 CRITICAL |
| SELECT * sin LIMIT | FAIL | SEC-001 MEDIUM + PERF-001 HIGH |
| WHERE tautológico (1=1, LIKE '%') | FAIL | SEC-006 CRITICAL |
| Columnas sensibles sin enmascarar | FAIL | SEC-008 HIGH |
| SQL sin contexto de motor/schema | PASS/WARN | INFO para reglas omitidas |

## Reglas

### Seguridad (8 reglas)

| ID | Regla | Severidad |
|----|-------|-----------|
| SEC-001 | SELECT * expone todas las columnas | MEDIUM |
| SEC-002 | DELETE sin WHERE | CRITICAL |
| SEC-003 | UPDATE sin WHERE | CRITICAL |
| SEC-004 | TRUNCATE/DROP sin protección | CRITICAL |
| SEC-005 | SQL Injection por concatenación | CRITICAL |
| SEC-006 | WHERE tautológico (1=1, TRUE, col=col) | CRITICAL |
| SEC-007 | GRANT con privilegios excesivos | HIGH |
| SEC-008 | Columnas sensibles sin enmascarar | HIGH |

### Rendimiento (10 reglas)

| ID | Regla | Severidad |
|----|-------|-----------|
| PERF-001 | SELECT sin LIMIT en resultado potencialmente grande | HIGH |
| PERF-002 | Wildcard inicial en LIKE | MEDIUM |
| PERF-003 | Índice faltante en columna de filtro/join | MEDIUM / INFO |
| PERF-004 | Patrón de consulta N+1 | HIGH |
| PERF-005 | Subconsulta donde JOIN sería suficiente | MEDIUM |
| PERF-006 | ORDER BY en conjunto grande sin índice | MEDIUM |
| PERF-007 | LIMIT con valor excesivo | HIGH |
| PERF-008 | Coerción de tipos implícita en JOINs | MEDIUM |
| PERF-009 | SELECT dentro de transacción innecesaria | MEDIUM |
| PERF-010 | COUNT(*) donde EXISTS sería suficiente | MEDIUM |

### Convenciones (6 reglas)

| ID | Regla | Severidad |
|----|-------|-----------|
| CONV-001 | Nombres no descriptivos | LOW |
| CONV-002 | Convención de nombres inconsistente | LOW |
| CONV-003 | Comparación incorrecta de NULL (= NULL) | HIGH |
| CONV-004 | Tipo de dato inapropiado | MEDIUM |
| CONV-005 | Consultas complejas sin comentarios | INFO |
| CONV-006 | Uso inconsistente de mayúsculas en keywords | INFO |

## Procedimiento

La skill sigue un procedimiento de 5 pasos:

1. **Parse** — Identifica cada sentencia, clasifica su tipo, inventario de cláusulas
2. **Clasificar motor** — Asigna el motor de BD o marca como `unknown`
3. **Aplicar reglas** — Carga los 3 archivos de reglas, aplica cada regla a cada sentencia
4. **Evaluar blast radius** — Evalúa el efecto semántico más allá de la sintaxis superficial (WHERE 1=1 = WHERE ausente)
5. **Producir veredicto** — Genera el reporte con resumen y hallazgos

## Manejo de información insuficiente

La skill **nunca inventa contexto**. Cuando falta información:

- Sin schema: PERF-003 se degrada a INFO, PERF-008 no se evalúa
- Sin motor: se aplican solo reglas agnósticas del motor, las específicas se listan como omitidas
- Entrada no parseable: se reporta INFO y se continúa con las demás sentencias

## Ejecución de tests

### Cómo ejecutar

Los tests están en la carpeta `tests/` como archivos Markdown. Cada test contiene:
- **Input**: SQL de entrada
- **Expected behavior**: Resultado esperado
- **Actual behavior**: Resultado obtenido
- **Pass / Fail**: Si la skill pasó el test

### Tests disponibles

| Test | Tipo | Qué verifica |
|------|------|-------------|
| test-01 | Happy path | SQL correcto — sin hallazgos artificiales |
| test-02 | Error evidente | Múltiples violaciones claras |
| test-03 | Caso límite | SQL que parece correcto pero tiene problemas ocultos |
| test-04 | Información insuficiente | Sin schema ni motor — sin suposiciones inventadas |
| test-05 | Adversarial | Entradas diseñadas para evadir reglas superficiales |

### Ejecución manual

1. Copiar el SQL del test como entrada a la skill
2. Verificar que los hallazgos reportados coinciden con los esperados
3. Confirmar que no se generan hallazgos artificiales
4. Validar que la información faltante se reporta como INFO, no como defecto

## Estructura del repositorio

```
sql-reviewer-skill/
├── SKILL.md                  # Procedimiento principal de la skill
├── README.md                 # Este archivo
├── rules/
│   ├── security.md           # 8 reglas de seguridad (SEC-001 a SEC-008)
│   ├── performance.md        # 10 reglas de rendimiento (PERF-001 a PERF-010)
│   └── conventions.md        # 6 reglas de convenciones (CONV-001 a CONV-006)
├── examples/
│   ├── valid.sql             # SQL correcto — sin violaciones
│   ├── invalid.sql           # SQL con violaciones claras
│   └── edge-cases.sql        # SQL que parece correcto pero tiene problemas ocultos
└── tests/
    ├── test-01.md            # Happy path
    ├── test-02.md            # Errores evidentes
    ├── test-03.md            # Casos límite
    ├── test-04.md            # Información insuficiente
    └── test-05.md            # Adversarial (Red Team)
```

## Decisiones de diseño

### Por qué es una skill y no un prompt

- Define un **procedimiento reproducible** de 5 pasos con criterios de completitud
- Usa reglas **deterministas** con formato IF/THEN y severidad fija por regla
- Separa las reglas en archivos de referencia (disclosed reference) para legibilidad
- Evalúa **blast radius** semántico, no solo coincidencias de patrones superficiales
- Maneja explícitamente la información insuficiente sin inventar contexto

### Blast radius

El concepto de _blast radius_ (radio de explosión) es central. Evalúa el daño real que una sentencia puede causar, no solo su sintaxis:

- `WHERE 1=1` tiene un WHERE presente pero es equivalente a no tener WHERE
- `LIMIT 1000000000` tiene un LIMIT pero es equivalente a no tener LIMIT
- `WHERE email LIKE '%'` filtra teóricamente pero coincide con todas las filas

### Agnóstico del motor

La skill aplica reglas universales por defecto. Las reglas específicas del motor se omiten con una nota INFO cuando no se proporciona el motor, evitando suposiciones incorrectas.

### Resolución de conflictos

Cuando dos reglas producen recomendaciones contradictorias:
- La regla de mayor severidad gana
- Si la severidad es igual: seguridad > rendimiento > convenciones
