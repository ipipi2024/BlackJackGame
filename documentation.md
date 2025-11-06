# CalculateHandValue Procedure Documentation

## Overview
The `CalculateHandValue` procedure calculates the optimal total value of a blackjack hand, implementing the "soft hand" logic where Aces can count as either 1 or 11.

## Procedure Signature
- **Input:**
  - `ESI` = pointer to hand array (DWORD array of card ranks 1-13)
  - `ECX` = hand size (number of cards)
- **Output:**
  - `EAX` = total hand value (optimized)
- **Modifies:** `EAX`, `EBX`, `ECX`, `EDX`

## Algorithm Flow

```
┌─────────────────────────────────────┐
│  Start: Initialize Variables        │
│  - total (EAX) = 0                  │
│  - aceCount (EBX) = 0               │
│  - counter (EDI) = hand size        │
└──────────────┬──────────────────────┘
               │
               ▼
        ┌──────────────┐
        │ Hand empty?  │
        └──────┬───────┘
          No   │   Yes
               │   └──────► Return 0
               ▼
┌──────────────────────────────────────┐
│  PHASE 1: Sum all cards              │
│  (Aces initially count as 1)         │
└──────────────┬───────────────────────┘
               │
               ▼
        ┌─────────────────┐
        │  For each card: │
        │  1. Get rank    │
        │  2. Is Ace?     │◄─────┐
        │     Yes: inc    │      │
        │     aceCount    │      │
        │  3. Convert to  │      │
        │     value       │      │
        │  4. Add to      │      │
        │     total       │      │
        └────────┬────────┘      │
                 │                │
                 └─ More cards? ──┘
                 │  (loop)
                 │ Done
                 ▼
┌──────────────────────────────────────┐
│  PHASE 2: Ace Optimization           │
│  (Try to use one Ace as 11)          │
└──────────────┬───────────────────────┘
               │
               ▼
        ┌──────────────┐
        │ aceCount > 0?│
        └──────┬───────┘
          No   │   Yes
          │    │
          │    ▼
          │  ┌─────────────────────┐
          │  │ Try: total += 10    │
          │  │ (makes one Ace = 11)│
          │  └─────────┬───────────┘
          │            │
          │            ▼
          │     ┌──────────────┐
          │     │ total <= 21? │
          │     └──────┬───────┘
          │       Yes  │   No
          │       │    │
          │       │    ▼
          │       │  ┌──────────────┐
          │       │  │ Revert:      │
          │       │  │ total -= 10  │
          │       │  └──────┬───────┘
          │       │         │
          │       └─────────┘
          │                │
          └────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ Return total│
                    └─────────────┘
```

## Detailed Step-by-Step Example

### Example 1: Ace and King (Blackjack - Soft 21)
**Hand:** Ace, King

**Phase 1 - Initial Calculation:**
```
Card 1: Ace (rank 1)
  - aceCount = 1
  - GetCardValue(1) = 1
  - total = 0 + 1 = 1

Card 2: King (rank 13)
  - aceCount = 1 (unchanged)
  - GetCardValue(13) = 10
  - total = 1 + 10 = 11
```

**Phase 2 - Ace Optimization:**
```
aceCount = 1 (> 0, so try optimization)
total + 10 = 11 + 10 = 21
21 <= 21? YES
Keep the optimization!

Final total = 21
```

### Example 2: Ace, 5, and King (Soft 16 becomes Hard 16)
**Hand:** Ace, 5, King

**Phase 1 - Initial Calculation:**
```
Card 1: Ace (rank 1)
  - aceCount = 1
  - GetCardValue(1) = 1
  - total = 0 + 1 = 1

Card 2: 5 (rank 5)
  - aceCount = 1
  - GetCardValue(5) = 5
  - total = 1 + 5 = 6

Card 3: King (rank 13)
  - aceCount = 1
  - GetCardValue(13) = 10
  - total = 6 + 10 = 16
```

**Phase 2 - Ace Optimization:**
```
aceCount = 1 (> 0, so try optimization)
total + 10 = 16 + 10 = 26
26 <= 21? NO
Revert: total = 26 - 10 = 16

Final total = 16
```

### Example 3: Two Aces and a 9 (Only one Ace counts as 11)
**Hand:** Ace, Ace, 9

**Phase 1 - Initial Calculation:**
```
Card 1: Ace (rank 1)
  - aceCount = 1
  - GetCardValue(1) = 1
  - total = 0 + 1 = 1

Card 2: Ace (rank 1)
  - aceCount = 2
  - GetCardValue(1) = 1
  - total = 1 + 1 = 2

Card 3: 9 (rank 9)
  - aceCount = 2
  - GetCardValue(9) = 9
  - total = 2 + 9 = 11
```

**Phase 2 - Ace Optimization:**
```
aceCount = 2 (> 0, so try optimization)
total + 10 = 11 + 10 = 21
21 <= 21? YES
Keep the optimization!

Final total = 21
(One Ace = 11, one Ace = 1, 9 = 9)
```

## Key Implementation Details

### Register Usage
| Register | Purpose |
|----------|---------|
| `EAX` | Running total, card value conversions, return value |
| `EBX` | Ace counter |
| `ECX` | Passed in as hand size (not used directly in proc) |
| `EDX` | Temporary storage for card ranks and values |
| `ESI` | Pointer to current card (increments by 4 each iteration) |
| `EDI` | Loop counter (hand size) |

### Why Only One Ace Becomes 11?
The algorithm only adds 10 once, which effectively converts ONE Ace from 1→11. This is optimal because:
- Two Aces as 11 each = 22 (bust)
- Maximum benefit is having exactly one Ace = 11

### Edge Cases Handled
1. **Empty hand:** Returns 0 immediately
2. **No Aces:** Skips optimization phase
3. **Ace would cause bust:** Reverts the +10 optimization
4. **Multiple Aces:** Only promotes one to value 11
