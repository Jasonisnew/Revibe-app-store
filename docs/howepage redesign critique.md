

This screen is moving in the right direction. It now communicates:

- personalized workout
- weekly structure
- some motivation

But the page still has 3 issues:

1. the main action is not obvious enough
2. too much vertical space is spent before the user can act
3. the app still feels like a generated plan, not an active coach

---

## 1. Header area

### Current issues
- “Hello Jason Liu2!” is too large and slightly awkward
- “Liu2” looks like a data/display bug
- “You ready for today’s session” is grammatically off
- the greeting block is taking too much vertical space
- the streak card appears before the main action, which weakens focus

### Revised layout
Make the top area more compact and more coach-like.

#### Replace this:
**Revibe**  
**Hello Jason Liu2! 👋**  
**You ready for today’s session**

#### With this:
**Revibe**  
**Good afternoon, Jason 👋**  
**Ready for today’s workout?**

### Layout changes
- reduce greeting font size by about 20–25%
- reduce top padding under the app title
- reduce space between greeting and subtext
- move the streak/progress module below the Today’s Workout card, not above it

### Why
The first thing the user should see is not identity or celebration.  
It should be: **what am I doing today, and how do I start?**

---

## 2. Streak / motivation card

### Current issues
- “0-day streak” feels demotivating
- “Keep up the work!” does not match a zero state
- it does not tell the user what to do next

### Revised text

#### Replace this:
**0-day streak**  
**Keep up the work!**

#### With one of these options:

##### Best option
**Start your streak today**  
**Complete today’s workout to build momentum**

##### Alternative
**This week: 0 of 4 workouts**  
**Start with today’s 30-minute session**

### Layout changes
- reduce the card height slightly
- use this card as a progress/momentum card rather than a streak-only card
- add a small progress bar or dot indicator if possible

### Better structure
Instead of only showing streak, combine streak + weekly goal:

**This week: 0/4 workouts**  
**Start with Chest and Triceps today**

### Why
A zero state should encourage action, not highlight lack of action.

---

## 3. Today’s Workout card

This should become the hero of the page.

### Current issues
- strong structure, but missing a clear primary button
- the “why this plan” explanation is helpful but too soft and too long
- exercise list is good, but the card still reads like a static plan
- no immediate action or coaching tone

### Revised card structure

#### New recommended layout order
1. section label
2. workout title
3. metadata row
4. short AI reason
5. exercise preview
6. primary CTA
7. secondary action

### Exact revised text

#### Section label
Replace:
**TODAY’S WORKOUT**

With:
**TODAY FOR YOU**

This feels more personalized.

#### Workout title
Keep:
**Chest and Triceps**

Or make slightly more coach-like:
**Chest and Triceps Focus**

#### Metadata row
Replace:
**30 min**  
**4 exercises**

With:
**30 min · 4 exercises · Full gym**

This makes the plan more instantly scannable.

#### AI reason line
Replace:
*This plan focuses on building muscle while avoiding stress on the shoulders, tailored for a full gym setup.*

With:
**Built for muscle gain, shoulder comfort, and your gym setup.**

Shorter, clearer, stronger.

#### Exercise list
Keep the list, but simplify the formatting slightly:

- Incline Dumbbell Press — 3 × 8
- Chest Fly — 3 × 10
- Bench Dips — 3 × 10
- Tricep Pushdowns — 3 × 12

Also shorten labels:
- “Chest Fly (machine or dumbbells)” → **Chest Fly**
- “Tricep Dips (bench)” → **Bench Dips**

You can surface the variation after tap if needed.

#### Primary CTA
Add a strong button directly inside the card:

**Start Today’s Workout**

#### Secondary action
Below or beside it, lighter treatment:

**Preview workout**

Or:

**Swap session**

### Layout changes
- add CTA button inside the card
- reduce paragraph-style explanation space
- add more spacing between metadata and exercise list
- make set/rep numbers smaller and lighter than exercise names
- add subtle divider above the CTA

### Why
The Today card should answer:
- what is it
- why this one
- how long
- what’s in it
- start now

Right now it answers the first four, but not the fifth strongly enough.

---

## 4. “Your Week” section

### Current issues
- good concept, but feels static
- repeated explanatory sentence is unnecessary
- not enough sense of progress
- today’s workout is not visually distinguished from the rest

### Revised text

#### Replace heading:
**Your Week**

With:
**Your Weekly Plan**

#### Remove repeated paragraph:
*This plan focuses on building muscle while avoiding stress on the shoulders, tailored for a full gym setup.*

Replace with:
**4 workouts built around your goal and recovery**

Or:
**Balanced for muscle growth and shoulder-friendly training**

### Revised item labels
Current:
- Day 1 Leg Day
- Day 2 Back and Biceps
- Day 3 Leg and Core Focus
- Day 4 Chest and Triceps

Suggested:
- **Mon · Legs**
- **Tue · Back & Biceps**
- **Thu · Legs & Core**
- **Sat · Chest & Triceps**

Or if actual days are unknown:
- **Workout 1 · Legs**
- **Workout 2 · Back & Biceps**
- **Workout 3 · Legs & Core**
- **Workout 4 · Chest & Triceps**

### Layout changes
- highlight today’s row with a tinted border/background
- add state chips:
  - **Today**
  - **Upcoming**
  - **Completed**
- show weekly progress above the list:
  - **0 of 4 completed**
- allow each row to be tappable for preview

### Example revised block

**Your Weekly Plan**  
**0 of 4 completed this week**

[Today] Chest & Triceps — 30 min  
[Upcoming] Legs — 45 min  
[Upcoming] Back & Biceps — 30 min  
[Upcoming] Legs & Core — 45 min

### Why
The week section should feel like a living plan, not a static schedule.

---

## 5. Sign Out button

### Current issues
- far too visually loud
- competes with workout CTA
- not appropriate as a major element on the home screen
- breaks the hierarchy badly

### Exact change
Remove it from this screen.

Move it to:
- profile
- settings
- account menu

### If it must remain
Make it:
- text link only
- in top-right account menu
- or small in profile page footer

#### Do not keep:
large red button floating over the home page

### Why
This is the biggest hierarchy problem on the whole screen.

---

## 6. Visual hierarchy and spacing

### Current issues
- too much height in greeting zone
- too much explanatory text repeated
- primary action not dominant
- some sections feel separated but not sequenced

### Revised order of sections
Use this home screen order:

1. app title / compact greeting
2. today’s workout hero card
3. progress / momentum card
4. weekly plan
5. optional lower-priority items

This is better than:
1. greeting
2. streak
3. workout
4. week
5. sign out

### Suggested spacing changes
- reduce top greeting area by 25–30%
- tighten vertical gap between greeting and hero card
- reduce long explanatory copy blocks
- give more spacing around CTA button
- keep weekly rows more compact

---

## 7. Tone and microcopy changes

Here is a full set of revised text you can use directly.

### Top of screen
**Revibe**  
**Good afternoon, Jason 👋**  
**Ready for today’s workout?**

### Today card
**TODAY FOR YOU**  
**Chest and Triceps Focus**  
**30 min · 4 exercises · Full gym**  
**Built for muscle gain and shoulder comfort.**

- Incline Dumbbell Press — 3 × 8  
- Chest Fly — 3 × 10  
- Bench Dips — 3 × 10  
- Tricep Pushdowns — 3 × 12  

**[Start Today’s Workout]**  
Preview workout

### Momentum card
**This week: 0 of 4 workouts**  
**Complete today’s session to start your streak**

### Weekly plan
**Your Weekly Plan**  
**4 workouts built around your goal and recovery**

**Today · Chest & Triceps** — 30 min  
**Upcoming · Legs** — 45 min  
**Upcoming · Back & Biceps** — 30 min  
**Upcoming · Legs & Core** — 45 min

---

## 8. Best redesigned wireframe

Here is the structure I would recommend:

```text
[Revibe]

Good afternoon, Jason 👋
Ready for today’s workout?

┌──────────────────────────────┐
│ TODAY FOR YOU                │
│ Chest and Triceps Focus      │
│ 30 min · 4 exercises · Gym   │
│ Built for muscle gain and    │
│ shoulder comfort.            │
│                              │
│ Incline Dumbbell Press  3×8  │
│ Chest Fly               3×10 │
│ Bench Dips              3×10 │
│ Tricep Pushdowns        3×12 │
│                              │
│ [ Start Today’s Workout ]    │
│ Preview workout              │
└──────────────────────────────┘

┌──────────────────────────────┐
│ This week: 0 of 4 workouts   │
│ Complete today’s session to  │
│ start your streak            │
└──────────────────────────────┘

Your Weekly Plan
4 workouts built around your goal and recovery

[Today]    Chest & Triceps    30 min
[Upcoming] Legs               45 min
[Upcoming] Back & Biceps      30 min
[Upcoming] Legs & Core        45 min