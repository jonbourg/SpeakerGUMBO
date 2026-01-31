//////////////////////////////////////////////////////////////////////////////
//  G.U.M.B.O.  —  Great Utility for Music Box Optimization
//  
//  An advanced, parametric speaker-enclosure generator.  GUMBO serves as  
//  a framework for designing and optimizing 3D-printable loudspeaker
//  enclosures. Its goal is to give creators complete control over geometry,
//  driver layout, baffle design, tuning volume, and structural integrity —  
//  all while keeping the code elegant and logical.
//  --------------------------------------------------------
//
// TS-based sealed/ported box, spaced drivers, port & terminals on removable
// surface-mount back panel with tongue (rabbet), gasket groove, screw pattern,
// and PRINTED internal port tube(s) with optional outer/inner flares.
//
// 
///////////////////////////////////////////////////////////////////////////////

//  SPEAKERS you plan on using: 
//  TWEETER
//  MIDRANGE
//  WOOFER or FULL-RANGE  PRV 3MR40-NDY-4, 4 ohm 40 watt 3 inch full range
//
//  Recommend using a speaker modeling program such as WinISD
//

// ======================================================================
// GLOBAL DISPLAY / DEBUG
// ======================================================================

$fn = 64;                  // Resolution - low for working, high for 3D printing.
showSpecs       = true;    // Recommend leaving this to true all the time
showDebug       = false;   // driver center debug cylinders
showDriverFaces = false;   // driver face overlays on baffle

// Distance in front of baffle to draw debug faces
driverFaceOffset = 18.0;      // mm
IN=25.4;  // for converting inches to mm

// ======================================================================
// ENCLOSURE TYPE & ALIGNMENT
// ======================================================================
sealed = true;   // true = sealed, false = ported

Vas = 0.022 * 28.3;     // Cubic feet * 28.3 to convert to cubic liters
Qts = 0.77;
Qtc = 0.9;

ventedVasFactor = 1.0;  // for vented speakers only

// Advisory sealed alignment bounds (not hard limits)
Qtc_warn_low  = 0.5;
Qtc_warn_high = 1.2;
// Don't change this
Qtc_safe = max(Qtc, Qts * 1.05);
function clampF(x, xmin, xmax) =
    is_undef(x) ? xmin :
    (x < xmin ? xmin :
     (x > xmax ? xmax : x));


// ======================================================================
// BOX GEOMETRY 
// ======================================================================
boxThickness   = 12;    // wall thickness (mm)
edge_round_radius      = 5;    
round_horizontal_edges = true;
frontTrim              = edge_round_radius; 

// Box geometry ratio's, use golden rule or your own
boxHeightRatio = 1.15;
boxWidthRatio  = 0.9;
boxDepthRatio  = 1.00;

// Only enable during troubleshooting — comment out for clean console
// echo("PARAMETERS DEBUG:");
// echo("boxHeightRatio =", boxHeightRatio);
// echo("boxWidthRatio =", boxWidthRatio);
// echo("boxDepthRatio =", boxDepthRatio);


// ======================================================================
// DRIVER PARAMETERS & POSITIONS
// ======================================================================

// Driver model names (matches index 0=tweeter, 1=mid, 2=woofer)
// Will print on driver fit test
driverModelNames = [
    "Tweeter",                     // 0
    "Midrange",                    // 1
    "PRV-3MR40-NDY-4"              // 2 - add your exact model here
];

// Driver index order (VERY IMPORTANT):
// 0 = Tweeter (top)
// 1 = Midrange (middle)
// 2 = Woofer (bottom)

// driverParams = [cutout dia, screw spacing, screw dia, enabled]
driverParams = [
    [1.385 * IN, 1.75 * IN, 2.8, false],   // Tweeter
    [2.79 * IN, 84.1, 2.8, false],         // Midrange
    [2.79 * IN, 84.1, 2.8, true]           // Woofer
];

speakerFaceDiameters = [
    2 * IN,         // Tweeter overall outside diameter
    79,             // Midrange overall outside diameter 
    93.7            // Woofer overall outside diameter
];

// Tweeter, Midrange, Woofer
driverScrewCount = [4, 4, 4];


// =====================================================================
// DRIVER FACE SHAPES (ordered, with shape-specific parameters grouped)
// =====================================================================
// Face shape codes:
// 0=round, 1=square, 2=rounded square, 3=rectangle,
// 4=clipped circle, 5=truncated circle, 6=squircle, 7=superellipse

driverFaceShape = [
    0,  // Tweeter
    0,  // Midrange
    4   // Woofer
];

// -------------------------------------------------
// Shape(s) 1,2,3 — Rectangle parameters
// -------------------------------------------------
driverRectSizes = [
    [65, 65],  // Tweeter (unused while shape=0)
    [75, 75],  // Midrange
    [90, 90]   // Woofer (placeholder)
];

// -------------------------------------------------
// Shape(s) 2 — Rounded Square Corner Radius
// -------------------------------------------------
driverCornerRadius = [
    0,   // Tweeter
    0,   // Midrange
    15    // Woofer
];

// -------------------------------------------------
// Shape 4, Clipped Circle (Like a FaitalPro 5FE120) 
// Shape 5, Truncated Circle
// -------------------------------------------------
// Clip depth. How far in from speaker face diameter the flats cut in per side.
driverClipDepth = [
    0,   // Tweeter
    0,   // Midrange
    5.6    // Woofer
];

// -------------------------------------------------
// 5) Shape 7 — Adjustable superellipse parameters
// -------------------------------------------------
// Suggested presets & examples:
//   Smooth circular frames:
//       n ≈ 2.0, corner_r = 0–1
//       Ex: Dayton ND tweeters, Peerless DX20.
//   Soft squircle / gentle square:
//       n ≈ 4.0, corner_r = 0–2
//       Ex: Tang Band W3/W4 frames.
//   Rounded rectangle:
//       n ≈ 5–8, corner_r = 1–4
//       Ex: Oval pod-style drivers, Bose cube modules.
//   Classic pincushion (vintage style):
//       n ≈ 1.2–1.6, corner_r = 2–5
//       Ex: Many older 3–5" square-frame full-ranges.
//   Modern PC/GRS-style frame (recommended):
//       n ≈ 1.30–1.45, corner_r = 2–4
//       Ex: Dayton PC83/PC105, GRS 4PF/5PF.
driverAdjustCurvature = [
    1.35,    // Tweeter (unused)
    1.35,   // Midrange
    1.35     // Woofer (unused)
];

driverAdjustCornerR = [
    2,     // tweeter
    2,     // mid
    2      // woofer
];

// ======================================================================
//  DRIVER POSITIONING OFFSETS 
// ======================================================================
driverEdgeMin = 3;     // Minimum distance from driver *frame edge* to any inner wall

// Manual offsets, (+Z=up, -Z=down), (+X=right, -X=left)
tweeterZ_offset = 0;
tweeterX_offset = 0;

midZ_offset = 0;
midX_offset = 0;

wooferZ_offset = 24.48;
wooferX_offset = 8.48;

// ======================================================================
//  DRIVER BAFFLE SETTINGS
// ======================================================================
baffleThickness = 12;
baffleCornerR = 5;
baffleEdgeStyle = 2;    // 0=flat, 1=chamfered, 2=rounded 
baffleEdgeSize = 5;
baffleFrameInset = 20;

driverRecessDepth = [3.0, 1.5, 5.7];  // Tweeter, Midrange, Woofer
driverSurfaceMount = [false, false, false];

flushTrimDepth = 5.7;   // Recommend same as recess depth
trimMargin = 0.8;       // Tolerance around speaker

// ======================================================================
// BAFFLE LOCATING FEATURES (FRONT GLUE-ON BAFFLE)
// ======================================================================
baffleLocMargin    = 15;
baffleSlotWidth    = 6;
baffleSlotLength   = 14;
baffleSlotDepth    = 3;

baffleKeyWidth     = 4;
baffleKeyLength    = 8;
baffleKeyDepth     = 3;

baffleLocClearance = 0.25;

// tabPocket params (add if missing)
tabPocketDepth = 3.0;
tabPocketClearance = 0.25;


// ────────────────────────────────────────────────
// GRILL PARAMETERS 
// ────────────────────────────────────────────────

grill_enable = true;     // Set false to hide grill completely in all views

// Grill sizing & fit
grill_thk = 2.4;
grill_clearance = 1.0;
grill_outer_inset = 8.0;

// Frame
grill_border_w = 0.0;
grill_corner_radius_front = 10.0;

//corner_r = 0;

// ────────────────────────────────────────────────
// GRILL CORE PATTERN SELECTOR
// ────────────────────────────────────────────────
// 0 = Honeycomb
// 1 = Waffle (rotated square)
// 2 = Bars (future)
// 3 = Perforated (future)
// ────────────────────────────────────────────────
grill_core_pattern = 0;


// Hex pattern
grill_hex_edge_margin = 7.0;  
grill_pattern_hex_flat = 8.0;
grill_pattern_hex_gap  = 1.0;

// Waffle pattern
grill_waffle_pitch = 8;   // distance between holes
grill_waffle_gap   = 5.5;  // size of diamond opening

// Bar pattern
grill_bar_pitch = 9;     // distance between bars
grill_bar_gap   = 4.5;   // slot width
grill_bar_angle = 30;     // 0 = vertical, 90 = horizontal

// Perforated pattern
grill_perf_pitch = 8.5;   // spacing between holes
grill_perf_dia   = 5.0;   // hole diameter
grill_perf_angle = 0;     // rotation (usually 0)


// Magnet physical size + fit clearance
grill_mag_dia   = 6.0;
grill_mag_thk   = 3.0;
grill_mag_clear = 0.3;

// Protrusion amount (used by pocket depth)
grill_mag_proud = 1.5;

// Boss geometry
grill_boss_d    = 10.0;
grill_boss_h    = 3.5;
grill_boss_wall = 2.0;

// Front skin (used in pocket positioning)
grill_skin_min  = 1.2;

// Retention cap dimensions (depends on proud + boss d)
chamfer_depth = 0.8;
chamfer_width = 1.0;
grill_cap_thk      = 1.5;
grill_cap_pocket_h = grill_mag_proud + 0.3;
grill_cap_total_h  = grill_cap_thk + grill_cap_pocket_h;
grill_cap_lip      = 0.8;

// Cosmetic front features
grill_dimple_dia   = 3.0;
grill_dimple_depth = 0.5;

/*
// ============================================================
// GRILL — GEOMETRY & PLACEMENT
// ============================================================
grill_enable          = true;     // Set false to hide grill completely in all views

grill_outer_inset     = 18.0;   // Try 8–15 mm; 0 = full size, 20 = matches old core-based size
grill_corner_radius_front = 10.0;   // ← key control: try 6–12 mm to match baffle feel
grill_clearance       = 1.0;      // mm smaller per side than baffle's flat core area
grill_border_w        = 1.0;      // visible solid border width around hex pattern
grill_thk             = 3.4;      // total grill thickness (before rounding)
grill_edge_r          = 1.0;      // radius of minkowski rounding on all edges (front/back/sides); set 0 for sharp
grill_standoff        = 0.6;      // mm — nominal gap between baffle front face and grill back face
grill_corner_adjust   = grill_edge_r;  // how much to reduce corner radius to compensate for edge rounding


// ============================================================
// GRILL PATTERN — HEXAGONAL ACOUSTIC OPENINGS
// ============================================================
grill_pattern_hex_flat        = 6.0;      // flat-to-flat distance of each hex (core size before gap)
grill_pattern_hex_gap         = 1.2;      // minimum wall thickness between hexes (material between openings)
*/


// ======================================================================
// PORT & PRINTED PORT PARAMETERS (LEGACY SINGLE PORT)
// ======================================================================
makePort             = false;             // enable making a single port
portInternalDiameter = 1.5 * IN;          // port ID (mm)
portLength           = 50;                // legacy param (for reference only)

// Port placement – always on the back panel
portOffsetX = 0;    // left/right (+X = right)
portOffsetZ = 0;   // up/down (+Z = up)

// Port flare (manual, outer flare only on panel back face)
portFlareOuterEnabled  = false;
portFlareOuterDepth    = 3;
portFlareOuterDiameter = 1.6 * portInternalDiameter;

// Printed port options
printedPortEnabled             = false;
printedPortWall                = 2.0;
printedPortLength              = 3.92 * 25.4;
printedPortInsideFlare         = false;
printedPortInsideFlareDiameter = 1.4 * portInternalDiameter;
printedPortInsideFlareDepth    = 4;
flareInner                     = false;

// ======================================================================
// MULTI-PORT PARAMETERS (UP TO 3 ROUND PORTS ON BACK PANEL)
// ======================================================================
// NOTE:
//  - If you enable multiPortEnabled, you probably want makePort = false
//    so you don't have BOTH the single legacy port and multi-ports active.
multiPortEnabled   = false;    // set true to enable multi-port mode
multiPortCount     = 3;        // 1, 2, or 3 ports (clamped 0–3)
multiPortDiameter  = 30;       // mm (internal port diameter)
multiPortLength    = 50;       // mm (printed tube length per port)
// Horizontal spacing between port centers (mm)
multiPortSpacing   = 38;
// Group center position on panel (local panel coords, like terminals/portOffset)
multiPortOffsetX   = 0;        // center of multi-port group in X
multiPortOffsetZ   = -10;      // center of group in Z (negative = down, positive = up)

// ======================================================================
// TERMINAL PARAMETERS
// ======================================================================
// terminalType:
// 0 = none, 1 = single wire, 2 = dual wire, 3 = round cup,
// 4 = rectangular cup, 5 = legacy pair, 6 = NL2, 7 = binding posts,
// 8 = spring clip
terminalType = 2;   // default: dual wire

wireDiameter    = 6.35;
dualWireSpacing = 20;

terminalRoundDiameter = 40;

terminalWidth  = 50;
terminalHeight = 40;

terminalPairWidth = 40;

nl2HoleDiameter = 24;

bindingPostHoleDiameter = 8;
bindingPostSpacingX     = 19;
bindingPlateWidth       = 40;
bindingPlateHeight      = 25;

springClipWidth  = 50;
springClipHeight = 35;

// Terminal offsets (on back panel)
terminalOffsetX = 0;
terminalOffsetZ = -40;  


// ======================================================================
// BACK PANEL (SURFACE-MOUNT)
// ======================================================================

// --------------------------------------------------
// ENABLE / TYPE
// --------------------------------------------------
makeBackPanel = true;


// --------------------------------------------------
// BASIC GEOMETRY (STRUCTURAL, SHARED TRUTH)
// --------------------------------------------------

// Back panel inset (flush mount pocket)
backPanelInsetDepth     = 3;        // mm, depth of pocket
backPanelThickness      = backPanelInsetDepth;
backPanelInsetFromCurve = 0.2;      // mm, offset from curved shell


// --------------------------------------------------
// FIT & TOLERANCE (MANUFACTURING REALITY)
// --------------------------------------------------

// Real fit clearance for the panel pocket (box-side geometry)
backPanelFitClearance = 0.25;       // mm (0.2–0.5 typical)

// Panel-side manufacturing tolerance
backPanelTolerance    = 0.25;        // mm (print clearance)


// --------------------------------------------------
// PANEL EDGE / TONGUE GEOMETRY
// --------------------------------------------------

// Tongue depth must exceed Minkowski rounding radius so it remains visible.
// For 12 mm walls, 6 mm beyond the round radius works very well.
backPanelTongueDepth = edge_round_radius + 6;

// Margin from panel edge to pocket boundary
backPanelEdgeMargin  = 4;           // mm

// Back panel edge rounding (independent of box)
backPanelEdgeRadius  = 2.0;         // mm (0 = sharp)


// --------------------------------------------------
// FASTENERS (SCREW PATTERN & HOLES)
// --------------------------------------------------

// Screw population
backScrewCountCorners = true;
backScrewCountMids    = true;

// Edge inset for screw locations
backPanelScrewEdgeInset = 3.5;      // mm (1.5–2.0 works well)

// Screw hole sizing (M3, print-friendly)
backScrewPilotDia   = 2.8;           // mm, box (pilot)
backScrewClearDia   = 3.3;           // mm, panel (clearance)
backScrewPilotDepth = 10;            // mm, depth into box material



// ======================================================================
// DRIVER FIT TEST PARAMETERS
// ======================================================================
fitTestDriverIndex = 2;   // 0=tweeter, 1=mid, 2=woofer

underFlangeThickness = 2.4;

shape_fit_tolerance  = 0.25;
cutout_fit_tolerance = 0.25;

// Clamp multi-port count to 0–3 for safety
multiPortCount_clamped = floor(clampF(multiPortCount, 0, 3));
