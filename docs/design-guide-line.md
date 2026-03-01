# 🧱 1. Foundations

## 1.1 Brand Principles

**Clarity over decoration**
**Typography over graphics**
**Restraint over feature noise**
**Warmth over sterility**
**Silence over stimulation**

If something feels “too UI,” remove it.

---

# 🎨 2. Color System

## 2.1 Core Palette

### Background

```
--color-bg-primary: #FFFFFF;   // main canvas
--color-bg-secondary: #F8F8F8; // subtle section contrast
```

White primary background. Use subtle shadows (opacity &lt; 5%) for elevation.

---

### Text

```
--color-text-primary:   #333333;
--color-text-secondary: #333333;
--color-text-muted:     #A0A0A0;
--color-text-on-dark:   #FFFFFF;
```

Primary and secondary for main content; muted for hints, captions, and secondary info.

---

### Accent & CTA

```
--color-accent:  #FF4D4D;  // primary accent
--color-cta-red: #FF3B30;  // main call-to-action (e.g. play, start)
--color-highlight: #000000; // selected state (tab, date, indicator)
```

Use CTA red sparingly for the primary action (e.g. central play button). Black for selection/highlight only.

---

### Dividers & Progress

```
--color-border: #E0E0E0;  // dividers, unfilled progress
--color-shadow: rgba(0,0,0,0.05);
```

Hairline borders only. Very subtle shadow for elevated cards.

---

## 2.2 Gradients (Soft Pastels)

Use for banners, progress, and cards. Keep corners rounded consistently.

**Peach → pink-orange** (countdown cards, info banners):
```
#FFEDD8 → #FDE6E7
```

**Pale yellow-orange** (speech bubbles, avatar circles):
```
#FFEBCC → #FFEDD8
```

**Progress bar** (filled portion):
```
#FDE673 → #FFAD02
```

**Green → blue** (category cards, variety):
```
#E8F8E8 → #E0F5FF
```

**Pale yellow-peach** (uniform card background):
```
#FFF0D9
```

---

## 2.3 Session / Category Card Palette

Soft pastel gradients and flat colors for session and category cards. Assign deterministically from ID so the same session keeps the same color.

```
--color-card-peach-orange:  #FFEDD8;
--color-card-yellow-peach:  #FFF0D9;
--color-card-green-blue:    #E8F8E8;
(+ peachEnd #FDE6E7, paleOrange #FFEBCC, paleYellowPeach #FFF0D9)
```

Rules:
- Text on cards: `--color-text-primary` (#333333) or black (#000000) for legibility.
- No heavy borders — card color or subtle shadow provides separation.
- Prefer gradients for hero cards; flat pastels for lists.

---

# 🔤 3. Typography System

Typography carries identity.

## 3.1 Font Pairing

### Headline Serif

Canela / Playfair / Editorial New / modern serif

Used for:

* Hero headlines
* Section titles
* Reflection statements

### Body Sans

Inter / SF Pro / modern grotesk

Used for:

* UI labels
* Body text
* Inputs
* Navigation

---

## 3.2 Type Scale

### H1

48–64px
Line-height: 1.1
Weight: Regular or Medium
Tracking: slightly negative (-1%)

---

### H2

32–40px
Line-height: 1.2

---

### H3

20–24px
Sans serif
Weight: Medium

---

### Body Large

18px
Line-height: 1.6

---

### Body Regular

16px
Line-height: 1.6–1.7

---

### Caption

13–14px
Muted color

---

No ALL CAPS unless very small micro-labels.

---

# 📐 4. Layout & Grid

## 4.1 Spacing Scale

Base unit: 8px

Use:
8 / 16 / 24 / 32 / 48 / 64 / 96

Never random spacing.

---

## 4.2 Margins

Desktop:
80–120px side margin for hero

Mobile:
24px side padding

Large breathing space is mandatory.

---

## 4.3 Containers

Avoid heavy cards.

Instead:

* light background shift (#EFEAE2)
* subtle divider
* typography grouping

No shadows unless extremely subtle (opacity < 4%).

---

# 🟫 5. Components

## 5.1 Buttons

### Primary

Background: #1C1C1C
Text: #FFFFFF
Radius: 6px
Padding: 12px 20px

No gradient.
No oversized pill.

---

### Secondary

Transparent background
1px border #1C1C1C
Text: #1C1C1C

---

### Text Button

Color: Accent
No underline by default
Underline on hover

---

## 5.2 Input Fields

Background: #FFFFFF
Border: 1px solid #E1DDD5
Radius: 6px
Padding: 14px

Focus:
Border becomes accent color.

No glowing shadows.
