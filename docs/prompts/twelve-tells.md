# Prompt: give the last twelve tells something to find

Thirty of the forty-two anomalies are observable. Twelve are not — they roll,
the player is told what to look for, and there is nothing there. They are
currently held out of the roll by `UNOBSERVABLE` in `src/shared/Anomalies.luau`.

This prompt brings them back. Each one is small; there are just twelve of them.

```bash
agy --model gemini-3.1-pro-high
```

---

## What already works, and why that matters

Do not rebuild machinery that exists. The pattern for document tells is already
proven by seven working anomalies:

1. `Anomalies.roll` corrupts a field — `idName`, `checkOut`, `roomNum`,
   `reservation`, `city`
2. `Shift.luau` sends that field in the `GuestArrived` payload
3. The ledger's `SurfaceGui` prints it

`name_mismatch`, `wrong_checkout`, `reversed_dates`, `invalid_room_109`,
`fake_reservation_code`, `expired_license` and `wrong_city` all work exactly
this way, with **no client branch at all**. Five of the twelve below are the
same shape — they just need a field on the ledger that does not exist yet.

---

```
Read src/shared/Anomalies.luau, src/client/DeskProps.luau (the ledger
SurfaceGui) and src/server/Shift.luau before writing anything.

CONTEXT
30 of 42 anomalies are observable. 12 are not: they roll, the player is told
what to look for, and nothing is there. They are held out of the roll by the
UNOBSERVABLE table in Anomalies.luau, which documents what each one needs.

Your job is to give each of the 12 an observable and delete it from that table.
The table shrinking to empty is the definition of done.

DO NOT invent a new system for these. Seven document tells already work by a
proven three-step pattern -- roll corrupts a field, Shift sends it, the ledger
prints it -- with no client branch. Follow it.

THE TWELVE, GROUPED BY WHAT THEY NEED

A. LEDGER NEEDS A NEW PRINTED FIELD (5) -- follow the existing pattern exactly
   - impossible_zip      -> add a postal code line; corrupt it to "00000"
   - negative_stay       -> add a length-of-stay line; corrupt it to "-3 nights"
   - forged_signature    -> add a signature line rendered in a handwriting font;
                            the anomaly renders it in a clean printed font instead
   - counterfeit_watermark -> the ledger already has uvWatermarkLabel showing
                            "★ OFFICIAL CRESTVIEW SEAL ★". Corrupt it to drop
                            the left star. The tell already says exactly this.
   - redacted_id         -> add a small ID photo frame; the anomaly blurs or
                            darkens the eye region

B. NEEDS A GUESTRENDERER BRANCH (2)
   - perfect_symmetry    -> mirror one half of the face onto the other. Real
                            faces are never symmetrical, which is the whole tell.
   - flickering_presence -> briefly drop the guest's transparency and restore it,
                            rarely and fast enough to be doubted

C. THE PHONE MUST ANSWER DIFFERENTLY (3)
   The rotary phone [T] already exists and fires CallRoom / PhoneResponse.
   - phone_occupied_room  -> the assigned room answers when it should be empty
   - phone_whisper_echo   -> the guest's own voice echoes back down the line
   - phone_static_screamer -> a burst of static. Use it sparingly; it is tier 3.
   The response must be readable in the existing subtitle banner.

D. POSITIONAL AUDIO (1)
   - whispering_vents    -> a quiet looping whisper from a vent in the lobby,
                            spatial so the player must turn their head to find it.
                            Read docs/ROBLOX.md section 7 on falloff first.

E. UV (1)
   - uv_counterfeit_seal -> this one already corrupts uvSymbol, but only
                            uv_occult_rune and uv_bloodied_hands build the UV
                            parts that the reveal toggles, so it has nothing to
                            light up. Give it a UV-visible mark on the document.

CONSTRAINTS
- The server decides. Corrupt fields in Anomalies.roll, never on the client.
- Every one you finish, DELETE from UNOBSERVABLE. Do not leave it listed.
- Do not touch src/server/State.luau, Atmosphere.shakeCamera, or the
  Anomalies.rollable pool mechanism itself.
- Keep the tells' wording as written. They are already good and the player has
  been shown them; make the world match the text, not the other way round.
- rojo build, selene src/ tools/, stylua src/ tools/. There are 2 known warnings
  about unused parameters on buildHorrorArchetypes -- do not add more.
- Commit AND push.

REPORT
- Which of the 12 you finished, and which you could not.
- The final contents of UNOBSERVABLE. Empty is the goal; say so if it is not.
- For each one you finished, name the file and how a player observes it.
```

---

## Review checklist (Claude, after agy finishes)

| check | why |
|---|---|
| `UNOBSERVABLE` actually shrank | the table is the contract; a tell removed from it must genuinely be findable |
| new ledger fields are corrupted server-side | corrupting on the client hands the answer to an exploiter |
| no new client branch for document tells | they work by printed field; a branch means it rebuilt the machinery |
| tell wording unchanged | the text is already good, and players were shown it |
| selene still at 2 warnings, not more | new dead code is how the last pass hid unimplemented branches |
| rollable count rises toward 42 | count it, do not trust the summary |
| pushed, not just committed | forgotten twice now |
