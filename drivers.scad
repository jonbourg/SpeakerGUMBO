// drivers.scad
// Pure library file: ONLY function and module definitions
// All computations (margin, enabledDriverIdx, zPositions, etc.) 
// are done in the main file after includes.

include <utils.scad>


// =============================================
// HELPER FUNCTIONS (pure – no side effects)
// =============================================

function getMargin(drivers) =
    drivers == [] ? 0 : max([for(d=drivers) d[3] ? d[0]/2 + 5 : 0]);

// Automatic top-to-bottom packing of enabled driver face envelopes.
// Radii are ordered by enabledDriverIdx (tweeter, midrange, woofer).
// The complete stack is centered vertically; manual offsets are applied ONCE
// in z_for_driver(). Impossible fits are reported in the main file.
function driver_stack_height(radii, gap) =
    len(radii) == 0 ? 0 :
    2 * sum_list(radii) + (len(radii) - 1) * gap;

function sum_list(values, i = 0) =
    i >= len(values) ? 0 : values[i] + sum_list(values, i + 1);

function compute_z_positions_ordered(faceRadii, boxHeight, gap = 5) =
    let(n = len(faceRadii), total = driver_stack_height(faceRadii, gap))
    n == 0 ? [] :
    [for (i = [0:n-1])
        total/2 -
        (i == 0 ? 0 : 2 * sum_list([for (k = [0:i-1]) faceRadii[k]]) + i*gap) -
        faceRadii[i]
    ];

function driver_z_offset(i) =
    i == 0 ? tweeterZ_offset : i == 1 ? midZ_offset : wooferZ_offset;

function z_for_driver(i) =
    let(pos = search(i, enabledDriverIdx),
        z_raw = pos == [] ? undef : zPositions[pos[0]])
    is_undef(z_raw) ? undef : z_raw + driver_z_offset(i);

// Shared positioning and clearance helpers (X/Z are baffle-plane coordinates).
// The horizontal clamp is retained for compatibility with existing geometry.
function driver_x_requested(i) =
    i == 0 ? tweeterX_offset : i == 1 ? midX_offset : wooferX_offset;
function driver_half_width(i) =
    (driverFaceShape[i] == 2 || driverFaceShape[i] == 3)
        ? driverRectSizes[i][0]/2 : speakerFaceDiameters[i]/2;
function driver_half_height(i) =
    (driverFaceShape[i] == 2 || driverFaceShape[i] == 3)
        ? driverRectSizes[i][1]/2 : speakerFaceDiameters[i]/2;
function driver_x_limit(i) =
    max(0, boxIntWidth/2 - driver_half_width(i) - driverEdgeMin);
function driver_x_actual(i) =
    clampF(driver_x_requested(i), -driver_x_limit(i), driver_x_limit(i));
function driver_is_rect(i) = driverFaceShape[i] == 3;
// Circle-vs-circle and axis-aligned rectangle-vs-rectangle are exact.
// Other shapes are conservatively enclosed by their bounding rectangles;
// those warnings can include false positives, but should not miss collisions.
function driver_pair_overlaps(a,b) =
    let(dx = abs(driver_x_actual(a)-driver_x_actual(b)),
        dz = abs(z_for_driver(a)-z_for_driver(b)),
        ax = driver_half_width(a), az = driver_half_height(a),
        bx = driver_half_width(b), bz = driver_half_height(b),
        both_round = driverFaceShape[a] == 0 && driverFaceShape[b] == 0,
        both_rect = driver_is_rect(a) && driver_is_rect(b))
    both_round ? sqrt(dx*dx + dz*dz) < ax + bx - 0.0001 :
    both_rect ? dx < ax+bx-0.0001 && dz < az+bz-0.0001 :
    // Conservative axis-aligned envelopes for noncircular face profiles.
    dx < ax+bx-0.0001 && dz < az+bz-0.0001;

// ======================================================================
// DRIVER DERIVED VALUES FOR GASKETS
// ======================================================================

function max_driver_diameter() =
    max([
        for (j = [0 : len(driverParams) - 1])
            driverParams[j][3]
                ? driver_bounding_diameter(j)
                : 0
    ]);

// ============================================================
// DRIVER CUTOUT (2D) — canonical driver outline
// Used by baffle, gaskets, fit tests
// ============================================================
module driver_cutout_2d(j, clearance = 0) {

    shape = driverFaceShape[j];

    faceDia = speakerFaceDiameters[j];
    rectW   = driverRectSizes[j][0];
    rectH   = driverRectSizes[j][1];
    clip    = driverClipDepth[j];

    // clearance expands outward
    faceDiaC = faceDia + 2*clearance;
    rectWC   = rectW   + 2*clearance;
    rectHC   = rectH   + 2*clearance;

    if (shape == 0) {
        circle(d = faceDiaC);
    }
    else if (shape == 1) {
        square([faceDiaC, faceDiaC], center = true);
    }
    else if (shape == 2) {
        r2 = driverCornerRadius[j] > 0 ? driverCornerRadius[j] : min(rectWC, rectHC) * 0.15;
        offset(r = r2)
            square([rectWC - 2*r2, rectHC - 2*r2], center = true);
    }
    else if (shape == 3) {
        square([rectWC, rectHC], center = true);
    }
    else if (shape == 4) {
        clipped_circle_2d(faceDiaC, clip);
    }
    else if (shape == 5) {
        clipped_circle_tb_2d(faceDiaC, clip);
    }
    else if (shape == 6) {
        squircle_2d(faceDiaC);
    }
    else if (shape == 7) {
        rotate(45)
            shape7_2d(faceDiaC, faceDiaC, driverAdjustCornerR[j], driverAdjustCurvature[j]);
    }
    else {
        circle(d = faceDiaC);
    }
}



// =============================================
// DRIVER CUTOUTS MODULE
// =============================================
module box_driver_cutouts() {
    
    echo("box_driver_cutouts called - number of drivers:", len(enabledDriverIdx));
    
    for (k = [0:len(enabledDriverIdx)-1]) {
        j = enabledDriverIdx[k];
        driver = driverParams[j];
        dia = driver[0];
        screwSpacing = driver[1];
        screwDia = driver[2];
        zPos = z_for_driver(j);
        driverXoffset_raw = j == 0 ? tweeterX_offset : j == 1 ? midX_offset : wooferX_offset;
        
        echo("Processing driver", j, "dia =", dia, "Z =", zPos, "X offset =", driverXoffset_raw);
    }
    
    for (k = [0:len(enabledDriverIdx)-1]) {
        j = enabledDriverIdx[k];
        driver = driverParams[j];
        dia = driver[0];
        screwSpacing = driver[1];
        screwDia = driver[2];
        zPos = z_for_driver(j);
        driverXoffset_raw = driver_x_requested(j);
        driverX = driver_x_actual(j);
        
        screwCount = driverScrewCount[j];
        effectiveScrewSpacing = (screwSpacing <= 0) ? dia*1.05 : screwSpacing;

        // Main hole
        translate([driverX, boxIntDepth/2 + boxThickness/2, zPos])
            rotate([90,0,0])
                cylinder(r=dia/2,
                         h=boxThickness + 10,
                         center=true);

        // Screw holes
        for (aIndex = [0:screwCount-1]) {
            angle = (screwCount == 3) ?
                [90, -30, -150][aIndex] :
                (aIndex * 360 / screwCount + 45);
            x = cos(angle) * effectiveScrewSpacing/2;
            z = sin(angle) * effectiveScrewSpacing/2;
            translate([driverX + x, boxIntDepth/2 + boxThickness/2, zPos + z])
                rotate([90,0,0])
                    cylinder(r=screwDia/2,
                             h=boxThickness *.75,
                             center=true);
        }
    }
}

module driver_face_overlay_2d(shape, j) {
    faceDia = speakerFaceDiameters[j];
    rectW = driverRectSizes[j][0];
    rectH = driverRectSizes[j][1];
    cornerR = driverCornerRadius[j] > 0 ? driverCornerRadius[j] : faceDia * 0.15;
    clip = driverClipDepth[j];

    if (shape == 0) {
        color([0,1,0,0.35]) circle(r = faceDia/2);                    // ← added 0.35
    }
    else if (shape == 1) {
        color([1,0.5,0,0.35]) square([faceDia, faceDia], center = true);  // ← added
    }
    else if (shape == 2) {
        color([0,0.7,1,0.35])                                         // ← added
            offset(r = cornerR)
                square([faceDia - 2*cornerR, faceDia - 2*cornerR], center = true);
    }
    else if (shape == 3) {
        color([1,0,0.5,0.35]) square([rectW, rectH], center = true);   // ← added
    }
    else if (shape == 4) {
        color([1,0,1,0.35])                                           // ← added
            intersection() {
                circle(r = faceDia/2);
                square([faceDia - 2*clip, faceDia], center = true);
                square([faceDia, faceDia - 2*clip], center = true);
            };
    }
    else if (shape == 5) {
        color([1,0.5,0,0.35])                                         // ← added (amber)
            intersection() {
                circle(r = faceDia/2);
                square([faceDia, faceDia - 2*clip], center = true);
            };
    }
    else if (shape == 6) {
        color([0,0.5,1,0.35])
            squircle_2d(faceDia);
    }
    else if (shape == 7) {
        color([0.2, 0.8, 1.0, 0.35])                                  // ← added (cyan)
            rotate(45)
                shape7_2d(faceDia, faceDia, driverAdjustCornerR[j], driverAdjustCurvature[j]);
    }
}

// Full 3D overlay module (called from main)
module driver_face_overlays(baffle_front_y) {
    if (showDriverFaces) {
        for (k = [0:len(enabledDriverIdx)-1]) {
            j = enabledDriverIdx[k];
            zPos = z_for_driver(j);
            shape = driverFaceShape[j];
            driverX = driver_x_actual(j);
            
            // Pure 2D overlay – always transparent in preview & render
            translate([driverX, baffle_front_y + 0.1, zPos])
            rotate([90,0,0])
                driver_face_overlay_2d(shape, j);  // ← no linear_extrude!
        }
    }
}
// =============================================
// DEBUG CYLINDERS (driver centers)
// =============================================
module driver_debug_cylinders() {
    if (showDebug) {
        driverColors = ["red", "green", "blue"];
        for (k = [0:len(enabledDriverIdx)-1]) {
            j = enabledDriverIdx[k];
            dia = driverParams[j][0];
            zPos = z_for_driver(j);
            
            // Pure 2D circle instead of cylinder
            translate([0, boxIntDepth/2 + boxThickness + 5 + k*5, zPos])
            rotate([90,0,0])
            color(driverColors[k % len(driverColors)], 0.5)
                circle(r = dia/2);           // ← 2D circle, always transparent in preview
        }
    }
}


// ============================================================
// DRIVER FACE POCKET (2D)
// ============================================================
/* module face_shape_pocket(
    faceShape,
    driver_outer_dia,
    clip_depth
) {

    if (faceShape == 0)
        circle(d = driver_outer_dia);

    else if (faceShape == 1)
        square([driver_outer_dia, driver_outer_dia], center = true);

    else if (faceShape == 2)
        offset(r = shape2_corner_r)
            square([
                driver_outer_dia - 2 * shape2_corner_r,
                driver_outer_dia - 2 * shape2_corner_r
            ], center = true);

    else if (faceShape == 3)
        square([rect_w, rect_h], center = true);

    else if (faceShape == 4)
        clipped_circle_2d(driver_outer_dia, clip_depth);

    else if (faceShape == 5)
        clipped_circle_tb_2d(driver_outer_dia, clip_depth);

    else if (faceShape == 6)
        //squircle_2d(driver_outer_dia, squircle_n);
        squircle_2d(driver_outer_dia);

    else if (faceShape == 7)
        adjustable_shape_2d(
            driver_outer_dia,
            driver_outer_dia,
            shape7_corner_r,
            driverAdjustCurvature
        );

    else
        circle(d = driver_outer_dia);
} */

module face_shape_pocket(faceShape, driver_outer_dia, clip_depth) {
    // Deprecated signature retained for compatibility.
    // Prefer driver_cutout_2d(j, clearance) for new code.
    circle(d = driver_outer_dia); // fallback (safe)
}


// ============================================================
// SCREW HOLE PATTERN
// ============================================================
module screw_holes(count, pcd, hole_d, depth, rot = 0) {
    for (i = [0 : count - 1]) {
        angle = 360 / count * i + rot;
        translate([
            cos(angle) * pcd / 2,
            sin(angle) * pcd / 2,
            0
        ])
            cylinder(h = depth + 0.1, d = hole_d);
    }
}




// MODULE FOR THE FIT TEST PUCK
module flush_fit_test_puck(
    faceShape,
    driver_outer_dia,
    driver_cutout_dia,
    flush_depth,
    under_flange_thk,
    screw_count,
    screw_circle_dia,
    screw_hole_dia,
    screw_rotation,
    clip_depth,
    shape_fit_tolerance,
    cutout_fit_tolerance,   // ← ADD COMMA HERE
    puck_dia_override = undef  // ← now valid
) {
    total_thickness = flush_depth + under_flange_thk;

    // Use override if provided, else old calculation
    disk_diameter =
    is_undef(puck_dia_override)
        ? (driver_outer_dia + 2*12)   // 12mm margin default
        : puck_dia_override;


    difference() {
        cylinder(h = total_thickness, d = disk_diameter);
        
        // Flush pocket
        translate([0, 0, total_thickness - flush_depth])
            linear_extrude(height = flush_depth + 0.01)
                offset(delta = shape_fit_tolerance)
                    face_shape_pocket(
                        faceShape,
                        driver_outer_dia,
                        clip_depth
                    );

        // Basket cutout
        translate([0, 0, -0.01])
            cylinder(
                h = total_thickness + 0.02,
                d = driver_cutout_dia + cutout_fit_tolerance
            );

        // Screw holes
        translate([0, 0, -0.01])
            screw_holes(
                screw_count,
                screw_circle_dia,
                screw_hole_dia,
                total_thickness,
                screw_rotation
            );
    }
}
