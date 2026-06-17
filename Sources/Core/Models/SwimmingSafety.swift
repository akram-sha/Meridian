public enum SwimmingSafety {
    case calm        //  < 15 km/h: Calm. No meaningful effect on open water swimmers.
    case moderate    // 15–27 km/h: Beaufort 3–4. Surface chop developing, sighting harder.
    case concerning  // 28–38 km/h: Beaufort 4–5. Organised events cancelled at this range.
    case dangerous   //  ≥ 39 km/h: Beaufort 6+. Small Craft Advisory threshold.
}