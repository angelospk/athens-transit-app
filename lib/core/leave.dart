// "Πότε να φύγω" (screen 16): the walk to the stop from a straight line, as the web planner does
// (streets ×1.3, 4.5 km/h), and when to leave so as to be at the stop a few minutes before the bus.

const walkMetresPerMin = 75.0;
const streetDetour = 1.3;

/// Minutes on foot for a straight-line distance, rounded up; at least 1.
int walkMinutes(double straightM) => (straightM * streetDetour / walkMetresPerMin).ceil().clamp(1, 120);

/// Minutes from now to leave: the bus's ETA less the walk and the margin; negative means late.
int leaveInMinutes(int etaS, int walkMin, int marginMin) => (etaS / 60).floor() - walkMin - marginMin;
