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

    innerW = max(1, core_w  - 2 * grill_border_w);
    innerH = max(1, core_h  - 2 * grill_border_w);

    // Fill control — 1.0 = hexes touch mask edge, <1.0 = intentional inset
    hex_fill_ratio = 0.995;   // very close to edge, slight safety
    // hex_fill_ratio = 1.0;  // max fill — may clip slightly on edges

    hex_flat = min(innerW, innerH) * hex_fill_ratio;

    difference() {
        rounded_rect_2d(gW, gH, grill_corner_radius_front);

        intersection() {
            hex_pattern_2d(innerW, innerH);
            // Use small or zero radius when border is zero
            let(effective_r = (grill_border_w < 0.5) ? 0 : corner_r)
                rounded_rect_2d(innerW, innerH, effective_r);
        }
    }
}

// ────────────────────────────────────────────────
// MAGNET BOSSES — Solid (attached to grill back)
// ────────────────────────────────────────────────
module grill_bosses(outer_w, outer_h) {
    pos = grill_mag_positions_xz(outer_w, outer_h);

    for (p = pos) {
        translate([p[0], -grill_boss_h, p[1]])
            rotate([-90, 0, 0])
                cylinder(
                    d = grill_boss_d,
                    h = grill_boss_h,
                    center = false,
                    $fn = 32
                );
    }
}

// ────────────────────────────────────────────────
// MAGNET CAVITIES — Rear-inserted in bosses
// ────────────────────────────────────────────────
module grill_magnet_cavities(outer_w, outer_h) {
    mag_d = grill_mag_dia + 2 * grill_mag_clear;           // 6.6 mm

    // Controlled depth: magnet thickness + small recess + clearance
    // 3.0 + 0.5 recess + 0.3 clearance = 3.8 mm max — but we'll cap it
    mag_h = min(3.8, grill_mag_thk + grill_mag_clear + 0.5);  // safe max 3.8 mm

    pos = grill_mag_positions_xz(outer_w, outer_h);

    for (p = pos) {
        // Position so cavity back aligns with boss back
        // Center the cylinder so only ~half protrudes backward if needed
        translate([p[0], -grill_boss_h + (mag_h / 2) + 0.2, p[1]]) {   // +0.2 instead of +0.5 — gentler
            rotate([-90, 0, 0])
                cylinder(
                    d1 = mag_d + 0.8,     // slight flare at back for easy drop-in
                    d2 = mag_d,
                    h = mag_h + 0.5,      // small overshoot only — enough to clean cut
                    center = true,
                    $fn = 48
                );
        }
    }
}

// ────────────────────────────────────────────────
// MAGNET RETENTION CAP (printed separately)
// ────────────────────────────────────────────────
module grill_mag_retention_cap() {
    cap_od   = grill_boss_d + 2 * grill_cap_lip;          // outer diameter with lip
    pocket_d = grill_mag_dia + 2 * grill_mag_clear + 0.15; // slight interference for press-fit
    pocket_h = grill_mag_proud + grill_mag_clear + 0.2;   // how far magnet sits proud

    cap_thk = 1.8;   // thickness of cap itself — 1.5–2.0 mm is sweet spot

    difference() {
        union() {
            // Main cap body
            cylinder(d = cap_od, h = cap_thk + pocket_h, $fn = 48);

            // Small insertion chamfer / lead-in on outer edge
            translate([0, 0, cap_thk + pocket_h - 0.6])
                cylinder(d1 = cap_od, d2 = cap_od + 0.8, h = 0.6, $fn = 48);
        }

        // Pocket for magnet (from back)
        translate([0, 0, -0.01])
            cylinder(d = pocket_d, h = pocket_h + 0.02, $fn = 48);

        // Optional: small center dimple for easier removal with tool
        translate([0, 0, cap_thk + pocket_h - 0.4])
            cylinder(d = 2.5, h = 0.8, $fn = 32);
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

    for (p = pos) {
        // Position cap on back face of boss
        // Boss back = Y = -grill_boss_h
        // Cap sits flush or slightly recessed (adjust z-offset if needed)
        translate([p[0], -grill_boss_h - grill_cap_thk/2 + 0.1, p[1]]) {  // +0.1 for slight recess
            rotate([-90, 0, 0])
                grill_mag_retention_cap();
        }
    }
}