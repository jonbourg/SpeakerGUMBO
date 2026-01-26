// box.scad
// Speaker enclosure shell
// Owns ALL box geometry and mating planes
// Phase 2A: extraction only — NO behavior changes

include <parameters.scad>
include <utils.scad>
include <drivers.scad>   // for box_driver_cutouts()

// ======================================================================
// SPEAKER BOX (SHELL + INTERFACES)
// ======================================================================

module speaker_box() {

    // --------------------------------------------------
    // INTERNAL DIMENSIONS (from TS)
    // --------------------------------------------------
    boxIntHeight = baseLen * boxHeightRatio / ratioNorm;
    boxIntWidth  = baseLen * boxWidthRatio  / ratioNorm;
    boxIntDepth  = baseLen * boxDepthRatio  / ratioNorm;

    // --------------------------------------------------
    // OUTER DIMENSIONS
    // --------------------------------------------------
    outerW = boxIntWidth  + 2 * boxThickness;
    outerD = boxIntDepth  + 2 * boxThickness;
    outerH = boxIntHeight + 2 * boxThickness;

    // --------------------------------------------------
    // BACK MATING PLANES
    // --------------------------------------------------
    yBackOuter  = -outerD/2;
    yBackInner  = yBackOuter + boxThickness;
    yBackCenter = (yBackOuter + yBackInner) / 2;
    // Back panel inset pocket (relative to curved shell)
    yBackPocketCenter =
        yBackOuter
        + edge_round_radius
        + backPanelInsetFromCurve
        + backPanelInsetDepth/2;
    // Back panel inset pocket reference
    yBackPocketStart =
        yBackOuter
        + edge_round_radius
        + backPanelInsetFromCurve;
    // Back panel pocket + pilot hole reference
    yPocketFloor = yBackOuter + backPanelInsetDepth;
    yPilotCenter = yPocketFloor + backScrewPilotDepth/2;
    
    // Back inset pocket: keep curved rim, but pocket must open at the back face
    pocketOvershoot = 0.2; // ensures cut reaches outside cleanly
    
    // --------------------------------------------------
    // FRONT MATING PLANE (true flat face)
    // --------------------------------------------------
    yFrontMatingPlane =
        (frontTrim > 0)
            ? outerD/2 - frontTrim
            : outerD/2;

    // --------------------------------------------------
    // LOCAL BOX SUBMODULES
    // --------------------------------------------------

    module box_outer() {
        if (!round_horizontal_edges || edge_round_radius <= 0) {
            cube([outerW, outerD, outerH], center=true);
        } else {
            r = edge_round_radius;
            minkowski() {
                cube([
                    outerW - 2*r,
                    outerD - 2*r,
                    outerH - 2*r
                ], center=true);
                sphere(r = r);
            }
        }
    }

    module box_interior() {
        cube([boxIntWidth, boxIntDepth, boxIntHeight], center=true);
    }

    module box_back_opening() {
        translate([0, yBackOuter + boxThickness/2, 0])
            cube([boxIntWidth,
                  boxThickness + 2,
                  boxIntHeight],
                 center=true);
    }

    module box_front_trim() {
        if (frontTrim > 0) {
            translate([0, outerD/2 - frontTrim/2, 0])
                cube([outerW + 0.2, frontTrim, outerH + 0.2], center=true);
        }
    }

    // --------------------------------------------------
    // BAFFLE LOCATORS (slot + key pockets)
    // --------------------------------------------------
    module box_baffle_locators() {

        // Slot recess (left side)
        translate([
            baffleSlotPosX - (baffleSlotLength/2 + baffleLocClearance),
            outerD/2 - (baffleSlotDepth + frontTrim),
            baffleSlotPosZ - (baffleSlotWidth/2 + baffleLocClearance)
        ])
            cube([
                baffleSlotLength + 2*baffleLocClearance,
                baffleSlotDepth + frontTrim,
                baffleSlotWidth + 2*baffleLocClearance
            ], center = false);

        // Key recess (right side, rounded rectangle)
        keyPocketLen = baffleKeyLength + 2*baffleLocClearance;
        keyPocketWid = baffleKeyWidth  + 2*baffleLocClearance;

        translate([
            baffleKeyPosX,
            outerD/2 - (baffleKeyDepth + frontTrim),
            baffleKeyPosZ
        ])
            minkowski() {
                cube([
                    keyPocketLen - 2,
                    baffleKeyDepth,     // <-- depth ONLY
                    keyPocketWid - 2
                ], center = false);     // <-- CRITICAL
                cylinder(r = 1, h = 0.01, center = true);
            }
    }
    
    // --------------------------------------------------
    // BACK PANEL SCREW HOLES
    // --------------------------------------------------
    module box_back_screw_holes() {

    // Corner screws
    if (backScrewCountCorners) {
        for (sx = [-backScrewPosX, backScrewPosX])
        for (sz = [-backScrewPosZ, backScrewPosZ]) {
            translate([sx, yPilotCenter, sz])
                rotate([90,0,0])
                    cylinder(
                        r = backScrewPilotDia/2,
                        h = backScrewPilotDepth+.01,
                        center = true
                    );
        }
    }

    // Mid-edge screws
    if (backScrewCountMids) {

        // Vertical mids
        for (sz = [-backScrewPosZ, backScrewPosZ]) {
            translate([0, yPilotCenter, sz])
                rotate([90,0,0])
                    cylinder(
                        r = backScrewPilotDia/2,
                        h = backScrewPilotDepth+.01,
                        center = true
                    );
        }

        // Horizontal mids
        for (sx = [-backScrewPosX, backScrewPosX]) {
            translate([sx, yPilotCenter, 0])
                rotate([90,0,0])
                    cylinder(
                        r = backScrewPilotDia/2,
                        h = backScrewPilotDepth+.01,
                        center = true
                    );
        }
    }
}

    
// --------------------------------------------------
// BACK PANEL INSET POCKET (box-owned subtraction)
// --------------------------------------------------

// How much curved rim to preserve around the pocket opening (in X/Z)
backPanelRimFromCurve = edge_round_radius + backPanelInsetFromCurve;

// Base pocket size (matches panel + reveal) BEFORE rim-preservation shrink
backPanelPocketW_raw =
    boxIntWidth
    + 2 * (boxThickness/2 + backPanelEdgeMargin)
    + 2 * backPanelFitClearance;

backPanelPocketH_raw =
    boxIntHeight
    + 2 * (boxThickness/2 + backPanelEdgeMargin)
    + 2 * backPanelFitClearance;

// Final pocket opening size (shrunk once so it doesn't run into rounded corners)
pocketW = max(1, backPanelPocketW_raw - 2*backPanelRimFromCurve);
pocketH = max(1, backPanelPocketH_raw - 2*backPanelRimFromCurve);

// Back panel screw positions (derived from pocket)
backScrewPosX = pocketW/2 - backPanelScrewEdgeInset;
backScrewPosZ = pocketH/2 - backPanelScrewEdgeInset;


// Pocket cut: MUST start at the outside back face, then cut inward
module box_back_inset_pocket() {
    translate([
        -pocketW/2,
        yBackOuter - pocketOvershoot,
        -pocketH/2
    ])
        cube([
            pocketW,
            backPanelInsetDepth + pocketOvershoot,
            pocketH
        ], center = false);
}



    // --------------------------------------------------
    // BOX SOLID
    // --------------------------------------------------
    difference() {
        box_outer();
        box_interior();
        box_back_inset_pocket();
        box_back_opening();
        box_driver_cutouts();
        box_baffle_locators();     // ← moved here
        box_back_screw_holes();    // ← moved here
        box_front_trim();
    }
}
