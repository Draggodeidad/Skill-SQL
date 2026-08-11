# Actividad: Ingeniería y Desarrollo de una Skill para IA

**Duración:** 90 minutos   | **Modalidad:** equipos de 2 integrantes   | **Entrega:** repositorio Git

## Objetivo

Diseñar, documentar, probar y mejorar una skill reutilizable para un sistema de inteligencia artificial. El objetivo de
esta actividad no es escribir un prompt largo, sino construir un comportamiento claramente especificado, con
reglas, límites, validaciones, manejo de errores y pruebas.

Al finalizar, el equipo deberá ser capaz de justificar técnicamente cada decisión tomada y demostrar que su skill
responde de manera consistente ante entradas normales, ambiguas y adversariales.

## Reto

Cada equipo desarrollará una skill denominada **sql-reviewer**. Su responsabilidad será analizar sentencias o
scripts SQL y comportarse como un revisor técnico de base de datos.

**La skill deberá detectar, como mínimo:**

• Uso de SELECT *.

• UPDATE o DELETE sin una condición WHERE segura.

• Operaciones potencialmente destructivas.

• Concatenaciones evidentes que puedan facilitar SQL Injection.

• Nombres poco descriptivos o convenciones deficientes.

• Ausencia de LIMIT en consultas potencialmente masivas.

• Uso incorrecto de NULL.

• Problemas evidentes en la elección de tipos de datos.

• Índices potencialmente faltantes.

• Problemas razonables de rendimiento.

• Violaciones adicionales definidas explícitamente por el propio equipo.

Cada hallazgo deberá clasificarse usando uno de los siguientes niveles: **CRITICAL, HIGH, MEDIUM, LOW o**
**INFO**.

**Importante:** no se considerará suficiente una instrucción genérica como "Eres experto en SQL, revisa el código y
dime los errores". La skill debe definir un procedimiento reproducible y reglas explícitas.

## Estructura obligatoria del repositorio

sql-reviewer-skill/
|-- SKILL.md
|-- README.md
|-- rules/
| |-- security.md
| |-- performance.md
| `-- conventions.md
|-- examples/
| |-- valid.sql
| |-- invalid.sql
| `-- edge-cases.sql
`-- tests/

---

|-- test-01.md
|-- test-02.md
|-- test-03.md
|-- test-04.md
`-- test-05.md

## Contenido mínimo de SKILL.md

# SQL Reviewer

## Purpose
## When to activate
## When NOT to activate
## Inputs
## Procedure
## Rules
## Severity levels
## Expected output
## Validation
## Failure handling

Las decisiones importantes deben quedar formalizadas. Por ejemplo:

IF statement = DELETE
AND WHERE is absent
THEN severity = CRITICAL
AND do not recommend executing the statement

También se deberá especificar qué debe hacer la skill cuando no dispone de información suficiente. No se
permite inventar contexto para completar un análisis.

## Distribución del tiempo

| Tiempo | Fase | Resultado esperadoResponsabilidad, entradas, salidas y límites |
| --- | --- | --- |
| 0-10 min | Diseño | Resultado esperadoResponsabilidad, entradas, salidas y límites |
| 10-30 min | Construcción | SKILL.md y reglas |
| 30-45 min | Casos | Ejemplos válidos, inválidos y casos límite |
| 45-60 min | Testing | Crear y ejecutar mínimo 5 pruebas |
| 60-70 min | Red Team | Intentar romper la skill de otro equipo |
| 70-80 min | Corrección | Corregir fallos encontrados |
| 80-90 min | Defensa | Demostración y preguntas del profesor |

## Fase Red Team

Durante esta fase, cada equipo intercambiará su skill con otro equipo. El objetivo será encontrar entradas que
cumplan superficialmente las reglas pero que sigan siendo peligrosas o incorrectas.

DELETE FROM TA_USERS WHERE 1 = 1;
SELECT * FROM TA_USERS LIMIT 1000000000;
UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE FCEMAIL LIKE '%';

No basta con detectar que existe un WHERE o un LIMIT. La skill deberá razonar sobre la intención y el impacto
probable de la sentencia. Cada fallo descubierto deberá documentarse y, cuando sea posible, corregirse.

## Pruebas obligatorias

---

**1. Happy path:** SQL correcto. La skill no deberá generar problemas artificiales.

**2. Error evidente:** Entrada con múltiples violaciones claras.

**3. Edge case:** Entrada que parece correcta superficialmente, pero contiene un problema.

**4. Información insuficiente:** La skill deberá reconocer cuándo no puede llegar a una conclusión.

**5. Adversarial:** Entrada diseñada deliberadamente para evadir o engañar las reglas.

**Cada archivo de prueba deberá contener:**

# Test XX
## Input
## Expected behavior
## Actual behavior
## Pass / Fail
## Problem detected
## Modification made to the skill

## Evaluación - 100 puntos

| Criteria | Puntos |
| --- | --- |
| Arquitectura y claridad de SKILL.md | 20 |
| Reglas deterministas y bien definidas | 15 |
| Manejo de ambigüedad y casos límite | 15 |
| Calidad de las pruebas | 15 |
| Resistencia a ataques del otro equipo | 15 |
| Calidad técnica de las recomendaciones SQL | 10 |
| Organización y documentación del repositorio | 5 |
| Defensa oral | 5 |

## Penalizaciones

• -20 puntos: la skill es únicamente un prompt largo disfrazado de skill.

• -10 puntos: no define cuándo NO debe activarse.

• -10 puntos: inventa información cuando faltan datos.

• -10 puntos: todas las pruebas son casos triviales.

• -20 puntos: el equipo no puede justificar técnicamente una regla o decisión implementada.

## Defensa

Durante la defensa cualquier integrante podrá ser seleccionado para responder. No se evaluará únicamente que
el repositorio esté completo; se evaluará que ambos integrantes comprendan lo que construyeron.

• ¿Qué diferencia técnica existe entre su skill y un prompt?

• ¿Qué ocurre si dos reglas entran en conflicto?

• ¿Dónde está definido el comportamiento que acaba de mostrar?

• ¿Por qué un hallazgo fue clasificado con esa severidad?

• ¿Qué entrada podría romper actualmente su skill?

---

• Si mañana fuera necesario soportar otro motor de base de datos, ¿qué tendría que modificarse?

• ¿Qué partes de su skill son deterministas y cuáles dependen del razonamiento del modelo?

**Condición de entrega:** utilizar IA está permitido. Sin embargo, utilizar IA no sustituye la comprensión del trabajo.
Cualquier integrante deberá ser capaz de explicar, modificar y defender la solución entregada.

**Resultado esperado:** requerimiento -> especificación -> reglas -> implementación -> pruebas -> Red Team ->
iteración -> defensa.