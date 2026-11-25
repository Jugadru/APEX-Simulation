# APEX 0.6.6.9.22 — Race Engineer 4.0 (candidate)
Base: 9.21, sporting revision 040. Presentation-only candidate; no new sporting revision or changes to decision authority.
- Existing radio and HUD retained; contextual diagnoses from current tyre, weather, wake, recovery and traffic evidence.
- Presentation-only communication bus: bounded history (32 per driver), pending queue (16), priority, expiry, cooldown and structured audio metadata.
- Administrative mode/control messages suppressed at commentary boundary; retained in engine telemetry. No changes to command validator or BOX V21.
- Original English pass acknowledgements with understated dry humour. No historical recordings or imitation of actual voices.
- Consultations: diagnosis, recovery, climate, strategy, KERS/DRS, in addition to original questions.
- Session-only conversation records and counters, no career relationship or sporting modifiers.
- References for design: Formula 1 official Lambiase/Verstappen radio compilation https://www.formula1.com/en/video/gianpiero-lambiase-max-verstappens-most-iconic-radio-moments.1865062761376363648 ; RaceFans Alonso/Stella transcript https://www.racefans.net/2010/11/17/alonsos-role-in-ferrari-strategy-revealed-in-pit-messages/ .
- Native FAST test registered; status NOT_RUN until CI evidence. Test covers mode suppression, diagnosis, memory, priority, expiry, RNG and sporting hash parity, BOX V21. No FULL, GPU or CPU benchmark verified.
- Remaining: staff-specific competencies and persistent relationship, full bilingual catalogue, explicit audio playback, full integration of legacy radio sources into one queue, graphical QA, multiseed and long-race performance. Do not merge before review and verification.
Rollback: discard candidate branch; main remains 9.21.
