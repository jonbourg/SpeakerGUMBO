// baffle.scad - corrected with parameter passing
include <parameters.scad>
include <drivers.scad>

echo("=== USING BAFFLE.SC AD ===");

// Helper Function for Grill Magnets
function clampF(lo, hi, v) = min(max(v, lo), hi);


// ===================== MODULES =====================

module base_rounded_plate(outerW, outerH, THK, cornerR) {
    r = cornerR;
    r_safe = clampF(r, 0, min(outerW, outerH)/2 - 0.5);
    if (r_safe <= 0) {
        cube([outerW, THK, outerH], center=true);
    } else {
        rotate([90,0,0])
            linear_extrude(height=THK, center=true)
                minkowski() {
                    square([outerW - 2*r_safe, outerH - 2*r_safe], center=true);
                    circle(r=r_safe);
                }
    }
}


// --------------------------------------------------
// FRONT EDGE CHAMFERS (front face only)
// --------------------------------------------------
module front_edge_chamfers(cham, outerW, outerH, THK) {
    
    echo("LOCAL front_edge_chamfers ACTIVE");

    // Left
    translate([-outerW/2, THK/2 + cham/2, 0])
        rotate([0,0,45])
            cube([cham*2, cham*2, outerH+20], center=true);

    // Right
    translate([ outerW/2, THK/2 + cham/2, 0])
        rotate([0,0,-45])
            cube([cham*2, cham*2, outerH+20], center=true);

    // Top
    translate([0, THK/2 + cham/2, outerH/2])
        rotate([45,0,0])
            cube([outerW+20, cham*2, cham*2], center=true);

    // Bottom
    translate([0, THK/2 + cham/2, -outerH/2])
        rotate([-45,0,0])
            cube([outerW+20, cham*2, cham*2], center=true);
}


// Chamfer for vertical edges (left/right)
module chamfer_cut_v(len, THK, chamfer) {
    translate([THK/2 - chamfer/2, 0, 0])
        cube([chamfer, chamfer, len + 2], center = true);
}



module baffle_outer_roundover_front(outerW, outerH, THK, r) {
    r_eff = clampF(r, 0, 8);
    if (r_eff <= 0) {
        base_rounded_plate(outerW, outerH, THK, baffleCornerR);
    } else {
        let(
            baseW = max(0.1, outerW - 2*r_eff),
            baseH = max(0.1, outerH - 2*r_eff)
        )
        intersection() {
            translate([0, -r_eff, 0])
                minkowski() {
                    cube([baseW, THK, baseH], center=true);
                    sphere(r=r_eff);
                }
            cube([outerW + 2*r_eff, THK, outerH + 2*r_eff], center=true);
        }
    }
}

module baffle_frame_outer(outerW, outerH, THK) {
    edgeR_local = clampF(baffleEdgeSize, 0, 8);

    // Style 2 = rounded *front edge* (keep corners rounded)
    if (baffleEdgeStyle == 2 && edgeR_local > 0) {
        baffle_outer_roundover_front(outerW, outerH, THK, edgeR_local);

    // Style 1 = chamfered *front edge* (keep corners rounded)
    } else if (baffleEdgeStyle == 1 && edgeR_local > 0) {
        difference() {
            base_rounded_plate(outerW, outerH, THK, baffleCornerR);
            front_edge_chamfers(edgeR_local, outerW, outerH, THK);
        }

    // Style 0 (or anything else) = flat *front edge* (but corners still rounded)
    } else {
        base_rounded_plate(outerW, outerH, THK, baffleCornerR);
    }
}


module baffle_core_solid(coreW, coreH, THK) {
    cube([coreW, THK, coreH], center=true);
}

module baffle_frame_solid(coreW, coreH, THK, outerW, outerH, baffleSlotPosX, baffleSlotPosZ, baffleKeyPosX, baffleKeyPosZ) {
    difference() {
        baffle_frame_outer(outerW, outerH, THK);
        cube([coreW, THK+0.2, coreH], center=true);

        translate([baffleSlotPosX, -THK/2 + tabPocketDepth/2, baffleSlotPosZ])
            cube([baffleSlotLength + 2*tabPocketClearance,
                  tabPocketDepth+.01,
                  baffleSlotWidth + 2*tabPocketClearance],
                 center=true);

        translate([baffleKeyPosX, -THK/2 + tabPocketDepth/2, baffleKeyPosZ])
            rotate([0,0,0])
                linear_extrude(height=tabPocketDepth+.01, center=true)
                    offset(r = 1 + tabPocketClearance)
                        square([baffleKeyLength - 2, baffleKeyWidth - 2], center=true);
    }
}

// 2D cutout profile for the *through* opening
module through_cutout_2d(j, shape) {
    // Prefer driver cutout diameter for acoustic hole size
    d = driverParams[j][0];

    if (shape == 0) {
        circle(d = d);
    }
    else if (shape == 4) {
        // Shape 4 = clipped circle (4 flats)
        // Use the same flat ratio you used in drivers.scad (adjust if you have a standard)
        // This makes a circle with 4 flats by intersecting with a square.
        flat = 0.86;  // 0.80-0.92 typical; 0.86 gives visible flats without over-clipping
        intersection() {
            circle(d = d);
            square([d*flat, d*flat], center=true);
        }
    }
    else {
        // Fallback to round unless you want other shapes as through cutouts too
        circle(d = d);
    }
}

// Shape 4: clipped circle (4 flats)
module shape4_2d(d) {
    flat = 0.86;  // same value used elsewhere
    intersection() {
        circle(d = d);
        square([d*flat, d*flat], center=true);
    }
}


module baffle_driver_features(THK) {
    echo("baffle_driver_features called - number of drivers:", len(enabledDriverIdx));
    
    for (k = [0:len(enabledDriverIdx)-1]) {
        j = enabledDriverIdx[k];
        driver = driverParams[j];
        dia = driver[0];
        screwSpacing = driver[1];
        screwDia = driver[2];
        faceDia = speakerFaceDiameters[j];
        shape = driverFaceShape[j];
        recessDepth = driverRecessDepth[j];
        screwCount = driverScrewCount[j];
        zPos = z_for_driver(j);
        driverXoffset_raw =
            j == 0 ? tweeterX_offset :
            j == 1 ? midX_offset :
                     wooferX_offset;
        
        innerHalfW = boxIntWidth / 2;
        faceR = (shape == 3)
            ? driverRectSizes[j][0] / 2
            : speakerFaceDiameters[j] / 2;
        marginX = innerHalfW - faceR;
        Xmax =
            (marginX <= 0) ? 0 :
            (marginX <= driverEdgeMin) ? 0 :
                                         (marginX - driverEdgeMin);
        driverX = clampF(driverXoffset_raw, -Xmax, Xmax);
        
        echo("Processing driver", j, "at Z:", zPos, "X offset:", driverXoffset_raw);
        
        // 1) FLUSH TRIM RING (if enabled)
        if (!driverSurfaceMount[j] && flushTrimDepth > 0) {
            trimY = THK/2 - flushTrimDepth/2;
            translate([driverX, trimY, zPos])
                rotate([90,0,0]) {
                    faceDia = speakerFaceDiameters[j];
                    trimDia = faceDia + 2*trimMargin;
                    
                    // Shape-specific trim ring cutouts (copy your original cases here)
                    if (shape == 0) {
                        cylinder(r = trimDia/2, h = flushTrimDepth + 0.5, center = true);
                    }
                    else if (shape == 1) {
                        w = driverRectSizes[j][0] + 2*trimMargin;
                        h = driverRectSizes[j][1] + 2*trimMargin;
                        linear_extrude(height = flushTrimDepth + 0.5, center=true)
                            square([w, h], center=true);
                    }
                    else if (shape == 2) {
                        w = driverRectSizes[j][0] + 2*trimMargin;
                        h = driverRectSizes[j][1] + 2*trimMargin;
                        r2 = driverCornerRadius[j] > 0 ? driverCornerRadius[j] : min(w, h)*0.15;
                        linear_extrude(height = flushTrimDepth + 0.5, center=true)
                            offset(r = r2)
                                square([w - 2*r2, h - 2*r2], center=true);
                    }
                    // ... add your other shape cases (3,4,5,6,7) from your original code ...
                    // RECTANGULAR FACE
                    else if (shape == 3) {
                        w = driverRectSizes[j][0] + 2*trimMargin;
                        h = driverRectSizes[j][1] + 2*trimMargin;
                        linear_extrude(height = flushTrimDepth + 0.5, center=true)
                            square([w, h], center=true);
                    }

                    // CLIPPED CIRCLE FACE (Faital-style) - TRIM
                    else if (shape == 4) {
                        baseDia  = faceDia;
                        faceDiaT = baseDia + 2*trimMargin;
                        userClip = driverClipDepth[j];
                        autoClip = 0.08 * baseDia;
                        clip     = (userClip > 0) ? userClip : autoClip;

                        linear_extrude(height = flushTrimDepth + 0.5, center=true)
                            clipped_circle_2d(faceDiaT, clip);
                    }

                    // TOP/BOTTOM CLIPPED CIRCLE - TRIM
                    else if (shape == 5) {
                        userClip = driverClipDepth[j];
                        autoClip = 0.08 * faceDia;
                        clip     = (userClip > 0) ? userClip : autoClip;

                        linear_extrude(height = flushTrimDepth + 0.5, center=true)
                            clipped_circle_tb_2d(faceDia + 2*trimMargin, clip);
                    }

                    // SQUIRCLE (shape 6) - TRIM
                    else if (shape == 6) {
                        D = faceDia + 2*trimMargin;
                        linear_extrude(height = flushTrimDepth + 0.5, center=true)
                            squircle_2d(faceDia + 2*trimMargin);
                    }

                    // ADJUSTABLE SUPERELLIPSE (shape 7) - TRIM
                    else if (shape == 7) {
                        n7 = driverAdjustCurvature[j];
                        r7 = driverAdjustCornerR[j];
                        linear_extrude(height = flushTrimDepth + 0.5, center=true)
                            rotate(45)
                                shape7_2d(trimDia, trimDia, r7, n7);
                    }

                    // Fallback: round
                    else {
                        cylinder(
                            r = trimDia/2,
                            h = flushTrimDepth + 0.5,
                            center = true
                        );
                    }                    
                }
        }
        
        
        
        // 2) RECESS POCKET
        if (!driverSurfaceMount[j] && recessDepth > 0) {
            recessY = THK/2 - recessDepth/2;
            translate([driverX, recessY, zPos])
                rotate([90,0,0]) {

                    faceDia = speakerFaceDiameters[j];

                    // SHAPE 0 — round
                    if (shape == 0) {
                        cylinder(
                            r = faceDia/2,
                            h = recessDepth + 0.5,
                            center = true
                        );
                    }

                    // SHAPE 1 — square
                    else if (shape == 1) {
                        linear_extrude(height = recessDepth + 0.5, center=true)
                            square(
                                [driverRectSizes[j][0],
                                 driverRectSizes[j][1]],
                                center=true
                            );
                    }

                    // SHAPE 2 — rounded square
                    else if (shape == 2) {
                        w = driverRectSizes[j][0];
                        h = driverRectSizes[j][1];
                        r2 = driverCornerRadius[j] > 0
                             ? driverCornerRadius[j]
                             : min(w, h) * 0.15;

                        linear_extrude(height = recessDepth + 0.5, center=true)
                            offset(r = r2)
                                square([w - 2*r2, h - 2*r2], center=true);
                    }

                    // SHAPE 3 — rectangle
                    else if (shape == 3) {
                        linear_extrude(height = recessDepth + 0.5, center=true)
                            square(
                                [driverRectSizes[j][0],
                                 driverRectSizes[j][1]],
                                center=true
                            );
                    }

                    // SHAPE 4 — clipped circle (4 flats)
                    else if (shape == 4) {
                        linear_extrude(height = recessDepth + 0.5, center=true)
                            shape4_2d(faceDia);
                    }

                    // SHAPE 5 — top/bottom clipped circle
                    else if (shape == 5) {
                        userClip = driverClipDepth[j];
                        autoClip = 0.08 * faceDia;
                        clip     = (userClip > 0) ? userClip : autoClip;

                        linear_extrude(height = recessDepth + 0.5, center=true)
                            clipped_circle_tb_2d(faceDia, clip);
                    }

                    // SHAPE 6 — squircle / superellipse
                    else if (shape == 6) {
                        linear_extrude(height = recessDepth + 0.5, center=true)
                            squircle_2d(faceDia);
                    }

                    // SHAPE 7 — hybrid (MATCHES OVERLAY EXACTLY)
                    else if (shape == 7) {
                        
                        cornerR =
                            is_num(driverAdjustCornerR[j])
                                ? driverAdjustCornerR[j]
                                : speakerFaceDiameters[j] * 0.06;

                        curvature =
                            is_num(driverAdjustCurvature[j])
                                ? driverAdjustCurvature[j]
                                : 0.5;
                        
                        linear_extrude(height = recessDepth + 0.5, center = true)
                            rotate(45)
                                shape7_2d(
                                    speakerFaceDiameters[j],
                                    speakerFaceDiameters[j],
                                    cornerR,
                                    curvature
                                );
                    }
                }
            }

        
        // 3) THROUGH CUTOUT  - CHATGPT DO NOT MAKE THIS SHAPE AWARE
        translate([driverX, 0, zPos])
            rotate([90,0,0])
                cylinder(r = dia/2, h = THK + 2, center = true);
        
        // 4) SCREW HOLES
        if (screwCount > 0) {
            effectiveScrewSpacing = (screwSpacing <= 0) ? dia*1.05 : screwSpacing;
            for (aIndex = [0:screwCount-1]) {
                angle = (screwCount == 3) ? [90, -30, -150][aIndex] : (aIndex * 360/screwCount + 45);
                sx = cos(angle) * effectiveScrewSpacing/2;
                sz = sin(angle) * effectiveScrewSpacing/2;
                translate([driverX + sx, 0, zPos + sz])
                    rotate([90,0,0])
                        cylinder(r = screwDia/2, h = THK + 2, center = true);
            }
        }
        
        // --------------------------------------------------
        // GRILL MAGNET CUTS
        // --------------------------------------------------
        if (grill_enable)
            baffle_grill_magnets(outerW, outerH, THK);
    }
}

// ============================================================
// FULL-FACE GRILL MAGNET SYSTEM (rear install, sealed)
// ============================================================
module baffle_grill_magnets(outerW, outerH, THK) {
    
    if (!is_undef(grill_enable) && grill_enable) {
        
        echo("=== GRILL MAGNET DEBUG (enabled) ===");
        echo("Baffle thickness (THK): ", THK);
        
        // Fallback-safe computations (define these properly in grill.scad if missing)
        skin = is_undef(grill_compute_skin) 
               ? grill_skin_min 
               : grill_compute_skin(THK);
        
        mag_depth = is_undef(grill_compute_mag_depth) 
                    ? grill_mag_thk + grill_mag_clear + 0.5 
                    : grill_compute_mag_depth();
        
        plug_depth = is_undef(grill_compute_plug_depth) 
                     ? mag_depth + grill_skin_min + 0.5 
                     : grill_compute_plug_depth(THK);
        
        echo("Keeper skin (front): ", skin);
        echo("Magnet pocket depth: ", mag_depth);
        echo("Plug depth (rear): ", plug_depth);
        echo("Front face Y: ", THK/2);
        echo("Magnet pocket forward face Y: ", THK/2 - skin);
        echo("Magnet pocket rear face Y: ", (THK/2 - skin) - mag_depth);
        echo("==========================");
        
        // Safety checks
        assert(THK >= skin + mag_depth + plug_depth + 0.5,
               str("Baffle too thin for grill magnet system — required min thickness = ", 
                   skin + mag_depth + plug_depth + 0.5, " mm"));
        
                
        // ─── Placement ───
        edge_margin = clampF(10, 15, 0.08 * min(outerW, outerH));
        xL = -outerW/2 + edge_margin;
        xR =  outerW/2 - edge_margin;
        z1 = -0.30 * outerH;
        z2 = 0;
        z3 =  0.30 * outerH;
        
        positions = [
            [xL, z1], [xL, z2], [xL, z3],
            [xR, z1], [xR, z2], [xR, z3]
        ];
        
        for (p = positions) {
            x = p[0];
            z = p[1];
            
            // Rear magnet pocket
            translate([x, -THK/2 + skin + mag_depth/2, z])
                rotate([90,0,0])
                    cylinder(
                        d = grill_mag_dia + grill_mag_clear,
                        h = mag_depth + 0.01,
                        center = true
                    );
            
            // Rear plug pocket
            translate([x, -THK/2 + plug_depth/2, z])
                rotate([90,0,0])
                    cylinder(
                        d = grill_mag_dia + grill_mag_clear,
                        h = plug_depth + 0.01,
                        center = true
                    );
            
            // Front witness dimple (optional, small cosmetic dent)
            translate([x, THK/2 - grill_dimple_depth/2, z])
                rotate([90,0,0])
                    cylinder(
                        d = grill_dimple_dia,
                        h = grill_dimple_depth + 0.01,
                        center = true
                    );
        }
    } else {
        // Optional debug when skipped
        if (is_undef(grill_enable)) {
            echo("WARNING: grill_enable undefined — magnet pockets skipped");
        } else {
            echo("Grill magnets disabled (grill_enable = false)");
        }
    }
}


module baffle_full(coreW, coreH, THK, outerW, outerH, baffleSlotPosX, baffleSlotPosZ, baffleKeyPosX, baffleKeyPosZ) {
    difference() {
        union() {
            baffle_core_solid(coreW, coreH, THK);
            baffle_frame_solid(coreW, coreH, THK, outerW, outerH, baffleSlotPosX, baffleSlotPosZ, baffleKeyPosX, baffleKeyPosZ);
        }
        baffle_driver_features(THK);  // pass THK if it uses it
    }
}

// Module to Make Plugs to fill in the back of the grill magnet holes.
module grill_magnet_plug(plug_depth)
{
    chamfer = 0.4;

    difference() {
        cylinder(
            d = grill_mag_dia + grill_mag_clear - 0.4,
            h = plug_depth,
            center = false
        );

        // insertion chamfer
        translate([0,0,plug_depth - chamfer])
            cylinder(
                d1 = grill_mag_dia + grill_mag_clear + 0.4,
                d2 = grill_mag_dia + grill_mag_clear - 0.2,
                h = chamfer,
                center = false
            );
    }
}

module grill_magnet_plugs_array(plug_depth, count = grill_mag_count)
{
    spacing = grill_mag_dia + 6;

    for (i = [0 : count-1])
        translate([i * spacing, 0, 0])
            grill_magnet_plug(plug_depth);
}


