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


    // Fill control — 1.0 = hexes touch mask edge, <1.0 = intentional inset
    hex_fill_ratio = 2.0;   // very close to edge, slight safety
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
                cylinder(d = grill_boss_d, h = grill_boss_h, center = false, $fn = 32);
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
                cylinder(d = mag_d, h = cavity_depth + 0.2, center = true, $fn = 48);
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
            cylinder(d = cap_od, h = cap_thk + pocket_h - chamfer_depth, $fn = 48);

            // Chamfer at HIGH Z / REAR (exposed side after rotation)
            translate([0, 0, (cap_thk + pocket_h) - chamfer_depth])
                cylinder(  // # for debug highlight (remove when done)
                    d1 = cap_od,                      // wide at base (inside cap)
                    d2 = cap_od - 2 * chamfer_width,  // narrow at very rear (exposed face)
                    h = chamfer_depth,
                    $fn = 48
                );
        }

        // Pocket from LOW Z / FRONT (against grill / boss)
        translate([0, 0, -0.01])  // cut from bottom
            cylinder(d = pocket_d, h = pocket_h + 0.02, $fn = 48);
        
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