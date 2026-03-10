# Protocolos de Validación - Sistema de Validación Multicapa

**ID:** DOC-FLU-VAL-001
**Versión:** 2.1.0
**Fecha:** 2026-03-09
**Nivel:** Componente Core
**Dependencias:** [Arquitectura Maestra](../01-SISTEMA/00-arquitectura-maestra.md)

---

## Resumen Ejecutivo

El sistema de validación de OPENCLAW implementa múltiples capas de comprobación que aseguran la calidad, coherencia y seguridad de todas las operaciones. Combina validación automática (AI-in-the-loop) con puntos de aprobación humana (Human-in-the-loop) para garantizar outputs confiables.

---

## 1. Arquitectura de Validación Multicapa

### Visión General de las 5 Capas

```
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 5: APROBACIÓN HUMANA                                      │
│  ────────────────────────────────────────────────────────────── │
│  Aprobación humana para operaciones críticas y destructivas     │
│  • Capacidad de override                                        │
│  • Escalamiento de conflictos                                   │
│  • Trazado de auditoría de decisiones humanas                   │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 4: VALIDACIÓN CRUZADA                                     │
│  ────────────────────────────────────────────────────────────── │
│  Segunda opinión de otra unidad especialista                    │
│  • Validación cruzada para tareas críticas                      │
│  • Consistencia semántica entre unidades                        │
│  • Resolución de discrepancias                                  │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 3: REVISIÓN DEL CATEDRÁTICO                               │
│  ────────────────────────────────────────────────────────────── │
│  Revisión por Catedrático antes de entrega                      │
│  • Validación de calidad                                        │
│  • Coherencia con políticas del dominio                         │
│  • Aprobación para entregar al usuario                          │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 2: IA-EN-EL-CICLO                                         │
│  ────────────────────────────────────────────────────────────── │
│  Supervisión automática por IA en puntos críticos               │
│  • Detección de anomalías                                       │
│  • Verificación de coherencia semántica                         │
│  • Validación de fuentes                                        │
│  • Control de calidad automático                                │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 1: VALIDACIÓN TRI-AGENTE (Interna)                        │
│  ────────────────────────────────────────────────────────────── │
│  Validación dentro de la unidad tri-agente                      │
│  • Director ↔ Ejecutor ↔ Archivador                             │
│  • Debate interno antes de output                               │
│  • Consenso requerido para proceder                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Capa 1: Validación Tri-Agente (Interna)

### Principio

Cada unidad especialista (tri-agente) implementa validación interna antes de producir output. Los tres agentes (Director, Ejecutor, Archivador) deben llegar a consenso.

### Proceso de Validación Interna

```
┌─────────────────────────────────────────────────────────────────┐
│                    UNIDAD TRI-AGENTE                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │   DIRECTOR   │────►│   EJECUTOR   │────►│  ARCHIVADOR  │    │
│  │              │     │              │     │              │    │
│  │  1. Plan     │     │  2. Ejecutar │     │  3. Validar  │    │
│  │  2. Revisar  │◄────│  3. Reportar │◄────│  4. Aprobar/ │    │
│  │  3. Aprobar  │     │              │     │     Rechazar │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│         │                    │                    │              │
│         └────────────────────┴────────────────────┘              │
│                              │                                   │
│                    ┌─────────▼─────────┐                         │
│                    │   ¿CONSENSO?      │                         │
│                    │   Sí → Output     │                         │
│                    │   No → Iterar     │                         │
│                    └───────────────────┘                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Reglas de Consenso

```typescript
// src/validation/consenso-tri-agente.ts

interface Tarea {
  esCritico: boolean;
  // ... otras propiedades
}

interface Resultado {
  // ... propiedades del resultado
}

interface Aprobacion {
  aprobado: boolean;
  razon?: string;
}

enum ResultadoConsenso {
  APROBADO = 'APROBADO',
  RECHAZADO = 'RECHAZADO'
}

interface ResultadoConsensoCompleto {
  resultado: ResultadoConsenso;
  razones?: string[];
}

export class ConsensoTriAgente {
  /**
   * Reglas para llegar a consenso en tri-unidad.
   */

  async validate(task: Tarea, result: Resultado): Promise<ResultadoConsensoCompleto> {
    // Director valida el plan
    const aprobacionDirector: Aprobacion = await this.director.validarPlan(task);

    // Ejecutor valida la ejecución
    const aprobacionEjecutor: Aprobacion = await this.ejecutor.validarEjecucion(result);

    // Archivador valida coherencia
    const aprobacionArchivador: Aprobacion = await this.archivador.validarCoherencia(result);

    // Consenso requiere 3/3 aprobaciones para output crítico
    // Consenso requiere 2/3 aprobaciones para output normal
    const umbral = task.esCritico ? 3 : 2;
    const aprobaciones = [
      aprobacionDirector.aprobado,
      aprobacionEjecutor.aprobado,
      aprobacionArchivador.aprobado
    ].filter(Boolean).length;

    if (aprobaciones >= umbral) {
      return { resultado: ResultadoConsenso.APROBADO };
    } else {
      const razones = [
        !aprobacionDirector.aprobado ? aprobacionDirector.razon : null,
        !aprobacionEjecutor.aprobado ? aprobacionEjecutor.razon : null,
        !aprobacionArchivador.aprobado ? aprobacionArchivador.razon : null
      ].filter((r): r is string => r);

      return {
        resultado: ResultadoConsenso.RECHAZADO,
        razones
      };
    }
  }
}
```

### Tipos de Validación Interna

| Tipo | Descripción | Responsable |
|------|-------------|-------------|
| **Validación Plan** | Verificar que el plan es viable | Director |
| **Validación Ejecución** | Verificar que el resultado es correcto | Ejecutor |
| **Validación Coherencia** | Verificar coherencia semántica | Archivador |
| **Validación Fuentes** | Verificar fuentes utilizadas | Archivador |
| **Validación Memoria** | Verificar consistencia con memoria | Archivador |

---

## 3. Capa 2: IA-en-el-Ciclo

### Principio

Supervisión automática por IA en puntos críticos del sistema. No requiere intervención humana pero añade verificación adicional.

### Puntos de Intervención IA

```
┌─────────────────────────────────────────────────────────────────┐
│                    PUERTAS IA-EN-EL-CICLO                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Puerta 1: CLASIFICACIÓN DE ENTRADA                            │
│  ├── Detección de intent malicioso                             │
│  ├── Clasificación de complejidad                              │
│  └── Validación de routing                                     │
│                                                                 │
│  Puerta 2: MONITOREO DE EJECUCIÓN                              │
│  ├── Detección de anomalías en tiempo real                     │
│  ├── Monitoreo de uso de recursos                              │
│  └── Detección de timeout y bucles                             │
│                                                                 │
│  Puerta 3: VALIDACIÓN DE SALIDA                                │
│  ├── Verificación de coherencia semántica                      │
│  ├── Verificación de hechos                                    │
│  ├── Atribución de fuentes                                     │
│  └── Puntuación de calidad                                     │
│                                                                 │
│  Puerta 4: CONSISTENCIA DE MEMORIA                             │
│  ├── Coherencia cruzada de memoria                             │
│  ├── Sin contradicciones                                       │
│  └── Indexación apropiada                                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Implementación de Gates

```python
class IAEnElCiclo:
    """
    Sistema de validación automática IA-en-el-ciclo.
    """

    def __init__(self):
        self.detector_anomalias = DetectorAnomalias()
        self.verificador_coherencia = VerificadorCoherenciaSemantica()
        self.verificador_hechos = VerificadorHechos()
        self.puntuador_calidad = PuntuadorCalidad()

    def puerta_clasificacion_entrada(self, entrada: EntradaUsuario) -> ResultadoPuerta:
        """Puerta 1: Validar entrada antes de procesar"""
        resultados = []

        # Detección de intent malicioso
        if self.detector_anomalias.es_malicioso(entrada):
            return ResultadoPuerta.BLOQUEAR(
                razon="Entrada potencialmente maliciosa detectada",
                escalar_a="SEGURIDAD"
            )

        # Clasificación de complejidad
        complejidad = self.clasificar_complejidad(entrada)
        resultados.append(f"Complejidad: {complejidad}")

        # Validación de routing
        routing_valido = self.validar_routing(entrada)
        if not routing_valido:
            return ResultadoPuerta.BLOQUEAR(
                razon="Routing inválido detectado",
                escalar_a="ROUTER"
            )

        return ResultadoPuerta.PASAR(resultados)

    def puerta_validacion_salida(self, salida: Salida) -> ResultadoPuerta:
        """Puerta 3: Validar salida antes de entregar"""
        resultados = []

        # Coherencia semántica
        coherencia = self.verificador_coherencia.verificar(salida)
        if coherencia.puntuacion < 0.7:
            return ResultadoPuerta.MARCAR(
                razon=f"Coherencia semántica baja: {coherencia.puntuacion}",
                requiere_revision=True
            )
        resultados.append(f"Coherencia: {coherencia.puntuacion}")

        # Verificación de hechos
        verificacion_hechos = self.verificador_hechos.verificar(salida)
        if verificacion_hechos.tiene_afirmaciones_no_verificadas:
            return ResultadoPuerta.MARCAR(
                razon="Afirmaciones no verificadas detectadas",
                afirmaciones=verificacion_hechos.afirmaciones_no_verificadas
            )
        resultados.append(f"Hechos verificados: {verificacion_hechos.cantidad_verificada}")

        # Puntuación de calidad
        calidad = self.puntuador_calidad.puntuar(salida)
        if calidad.puntuacion < 0.6:
            return ResultadoPuerta.MARCAR(
                razon=f"Puntuación de calidad baja: {calidad.puntuacion}",
                requiere_regeneracion=True
            )
        resultados.append(f"Calidad: {calidad.puntuacion}")

        return ResultadoPuerta.PASAR(resultados)

    def puerta_consistencia_memoria(self, actualizacion_memoria: ActualizacionMemoria) -> ResultadoPuerta:
        """Puerta 4: Validar consistencia de memoria"""
        # Verificar no contradicciones
        contradicciones = self.encontrar_contradicciones(actualizacion_memoria)
        if contradicciones:
            return ResultadoPuerta.BLOQUEAR(
                razon="Contradicción en memoria detectada",
                contradicciones=contradicciones
            )

        return ResultadoPuerta.PASAR()
```

### Scoring de Calidad

```python
class PuntuadorCalidad:
    """
    Puntuación de calidad para salidas.
    """

    def puntuar(self, salida: Salida) -> PuntuacionCalidad:
        puntuaciones = {}

        # Completitud (0-1)
        puntuaciones['completitud'] = self.evaluar_completitud(salida)

        # Relevancia (0-1)
        puntuaciones['relevancia'] = self.evaluar_relevancia(salida)

        # Coherencia (0-1)
        puntuaciones['coherencia'] = self.evaluar_coherencia(salida)

        # Precisión (0-1)
        puntuaciones['precision'] = self.evaluar_precision(salida)

        # Utilidad (0-1)
        puntuaciones['utilidad'] = self.evaluar_utilidad(salida)

        # Puntuación final ponderada
        pesos = {
            'completitud': 0.25,
            'relevancia': 0.25,
            'coherencia': 0.20,
            'precision': 0.20,
            'utilidad': 0.10
        }

        puntuacion_final = sum(
            puntuaciones[k] * pesos[k] for k in puntuaciones
        )

        return PuntuacionCalidad(
            puntuacion=puntuacion_final,
            componentes=puntuaciones,
            aprobada=puntuacion_final >= 0.6
        )
```

---

## 4. Capa 3: Domain Chief Review

### Principio

El Catedrático del dominio revisa y aprueba el resultado antes de entregar al usuario. Esta es la responsabilidad principal de cada Domain Chief.

### Flujo de Review

```
┌─────────────────────────────────────────────────────────────────┐
│                    DOMAIN CHIEF REVIEW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Input: Resultado de Specialist Unit                            │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────┐                                            │
│  │ 1. QUALITY CHECK│  ¿Cumple estándares de calidad?           │
│  └────────┬────────┘                                            │
│           │                                                     │
│     ┌─────┴─────┐                                               │
│     │           │                                               │
│    PASS        FAIL                                             │
│     │           │                                               │
│     ▼           ▼                                               │
│  ┌───────┐  ┌─────────────┐                                     │
│  │ 2.    │  │ Request     │                                     │
│  │ POLICY│  │ Revision    │                                     │
│  │ CHECK │  └─────────────┘                                     │
│  └───┬───┘                                                     │
│      │                                                         │
│  ┌───┴───────────┐                                             │
│  │               │                                             │
│ PASS           FAIL                                            │
│  │               │                                             │
│  ▼               ▼                                             │
│ ┌─────────┐  ┌─────────────┐                                    │
│ │APPROVE  │  │ Escalate to │                                    │
│ │& DELIVER│  │ Cross-Check │                                    │
│ └─────────┘  └─────────────┘                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Responsabilidades del Domain Chief

```python
class DomainChiefReviewer:
    """
    Proceso de revisión por Domain Chief.
    """

    def review(self, unit_result: UnitResult, task: Task) -> ReviewResult:
        # 1. Quality Check
        quality = self.check_quality(unit_result)
        if not quality.passed:
            return ReviewResult.REQUEST_REVISION(
                issues=quality.issues,
                suggestions=quality.improvements
            )

        # 2. Policy Check
        policy = self.check_policy_compliance(unit_result, task)
        if not policy.compliant:
            return ReviewResult.NON_COMPLIANT(
                violations=policy.violations,
                require_escalation=True
            )

        # 3. Domain Coherence
        coherence = self.check_domain_coherence(unit_result)
        if not coherence.coherent:
            return ReviewResult.INCOHERENT(
                issues=coherence.issues
            )

        # 4. Approve
        return ReviewResult.APPROVED(
            confidence=quality.score * policy.score * coherence.score,
            ready_for_delivery=True
        )

    def check_quality(self, result: UnitResult) -> QualityCheck:
        """Verificar calidad según estándares del dominio"""
        checks = []

        # Completitud
        if result.is_complete():
            checks.append(Check.PASS("Completeness"))
        else:
            checks.append(Check.FAIL("Incomplete result"))

        # Precisión técnica
        if self.verify_technical_accuracy(result):
            checks.append(Check.PASS("Technical accuracy"))
        else:
            checks.append(Check.FAIL("Technical inaccuracies detected"))

        # Fuentes citadas
        if result.has_proper_sources():
            checks.append(Check.PASS("Source attribution"))
        else:
            checks.append(Check.WARN("Missing source attribution"))

        return QualityCheck(
            passed=all(c.passed for c in checks),
            checks=checks
        )

    def check_policy_compliance(self, result: UnitResult, task: Task) -> PolicyCheck:
        """Verificar cumplimiento de políticas del dominio"""
        violations = []

        # Verificar no excede scope
        if result.exceeds_scope(task):
            violations.append("Result exceeds task scope")

        # Verificar no contiene información prohibida
        if result.contains_prohibited_content():
            violations.append("Contains prohibited content")

        # Verificar compliance con regulaciones (si aplica)
        if task.has_regulatory_requirements:
            if not result.meets_regulations(task.regulations):
                violations.append("Regulatory compliance issues")

        return PolicyCheck(
            compliant=len(violations) == 0,
            violations=violations
        )
```

---

## 5. Capa 4: Cross-Unit Validation

### Principio

Para tareas críticas, una segunda unidad especialista valida el resultado de la primera. Proporciona "segunda opinión".

### Cuándo Aplicar

| Situación | Cross-Unit Required |
|-----------|---------------------|
| Tareas críticas de producción | ✅ Siempre |
| Operaciones financieras | ✅ Siempre |
| Cambios de infraestructura | ✅ Siempre |
| Contenido médico/legal | ✅ Siempre |
| Decisiones arquitectónicas | ✅ Siempre |
| Tareas rutinarias | ❌ No requerido |
| Consultas simples | ❌ No requerido |

### Proceso de Cross-Validation

```python
class CrossUnitValidator:
    """
    Validación cruzada entre unidades especialistas.
    """

    def __init__(self, unit_registry: UnitRegistry):
        self.registry = unit_registry

    def request_cross_validation(
        self,
        original_result: UnitResult,
        task: Task,
        domain: str
    ) -> CrossValidationResult:

        # Obtener segunda unidad del mismo dominio o dominio relacionado
        second_unit = self.registry.get_different_unit(domain)

        if not second_unit:
            return CrossValidationResult.SKIPPED(
                reason="No second unit available"
            )

        # Enviar para revisión
        review_request = CrossReviewRequest(
            original_task=task,
            original_result=original_result,
            review_type="validation"
        )

        review_result = second_unit.review(review_request)

        # Comparar resultados
        if review_result.agrees_with(original_result):
            return CrossValidationResult.CONFIRMED(
                validator=second_unit.id,
                confidence=review_result.confidence
            )
        else:
            # Discrepancia detectada
            return CrossValidationResult.DISCREPANCY(
                original=original_result,
                review=review_result,
                discrepancies=self.identify_discrepancies(
                    original_result,
                    review_result
                ),
                require_resolution=True
            )

    def resolve_discrepancy(
        self,
        original: UnitResult,
        review: ReviewResult,
        discrepancies: list
    ) -> Resolution:

        # Estrategias de resolución
        strategies = [
            self.try_consensus,      # Unidades negocian
            self.try_synthesis,      # Sintetizar ambas perspectivas
            self.escalate_to_chief,  # Chief decide
            self.escalate_to_human   # Humano decide
        ]

        for strategy in strategies:
            resolution = strategy(original, review, discrepancies)
            if resolution.success:
                return resolution

        return Resolution.UNRESOLVED(
            require_human_intervention=True
        )
```

---

## 6. Capa 5: Human-in-the-Loop

### Principio

Puntos donde un humano debe aprobar, validar o intervenir. Requerido para operaciones críticas, destructivas, o cuando el sistema no puede resolver automáticamente.

### Puntos de Intervención Humana

```
┌─────────────────────────────────────────────────────────────────┐
│                    HUMAN-IN-THE-LOOP GATES                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ MANDATORY HUMAN APPROVAL                                │   │
│  │                                                         │   │
│  │ • Operaciones destructivas (rm, drop, delete)           │   │
│  │ • Cambios en configuración de producción                │   │
│  │ • Despliegues a producción                              │   │
│  │ • Operaciones financieras (> threshold)                 │   │
│  │ • Acceso a datos sensibles                              │   │
│  │ • Modificación de políticas del sistema                │   │
│  │ • Creación de nuevos dominios (configurable)           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ CONDITIONAL HUMAN APPROVAL                              │   │
│  │                                                         │   │
│  │ • Discrepancias no resueltas entre unidades            │   │
│  │ • Low confidence outputs (< 0.5)                        │   │
│  │ • Novedad detectada (patrón no conocido)               │   │
│  │ • Escalamiento por cualquier Chief                      │   │
│  │ • Solicitud explícita del usuario                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ HUMAN OVERRIDE CAPABILITIES                             │   │
│  │                                                         │   │
│  │ • Override cualquier decisión del sistema               │   │
│  │ • Forzar aprobación de operación bloqueada              │   │
│  │ • Modificar reglas de validación                        │   │
│  │ • Añadir excepciones permanentes                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Sistema de Aprobación Humana

```python
class HumanInTheLoop:
    """
    Sistema de aprobación e intervención humana.
    """

    def __init__(self, notification_system, approval_queue):
        self.notifications = notification_system
        self.queue = approval_queue
        self.timeout = timedelta(minutes=30)  # Timeout por defecto

    def request_approval(
        self,
        operation: Operation,
        context: ApprovalContext,
        urgency: Urgency = Urgency.NORMAL
    ) -> ApprovalResult:

        # Crear solicitud de aprobación
        request = ApprovalRequest(
            id=generate_uuid(),
            operation=operation,
            context=context,
            urgency=urgency,
            created_at=datetime.now(),
            expires_at=datetime.now() + self.timeout
        )

        # Determinar quiénes pueden aprobar
        approvers = self.get_authorized_approvers(operation)
        request.authorized_approvers = approvers

        # Encolar
        self.queue.add(request)

        # Notificar
        self.notifications.send(
            recipients=approvers,
            subject=f"[{urgency}] Approval Required: {operation.type}",
            body=self.format_approval_request(request),
            channels=self.get_notification_channels(urgency)
        )

        # Esperar respuesta (con timeout)
        result = self.wait_for_response(request)

        return result

    def wait_for_response(self, request: ApprovalRequest) -> ApprovalResult:
        """Esperar respuesta humana con timeout"""
        while datetime.now() < request.expires_at:
            response = self.queue.check_response(request.id)

            if response:
                # Log de decisión humana
                self.audit_log.record_human_decision(
                    request=request,
                    response=response,
                    approver=response.approver
                )

                return ApprovalResult(
                    approved=response.approved,
                    approver=response.approver,
                    comments=response.comments,
                    timestamp=response.timestamp
                )

            # Esperar antes de checkear de nuevo
            sleep(5)

        # Timeout
        return ApprovalResult.TIMEOUT(
            request=request,
            action_on_timeout=self.get_timeout_action(request)
        )

    def process_override(
        self,
        approver: str,
        operation: Operation,
        reason: str
    ) -> OverrideResult:
        """Procesar override humano de decisión del sistema"""

        # Verificar autorización
        if not self.is_authorized_for_override(approver, operation):
            return OverrideResult.DENIED(
                reason="Not authorized for override"
            )

        # Registrar override
        self.audit_log.record_override(
            approver=approver,
            operation=operation,
            reason=reason,
            timestamp=datetime.now()
        )

        # Ejecutar override
        return OverrideResult.GRANTED(
            approver=approver,
            operation=operation,
            audit_id=self.audit_log.last_id
        )
```

### Notification Channels

```python
class NotificationChannels:
    """
    Canales de notificación para aprobaciones humanas.
    """

    def get_channels(self, urgency: Urgency) -> list:
        if urgency == Urgency.CRITICAL:
            return [
                Channel.PUSH_NOTIFICATION,
                Channel.SMS,
                Channel.EMAIL,
                Channel.SLACK
            ]
        elif urgency == Urgency.HIGH:
            return [
                Channel.PUSH_NOTIFICATION,
                Channel.EMAIL,
                Channel.SLACK
            ]
        elif urgency == Urgency.NORMAL:
            return [
                Channel.EMAIL,
                Channel.SLACK
            ]
        else:  # LOW
            return [
                Channel.EMAIL
            ]
```

### Audit Trail de Decisiones Humanas

```python
class HumanDecisionAudit:
    """
    Registro de auditoría para todas las decisiones humanas.
    """

    def record_human_decision(
        self,
        request: ApprovalRequest,
        response: ApprovalResponse,
        approver: str
    ):
        record = {
            "id": generate_uuid(),
            "timestamp": datetime.now().isoformat(),
            "request_id": request.id,
            "operation_type": request.operation.type,
            "operation_details": request.operation.to_dict(),
            "context": request.context.to_dict(),
            "decision": "APPROVED" if response.approved else "REJECTED",
            "approver": approver,
            "comments": response.comments,
            "response_time_seconds": (
                response.timestamp - request.created_at
            ).total_seconds(),
            "urgency": request.urgency.value
        }

        self.db.insert("human_decisions", record)

        # También guardar en log inmutable
        self.immutable_log.append(record)
```

---

## 7. Flujo Completo de Validación

### Ejemplo End-to-End

```
Usuario: "/dev implementar autenticación JWT para API producción"

┌─────────────────────────────────────────────────────────────────┐
│ CAPA 2: AI-IN-THE-LOOP (Gate 1: Input)                         │
│ ✅ Input classificado como "desarrollo crítico"                 │
│ ✅ No malicious intent detectado                                │
│ ✅ Routing a /dev → CEngO validado                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ CAPA 1: TRI-AGENT VALIDATION (DEV Unit)                         │
│ Director: Planifica enfoque JWT                                 │
│ Ejecutor: Implementa código                                     │
│ Archivador: Valida coherencia con arquitectura existente        │
│ ✅ Consenso 3/3 alcanzado                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ CAPA 2: AI-IN-THE-LOOP (Gate 3: Output)                        │
│ ✅ Coherencia semántica: 0.92                                   │
│ ✅ Facts verificados: 5/5                                       │
│ ✅ Quality score: 0.88                                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ CAPA 3: DOMAIN CHIEF REVIEW (CEngO)                            │
│ ✅ Quality check passed                                         │
│ ✅ Policy compliance verified                                   │
│ ✅ Domain coherence confirmed                                   │
│ ⚠️ FLAGGED: Cambio en producción requiere aprobación           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ CAPA 5: HUMAN-IN-THE-LOOP                                       │
│ 📧 Approval request sent to: ruben@domain.com                  │
│ ⏳ Waiting for human approval...                                │
│                                                                 │
│ [30 min después]                                                │
│ ✅ APPROVED by: ruben@domain.com                                │
│ 📝 Comments: "Proceder con despliegue en staging primero"       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ DELIVERY                                                         │
│ Resultado entregado al usuario con:                             │
│ • Código JWT implementado                                       │
│ • Tests unitarios                                               │
│ • Documentación                                                 │
│ • Audit trail completo                                          │
│ • Human approval record                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. Configuración de Validación

### Archivo de Configuración

```yaml
# config/validation.yaml

validation:
  layers:
    tri_agent:
      enabled: true
      consensus_threshold:
        critical: 1.0      # 3/3 para crítico
        normal: 0.67       # 2/3 para normal
      max_iterations: 3

    ai_in_the_loop:
      enabled: true
      gates:
        input_classification: true
        execution_monitoring: true
        output_validation: true
        memory_consistency: true
      thresholds:
        coherence: 0.7
        quality: 0.6
        fact_verification: 0.8

    domain_chief:
      enabled: true
      always_required: true
      timeout_minutes: 60

    cross_unit:
      enabled: true
      triggers:
        - production_changes
        - financial_operations
        - infrastructure_changes
        - medical_legal_content
        - architectural_decisions

    human_in_the_loop:
      enabled: true
      mandatory_for:
        - destructive_operations
        - production_deployments
        - financial_operations_above: 1000
        - sensitive_data_access
        - policy_modifications
      timeout_minutes: 30
      escalation:
        on_timeout: "notify_and_wait"
        max_escalations: 3

  audit:
    log_all_decisions: true
    immutable_storage: true
    retention_days: 365
```

---

## 9. Métricas de Validación

### KPIs

| Métrica | Target | Descripción |
|---------|--------|-------------|
| **Tri-Agent Consensus Rate** | > 95% | % de outputs con consenso 3/3 |
| **AI Gate Pass Rate** | > 90% | % de outputs que pasan gates AI |
| **Human Approval Rate** | > 98% | % de operaciones aprobadas por humanos |
| **False Positive Rate** | < 5% | % de falsas alertas de validación |
| **Avg Validation Time** | < 2s | Tiempo promedio de validación automática |
| **Human Response Time** | < 30min | Tiempo promedio de respuesta humana |
| **Audit Completeness** | 100% | % de operaciones con audit trail |

---

## Referencias

- [Arquitectura Maestra](../01-SISTEMA/00-arquitectura-maestra.md)
- [Arquitectura de Memoria](../09-MEMORIA/00-arquitectura-memoria.md)
- [Bus de Mensajes](01-mensaje-bus.md)

---

**Documento:** Protocolos de Validación - Sistema de Validación Multicapa
**Ubicación:** `docs/08-FLUJOS/02-validacion.md`
**Versión:** 2.1.0
**Fecha:** 2026-03-09
