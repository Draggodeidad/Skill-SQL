# SQL Reviewer Skill

## Descripcion

Skill de revision tecnica de SQL. Analiza sentencias y scripts SQL aplicando reglas deterministas de seguridad, rendimiento y convenciones. Cada hallazgo se clasifica por severidad usando un procedimiento reproducible — no es un prompt generico.

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
    ├── test-03.md            # Casos limite
    ├── test-04.md            # Informacion insuficiente
    └── test-05.md            # Adversarial (Red Team)
```

## Como usar

La skill se activa automaticamente cuando se proporciona codigo SQL para revision. Tambien se puede invocar manualmente pidiendo revisar, auditar o analizar sentencias SQL.

### Entradas

| Parametro | Requerido | Descripcion |
|-----------|-----------|-------------|
| `sql` | Si | Sentencia(s) o script(s) SQL a revisar |
| `engine` | No | Motor de base de datos (MySQL, PostgreSQL, SQL Server, Oracle, SQLite) |
| `schema` | No | Definiciones de tablas, indices, restricciones |

### Salida

La skill produce un reporte estructurado con:
- Resumen de hallazgos por nivel de severidad
- Veredicto: PASS, WARN o FAIL
- Lista detallada de hallazgos con ID de regla, fragmento SQL, blast radius y recomendacion

## Reglas

### Seguridad (8 reglas)

| ID | Regla | Severidad |
|----|-------|-----------|
| SEC-001 | SELECT * expone todas las columnas | MEDIUM |
| SEC-002 | DELETE sin WHERE | CRITICAL |
| SEC-003 | UPDATE sin WHERE | CRITICAL |
| SEC-004 | TRUNCATE/DROP sin proteccion | CRITICAL |
| SEC-005 | SQL Injection por concatenacion | CRITICAL |
| SEC-006 | WHERE tautologico (1=1, TRUE, col=col) | CRITICAL |
| SEC-007 | GRANT con privilegios excesivos | HIGH |
| SEC-008 | Columnas sensibles sin enmascarar | HIGH |

### Rendimiento (10 reglas)

| ID | Regla | Severidad |
|----|-------|-----------|
| PERF-001 | SELECT sin LIMIT en resultado potencialmente grande | HIGH |
| PERF-002 | Wildcard inicial en LIKE | MEDIUM |
| PERF-003 | Indice faltante en columna de filtro/join | MEDIUM / INFO |
| PERF-004 | Patron de consulta N+1 | HIGH |
| PERF-005 | Subconsulta donde JOIN seria suficiente | MEDIUM |
| PERF-006 | ORDER BY en conjunto grande sin indice | MEDIUM |
| PERF-007 | LIMIT con valor excesivo | HIGH |
| PERF-008 | Coercion de tipos implicita en JOINs | MEDIUM |
| PERF-009 | SELECT dentro de transaccion innecesaria | MEDIUM |
| PERF-010 | COUNT(*) donde EXISTS seria suficiente | MEDIUM |

### Convenciones (6 reglas)

| ID | Regla | Severidad |
|----|-------|-----------|
| CONV-001 | Nombres no descriptivos | LOW |
| CONV-002 | Convencion de nombres inconsistente | LOW |
| CONV-003 | Comparacion incorrecta de NULL (= NULL) | HIGH |
| CONV-004 | Tipo de dato inapropiado | MEDIUM |
| CONV-005 | Consultas complejas sin comentarios | INFO |
| CONV-006 | Uso inconsistente de mayusculas en keywords | INFO |

## Niveles de severidad

| Nivel | Definicion |
|-------|-----------|
| CRITICAL | Perdida de datos o acceso no autorizado es seguro si se ejecuta |
| HIGH | Degradacion significativa de rendimiento o resultados probablemente incorrectos |
| MEDIUM | Problema de mantenibilidad o convencion con impacto moderado |
| LOW | Mejora menor de estilo o nombres |
| INFO | Observacion o sugerencia — no es un defecto |

## Procedimiento

La skill sigue un procedimiento de 5 pasos:

1. **Parse** — Identifica cada sentencia, clasifica su tipo, inventario de clausulas
2. **Clasificar motor** — Asigna el motor de BD o marca como `unknown`
3. **Aplicar reglas** — Carga los 3 archivos de reglas, aplica cada regla a cada sentencia
4. **Evaluar blast radius** — Evalua el efecto semantico mas alla de la sintaxis superficial (WHERE 1=1 = WHERE ausente)
5. **Producir veredicto** — Genera el reporte con resumen y hallazgos

## Manejo de informacion insuficiente

La skill **nunca inventa contexto**. Cuando falta informacion:

- Sin schema: PERF-003 se degrada a INFO, PERF-008 no se evalua
- Sin motor: se aplican solo reglas agnosticas del motor, las especificas se listan como omitidas
- Entrada no parseable: se reporta INFO y se continua con las demas sentencias

## Pruebas

| Prueba | Tipo | Descripcion |
|--------|------|-------------|
| test-01 | Happy path | SQL correcto — sin hallazgos artificiales |
| test-02 | Error evidente | Multiples violaciones claras |
| test-03 | Caso limite | SQL que parece correcto pero tiene problemas ocultos |
| test-04 | Informacion insuficiente | Sin schema ni motor — sin suposiciones inventadas |
| test-05 | Adversarial | Entradas disenadas para evadir reglas superficiales |

## Decisiones de diseno

### Por que es una skill y no un prompt

- Define un **procedimiento reproducible** de 5 pasos con criterios de completitud
- Usa reglas **deterministas** con formato IF/THEN y severidad fija por regla
- Separa las reglas en archivos de referencia (disclosed reference) para legibilidad
- Evalua **blast radius** semantico, no solo coincidencias de patrones superficiales
- Maneja explicitamente la informacion insuficiente sin inventar contexto

### Blast radius

El concepto de _blast radius_ (radio de explosion) es central. Evalua el dano real que una sentencia puede causar, no solo su sintaxis:

- `WHERE 1=1` tiene un WHERE presente pero es equivalente a no tener WHERE
- `LIMIT 1000000000` tiene un LIMIT pero es equivalente a no tener LIMIT
- `WHERE email LIKE '%'` filtra teoricamente pero coincide con todas las filas

### Agnostico del motor

La skill aplica reglas universales por defecto. Las reglas especificas del motor se omiten con una nota INFO cuando no se proporciona el motor, evitando suposiciones incorrectas.

### Resolucion de conflictos

Cuando dos reglas producen recomendaciones contradictorias:
- La regla de mayor severidad gana
- Si la severidad es igual: seguridad > rendimiento > convenciones
