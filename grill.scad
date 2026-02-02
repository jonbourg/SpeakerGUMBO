//
// G.U.M.B.O. Speaker Grill — Clean Hex Core + Rounded Frame
// Jon Bourgeois
//
// Back face at Y = 0
// Grill extends in +Y direction
//
// Units: mm
// ======================================================
// MAGNET SYSTEM
//   - Bosses attached to grill backside
//   - Rear-inserted magnet cavities in bosses
//   - Printed retention caps to secure magnets
//   - 6×3 mm magnets, 0.3 mm radial clearance
//   - Front skin preserved
// ======================================================

include <parameters.scad>
include <utils.scad>

// ────────────────────────────────────────────────
// GRILL PANEL (2D) — Parametric
// ────────────────────────────────────────────────
module grill_panel_2d(outer_w, outer_h, core_w, core_h, corner_r) {
    // ... safe defaults ...

    gW = outer_w - 2*grill_outer_inset - 2*grill_clearance;
    gH = outer_h - 2*grill_outer_inset - 2*grill_clearance;

    innerW = gW - 2 * grill_hex_edge_margin;
    innerH = gH - 2 * grill_hex_edge_margin;

    difference() {
        rounded_rect_2d(gW, gH, grill_corner_radius_front);

        intersection() {
            grill_core_pattern_2d(innerW, innerH);
            let(effective_r = (grill_border_w < 0.5) ? 0 : corner_r)
                rounded_rect_2d(innerW, innerH, effective_r);
        }
    }
}


// ────────────────────────────────────────────────
// HONEYCOMB PATTERN (2D) — SUBTRACTIVE (PRINT SAFE)
// Generates a honeycomb
// ────────────────────────────────────────────────
module grill_hex_pattern_honeycomb(w, h) {
    hole_flat = grill_pattern_hex_flat;
    wall      = grill_pattern_hex_gap;
    pitch     = hole_flat + wall;

    // ── Flat-top layout ─────────────────────────────
    x_step    = pitch;                      // horizontal spacing same row
    y_step    = pitch * sqrt(3) / 2;       // vertical spacing
    x_offset  = pitch / 2;                  // offset for odd rows

    cols = ceil(w / x_step) + 4;   // generous overshoot
    rows = ceil(h / y_step) + 4;

    for (row = [-rows:rows]) {
        y = row * y_step - h/2;   // better centering
        x_shift = (row % 2 != 0) ? x_offset : 0;
        for (col = [-cols:cols]) {
            x = col * x_step + x_shift - w/2;
            translate([x, y])
                hex_hole_2d(hole_flat);
        }
    }
}



module hex_hole_2d(flat_d) {
    // Pointy-top version - starts at top point
    R = flat_d / 2;   // now R = distance center → flat center
    polygon(points = [
        for (i = [0:5])
            let(angle = 30 + 60*i)   // rotate 30°
                [ R * cos(angle), R * sin(angle) ]
    ]);
}



// ────────────────────────────────────────────────
// WAFFLE PATTERN (2D) — SUBTRACTIVE (PRINT SAFE)
// Generates diamond-shaped HOLES
// ────────────────────────────────────────────────
module waffle_pattern_2d(w, h) {

    // ── USER TUNABLES ───────────────────────────
    waffle_pitch = grill_waffle_pitch;   // center-to-center spacing
    waffle_gap   = grill_waffle_gap;     // hole size control
    waffle_angle = 45;
    // ────────────────────────────────────────────

    span = sqrt(w*w + h*h) + waffle_pitch * 2;

    rotate(waffle_angle)
    for (x = [-span : waffle_pitch : span])
        for (y = [-span : waffle_pitch : span])
            translate([x, y])
                square([waffle_gap, waffle_gap], center = true);
}


// ────────────────────────────────────────────────
// BAR PATTERN (2D) — SUBTRACTIVE (PRINT SAFE)
// Generates slots between solid bars
// ────────────────────────────────────────────────
module bars_pattern_2d(w, h) {

    // ── USER TUNABLES ───────────────────────────
    bar_pitch = grill_bar_pitch;   // center-to-center spacing
    bar_gap   = grill_bar_gap;     // slot width (cut)
    bar_angle = grill_bar_angle;   // degrees (0 = vertical)
    // ────────────────────────────────────────────

    span = sqrt(w*w + h*h) + bar_pitch * 2;

    rotate(bar_angle)
    for (x = [-span : bar_pitch : span]) {
        translate([x, 0])
            square([bar_gap, span * 2], center = true);
    }
}


// ────────────────────────────────────────────────
// PERFORATED PATTERN (2D) — SUBTRACTIVE (PRINT SAFE)
// Generates round holes in a uniform grid
// ────────────────────────────────────────────────
module perforated_pattern_2d(w, h) {

    // ── USER TUNABLES ───────────────────────────
    perf_pitch = grill_perf_pitch;   // center-to-center spacing
    perf_dia   = grill_perf_dia;     // hole diameter
    perf_angle = grill_perf_angle;   // degrees (optional rotation)
    // ────────────────────────────────────────────

    span = sqrt(w*w + h*h) + perf_pitch * 2;

    rotate(perf_angle)
    for (x = [-span : perf_pitch : span])
        for (y = [-span : perf_pitch : span])
            translate([x, y])
                circle(d = perf_dia);
}


// ────────────────────────────────────────────────
// MAGNET BOSSES — Solid (attached to grill back)
// ────────────────────────────────────────────────
module grill_bosses(outer_w, outer_h) {
    pos = grill_mag_positions_xz(outer_w, outer_h);
    for (p = pos) {
        translate([p[0], -grill_boss_h, p[1]])
            rotate([-90, 0, 0])
                cylinder(d = grill_boss_d, h = grill_boss_h, center = false);
    }
}

// ────────────────────────────────────────────────
// MAGNET CAVITIES — Rear-inserted in bosses
// ────────────────────────────────────────────────
module grill_magnet_cavities(outer_w, outer_h) {
    mag_d = grill_mag_dia + 2 * grill_mag_clear;  // e.g., 6.6 mm
    cavity_depth = grill_mag_thk - grill_mag_proud + grill_mag_clear;  // shallow: full thk - proud + clear

    pos = grill_mag_positions_xz(outer_w, outer_h);
    for (p = pos) {
        translate([p[0], -grill_boss_h + cavity_depth / 2 - 0.01, p[1]]) {
            rotate([-90, 0, 0])
                cylinder(d = mag_d, h = cavity_depth + 0.2, center = true);
        }
    }
}

// ────────────────────────────────────────────────
// MAGNET RETENTION CAP (printed separately)
// ────────────────────────────────────────────────
// This module works and puts a chamfer on the end of the cap, but no dimple
module grill_mag_retention_cap() {
    cap_od = grill_boss_d;                // 10 mm
    pocket_d = grill_mag_dia + 2 * grill_mag_clear + 0.15;
    pocket_h = grill_mag_proud + 0.3;
    cap_thk = grill_cap_thk; // use global

    difference() {
        union() {
            cylinder(d = cap_od, h = cap_thk + pocket_h - chamfer_depth);

            // Chamfer at HIGH Z / REAR (exposed side after rotation)
            translate([0, 0, (cap_thk + pocket_h) - chamfer_depth])
                cylinder(  // # for debug highlight (remove when done)
                    d1 = cap_od,                      // wide at base (inside cap)
                    d2 = cap_od - 2 * chamfer_width,  // narrow at very rear (exposed face)
                    h = chamfer_depth
                );
        }

        // Pocket from LOW Z / FRONT (against grill / boss)
        translate([0, 0, -0.01])  // cut from bottom
            cylinder(d = pocket_d, h = pocket_h + 0.02);
        
    }
}


// ────────────────────────────────────────────────
// FINAL 3D GRILL — Parametric
// ────────────────────────────────────────────────
module grill_panel_flat(outer_w, outer_h, core_w, core_h, corner_r) {
    difference() {  // ← add this to subtract cavities from the whole grill + bosses
        union() {
            translate([0, grill_thk/2, 0])
                rotate([90, 0, 0])
                    linear_extrude(height = grill_thk, center = true, convexity = 6)
                        grill_panel_2d(outer_w, outer_h, core_w, core_h, corner_r);

            grill_bosses(outer_w, outer_h);
        }

        // Subtract cavities from bosses
        grill_magnet_cavities(outer_w, outer_h);
    }
}

// Places caps on the back of each boss (for assembly visualization)
module grill_installed_caps(outer_w, outer_h) {
    pos = grill_mag_positions_xz(outer_w, outer_h);
    
    // Caps Y offset logic:
    // - Assembled (explodeDistance small/zero): no extra back offset → flush on baffle
    // - Exploded: push caps back ~10 mm from bosses → visible separation from grill
    extra_cap_back = (explodeDistance > 5) ? -5 : 0;
    
    for (p = pos) {
        translate([p[0], -grill_boss_h - grill_cap_total_h / 2 + extra_cap_back + chamfer_depth, p[1]]) {
            color("DimGray")
            rotate([90, 0, 0])  // keep this if pocket faces grill; flip to [90,0,0] if needed
                grill_mag_retention_cap();
        }
    }
}

// ────────────────────────────────────────────────
// GRILL CORE ROUTER (2D)
// Centralized pattern selection
// ────────────────────────────────────────────────
module grill_core_pattern_2d(w, h) {

    if (grill_core_pattern == 0) {
        grill_hex_pattern_honeycomb(w, h);

    } else if (grill_core_pattern == 1) {
        waffle_pattern_2d(w, h);

    } else if (grill_core_pattern == 2) {
        bars_pattern_2d(w, h);   // placeholder

    } else if (grill_core_pattern == 3) {
        perforated_pattern_2d(w, h);   // placeholder

    } else {
        // Safe fallback: solid (debug friendly)
        square([w, h], center = true);
    }
}


// ────────────────────────────────────────────────
// GRILL MAGNET CAPS — ARRAY (FLIPPED FOR PRINTING)
// ────────────────────────────────────────────────
module grill_mag_caps_array(count = undef)
{
    eff_count = is_undef(count) ? 1 : count;
    spacing = grill_boss_d + 6;

    for (i = [0 : eff_count - 1])
        translate([i * spacing, 0, grill_cap_thk+(chamfer_depth*2)])
            rotate([180, 0, 0])   // ← THIS is the flip
                grill_mag_retention_cap();
}

