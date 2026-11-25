# APEX 0.6.6.9.22 — Race Engineer 4.0 (candidate)
Base: 9.21, sporting revision 040. Presentation-only candidate; no new sporting revision or changes to decision authority.
- Existing radio and HUD retained; contextual diagnoses from current tyre, weather, wake, recovery and traffic evidence.
- Presentation-only communication bus: bounded history (32 per driver), pending queue (16), priority, expiry, cooldown and structured audio metadata.
- Administrative mode/control messages suppressed at commentary boundary; retained in engine telemetry. No changes to command validator or BOX V21.
- Original English pass acknowledgements, dry humour, paired pilot/engineer dialogue when pressure is low, and nearby rival-pass notices only when a fresh confirmed pass contains a position. Fictional voice profiles CALM/DEADPAN/TECHNICAL. Existing staff level changes sustained-evidence diagnosis latency, never sporting performance. No historical recordings or imitation of actual voices.
- Consultations: diagnosis, recovery, climate, strategy, KERS/DRS, in addition to original questions.
- Session-only conversation records and counters, no career relationship or sporting modifiers.
- References for design: Formula 1 official Lambiase/Verstappen radio compilation https://www.formula1.com/en/video/gianpiero-lambiase-max-verstappens-most-iconic-radio-moments.1865062761376363648 ; RaceFans Alonso/Stella transcript https://www.racefans.net/2010/11/17/alonsos-role-in-ferrari-strategy-revealed-in-pit-messages/ .
- Native FAST test registered, plus 12 scenario jobs (ITA/GBR/MON, dry/heavy rain, seeds 42/123, 1800 ticks) with explicit observer CPU measurement. Test covers mode suppression, six errors, diagnosis, memory, priority, expiry, staff interpretation latency, pass dialogue, RNG and sporting hash parity, BOX V21. Status NOT_RUN for final candidate until CI evidence. No FULL, GPU or CPU benchmark verified.
- Remaining: real individual staff profile/contract linkage and persistent relationship, full bilingual catalogue, explicit audio playback, full integration of legacy radio sources into one queue, graphical QA, verification of multiseed/long-race performance. Do not merge before review and verification.
Rollback: discard candidate branch; main remains 9.21.
