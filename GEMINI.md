# Workbench Permanent Directives & System Invariants

## ABSOLUTE FLIGHT METHOD INVARIANT (DOORS & ALL GAMES)
**CRITICAL**: NEVER, UNDER ANY CIRCUMSTANCES, CHANGE OR REPLACE THE FLY / NOCLIP METHOD IN DOORS (OR MEDVED).
- The DOORS fly method is LOCKED PERMANENTLY to the original proven `mgTable.noclip = v` / `syncNativeFlightSpeed(State.Noclip_Speed)` method with clean 3.2-stud floor ground check.
- NEVER replace it with custom velocity physics, NEVER remove `mg.noclip = v` from the toggle, NEVER inject downward raycast snaps, and NEVER continuously overwrite `mgTable.clipPos = root.Position` on Heartbeat.
- This rule is permanently active and immutable across all turns in this chat.

## INTERACTION & IMMUNITY INVARIANTS
- Universal Entity Immunity: `hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)`, `CollisionGroup = "NoPlayer"`, `CanTouch = true`, `CanQuery = true` must ALWAYS remain active both when flying and when walking on the floor.
- Interaction Receptors: Never set `CanTouch = false` on character parts.
- Prompt Stability: Protect against duplicate `fireproximityprompt` calls with clean 150ms debounce so prompts never disappear when clicked.
- Drawer Distance Guard: Drawers must respect 6.5-stud server validation range.
