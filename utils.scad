// utils.scad
// General-purpose helper functions and modules used across the project
// (countersunk holes, port tubes, flares, clamps, etc.)
// Includes the adjustable superellipse shape7_2d used for driver faces


// ============================================================
// HELPERS
// ============================================================

function diag(w, h) = sqrt(w*w + h*h);

// Clipped circle flat length (4-flat style)
function clipped_flat_length(d, flat_ratio) =
    d * flat_ratio;
    
// Length of one flat on a clipped circle
    function clipped_flat_chord_length(d, clip) =
        let(R = d / 2)
        2 * sqrt(R*R - (R - clip)*(R - clip));
        
function grill_compute_skin(thk) = grill_skin_min;

function grill_compute_mag_depth() = grill_mag_thk + grill_mag_clear + 0.5;

function grill_compute_plug_depth(thk) = 
    let (pd = grill_mag_thk + grill_mag_clear + grill_skin_min + 0.5)
    min(pd, thk * 0.6);  // never more than 60% of baffle thickness
       
function clamp_min(v, minv) = (v < minv) ? minv : v;

// Driver Bourding Diameter for Gaskets
function driver_bounding_diameter(j) =
    (driverFaceShape[j] == 0 ||
     driverFaceShape[j] == 4 ||
     driverFaceShape[j] == 5 ||
     driverFaceShape[j] == 6 ||
     driverFaceShape[j] == 7)
        ? speakerFaceDiameters[j]
        : diag(
            driverRectSizes[j][0],
            driverRectSizes[j][1]
          );
 
        
    
// ============================================================
// MODULES
// ============================================================    

module countersunk_hole(d_through, d_head, depth_head, panel_thickness) {
    // Through-hole along +Z (we rotate later)
    cylinder(
        r = d_through/2,
        h = panel_thickness + backPanelTongueDepth + 4,
        center = true
    );
    // Conical countersink
    translate([0, 0, panel_thickness/2 - depth_head/2])
        cylinder(
            r1 = d_through/2,      // narrow (inside)
            r2 = d_head/2,         // wide (outside)
            h = depth_head,
            center = true
        );
}

module port_flare_outer_cone(d_inside, d_flare, depth_flare, panel_thickness) {
    translate([0, 0, panel_thickness/2 - depth_flare/2])
        cylinder(
            r1 = d_inside/2,       // narrow (port ID)
            r2 = d_flare/2,        // wide (mouth)
            h = depth_flare,
            center = true
        );
}

module printed_port_tube(id, length, wall) {
    difference() {
        cylinder(r = id/2 + wall, h = length, center = false);
        cylinder(r = id/2, h = length + 0.5, center = false);
    }
}

// What does this do?
module square_cutout(width_mm, depth_mm) {
    corner_r = max(width_mm/6,1);
    halfW = width_mm/2;
    union() {
        translate([-halfW + corner_r,0,0])
            cylinder(r=corner_r, h=depth_mm, center=true);
        translate([ halfW - corner_r,0,0])
            cylinder(r=corner_r, h=depth_mm, center=true);
        translate([0,0,0])
            cube([width_mm - 2*corner_r, 2*corner_r, depth_mm], center=true);
    }
}

// ============================================================
// 2D SHAPE HELPERS (used in baffle, drivers, fit-test puck, etc.)
// ============================================================

// Shape 4 Clipped circle with 4 flats
module clipped_circle_2d(d, clip) {
    intersection() {
        circle(d = d);
        square([d - 2*clip, d - 2*clip], center = true);
    }
}

// Truncated circle (top/bottom flats)
module clipped_circle_tb_2d(faceDia, clip) {
    R = faceDia / 2;
    c = min(clip, R - 0.5);

    intersection() {
        circle(r = R);
        square([faceDia, faceDia - 2*c], center = true);
    }
}

// ======================================================================
// SHAPE 6 — SQUIRCLE (SHARED DEFINITION)
// ======================================================================
// d : overall diameter (mm)
// n : curvature exponent (fixed for Shape 6)
//
// n ≈ 2.0  → circle
// n ≈ 3.0  → classic squircle (recommended)
// n ≈ 4.0+ → more square-like
//
module squircle_2d(d, n = 3) {

    a = d / 2;
    steps = 180;

    polygon([
        for (i = [0 : steps])
            let(t = i * 360 / steps)
            [
                a * sign(cos(t)) * pow(abs(cos(t)), 2 / n),
                a * sign(sin(t)) * pow(abs(sin(t)), 2 / n)
            ]
    ]);
}


// ======================================================================
// SHAPE 7 — HYBRID SUPERLLIPSE (SHARED DEFINITION)
// ======================================================================
// Optional: add the superellipse 2D shape here too if you want
// (it's used in driver faces, but could be considered general-purpose)
module shape7_2d(w, h, corner_r, curvature_n) {

    // ---- INPUT SANITIZATION ----
    w = is_num(w) ? w : 0;
    h = is_num(h) ? h : 0;

    // Bail out cleanly if we still have no size
    if (w <= 0 || h <= 0) {
        echo("Shape7 skipped: invalid w/h", w, h);
        children();
    } else {

        corner_r =
            is_num(corner_r)
                ? corner_r
                : min(w, h) * 0.06;

        curvature_n =
            (is_num(curvature_n) && curvature_n > 0)
                ? curvature_n
                : 0.5;

        echo("Shape7 inputs:", w, h, corner_r, curvature_n);

        a = (w / 2) - corner_r;
        b = (h / 2) - corner_r;

        polygon([
            for (i = [0 : 0.5 : 360])
                let(
                    angle = i,
                    x = pow(abs(cos(angle)), 2/curvature_n)
                        * (a + corner_r)
                        * sign(cos(angle)),
                    y = pow(abs(sin(angle)), 2/curvature_n)
                        * (b + corner_r)
                        * sign(sin(angle))
                )
                [x, y]
        ]);
    }
}


// ────────────────────────────────────────────────
// 2D SHAPES - ADDED for GRILL
// ────────────────────────────────────────────────

// Rounded rectangle (safe)
module rounded_rect_2d(w, h, r) {
    w2 = clamp_min(w, 1);
    h2 = clamp_min(h, 1);
    r2 = min(r, min(w2, h2)/2 - 0.01);

    offset(r = r2)
        square([w2 - 2*r2, h2 - 2*r2], center = true);
} 

// Flat-top hexagon
module hex_2d(flat) {
    f = clamp_min(flat, 1);
    r = f / sqrt(3);

    polygon(points = [
        [ r,      0          ],
        [ r/2,    r*0.866025 ],
        [-r/2,    r*0.866025 ],
        [-r,      0          ],
        [-r/2,   -r*0.866025 ],
        [ r/2,   -r*0.866025 ]
    ]);
}

// Tiled hex pattern
module hex_pattern_2d(w, h) {
    flat = clamp_min(grill_pattern_hex_flat - grill_pattern_hex_gap, 1);
    dx = flat * 1.5;
    dy = flat * sqrt(3);

    rows = ceil(h / dy) + 1;
    cols = ceil(w / dx) + 1;

    for (r = [-rows : rows]) {
        y = r * dy;
        xoff = (r % 2 == 0) ? 0 : dx/2;

        for (c = [-cols : cols]) {
            translate([c*dx + xoff, y])
                hex_2d(flat);
        }
    }
}

// Returns 6 magnet centers in X/Z for a given outerW/outerH
function grill_mag_positions_xz(outerW, outerH) =
    let(
        // use whatever margin logic you’re already using (your clamp idea)
        margin = clampF(10, 15, 0.08 * min(outerW, outerH)),
        xL = -outerW/2 + margin,
        xR =  outerW/2 - margin,
        z1 = -0.30 * outerH,
        z2 =  0,
        z3 =  0.30 * outerH
    )
    [
        [xL, z1], [xL, z2], [xL, z3],
        [xR, z1], [xR, z2], [xR, z3]
    ];

/*
// Returns 6 magnet centers in X/Z for a given outerW/outerH
function grill_mag_positions_xz(outerW, outerH) =
    let(
        margin = min(0.08 * min(outerW, outerH), 15),
        xL = -outerW/2 + margin,
        xR =  outerW/2 - margin,
        zT =  0.30 * outerH,
        zM =  0,
        zB = -0.30 * outerH
    )
    [
        [xL, zB], [xL, zM], [xL, zT],
        [xR, zB], [xR, zM], [xR, zT]
    ]; */





