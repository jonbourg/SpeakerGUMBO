// back_panel.scad
// Removable rear panel with tongue, gasket groove, countersunk screws,
// terminals, and optional printed internal port tubes (single or multi)

include <parameters.scad>
include <utils.scad>

module back_panel(box_if, explode_y = 0) {
    valid = is_list(box_if) && len(box_if) >= 15;
    
    if (!valid) {
        echo("ERROR: back_panel called with invalid box_if array!");
    }
    
    // Extract values
    boxThickness     = box_if[3];
    boxIntWidth      = box_if[4];
    boxIntHeight     = box_if[5];
    boxIntDepth      = box_if[6];
    pocketW          = box_if[11];
    pocketH          = box_if[12];
    backScrewPosX    = box_if[13];
    backScrewPosZ    = box_if[14];
    
    echo("BACK PANEL IF:", "pocketW=", pocketW, "pocketH=", pocketH, "screwX=", backScrewPosX, "screwZ=", backScrewPosZ);
    
    // Trust passed pocket values
    pocketW_use = pocketW;
    pocketH_use = pocketH;
    echo("USING PASSED POCKET VALUES:", "pocketW_use=", pocketW_use, "pocketH_use=", pocketH_use);
    
    // Panel + tongue sizes
    panelOuterW = pocketW_use - 2 * backPanelTolerance;
    panelOuterH = pocketH_use - 2 * backPanelTolerance;
    tongueWidth = boxIntWidth - 2 * backPanelTolerance;
    tongueHeight = boxIntHeight - 2 * backPanelTolerance;
    
    // ────────────────────────────────────────────────────────────────
    // SIMPLE & ACCURATE FLUSH POSITIONING
    // Pocket floor = outer back + inset depth (3mm)
    // Panel outer face sits at pocket floor when flush
    // ────────────────────────────────────────────────────────────────
    outer_back_y = - (boxIntDepth + 2*boxThickness)/2;           // ≈ -outerD/2
    pocket_floor_y = outer_back_y;                               // no extra inset in Y
    flush_y_center = pocket_floor_y + backPanelThickness/2;      // panel center

    // Local offsets relative to flush center
    yPanelCenter_local = flush_y_center;
    tongueOffsetY_local = flush_y_center + (backPanelTongueDepth/2 + backPanelThickness/2);

    // Debug echoes to confirm
    echo("OUTER BACK Y:", outer_back_y);
    echo("POCKET FLOOR Y (after 3mm inset):", pocket_floor_y);
    echo("FLUSH PANEL CENTER Y:", flush_y_center);
    
    // ────────────────────────────────────────────────────────────────
    // BUILD PANEL AT FLUSH POSITION, THEN APPLY EXPLODE
    // ────────────────────────────────────────────────────────────────
    translate([0, explode_y, 0]) {   // explode adds separation on top
        difference() {
            union() {
                // Panel face
                translate([0, yPanelCenter_local, 0])
                    cube([panelOuterW, backPanelThickness, panelOuterH], center=true);
                
                // Tongue (extends forward into box)
                translate([0, tongueOffsetY_local, 0])
                    cube([tongueWidth, backPanelTongueDepth, tongueHeight], center=true);
                
                // Ports if enabled (position relative to flush_y)
                if (makePort && !multiPortEnabled && printedPortEnabled) {
                    translate([
                        portOffsetX,
                        yPanelCenter_local - backPanelThickness/2,
                        portOffsetZ
                    ])
                        rotate([-90,0,0])
                            printed_port_tube(portInternalDiameter, printedPortLength, printedPortWall);
                }
                
                // Multi-ports...
                if (multiPortEnabled && printedPortEnabled && multiPortCount_clamped > 0) {
                    for (i = [0:multiPortCount_clamped-1]) {
                        localX = multiPortOffsetX + (i - (multiPortCount_clamped - 1)/2) * multiPortSpacing;
                        localZ = multiPortOffsetZ;
                        translate([localX, yPanelCenter_local - backPanelThickness/2, localZ])
                            rotate([-90,0,0])
                                printed_port_tube(multiPortDiameter, multiPortLength, printedPortWall);
                    }
                }
            }
            
            // Screw holes and other subtractions (relative to flush)
            if (backScrewCountCorners) {
                for (sx = [-backScrewPosX, backScrewPosX])
                for (sz = [-backScrewPosZ, backScrewPosZ]) {
                    translate([sx, yPanelCenter_local, sz])
                        rotate([90,0,0])
                            cylinder(r = backScrewClearDia/2, h = backPanelThickness + backPanelTongueDepth + 4-1, center = true);
                }
            }
            // Mid-edge screws
            if (backScrewCountMids) {
                // Vertical mids (top/bottom centers)
                for (sz = [-backScrewPosZ, backScrewPosZ]) {
                    translate([0, yPanelCenter_local, sz])  // ← _local
                        rotate([90,0,0])
                            cylinder(
                                r = backScrewClearDia/2,
                                h = backPanelThickness + backPanelTongueDepth + 4,
                                center = true
                            );
                }
                
                // Horizontal mids (left/right centers)
                for (sx = [-backScrewPosX, backScrewPosX]) {
                    translate([sx, yPanelCenter_local, 0])  // ← _local
                        rotate([90,0,0])
                            cylinder(
                                r = backScrewClearDia/2,
                                h = backPanelThickness + backPanelTongueDepth + 4,
                                center = true
                            );
                }
            }
            
            // Terminal cutouts
            translate([0, yPanelCenter_local, 0])
                panel_back_face_cutouts_local();
        }
    }
}

// ======================================================================
// HELPERS FOR TERMINAL SCREWS
// ======================================================================

backPanelTotalThickness = backPanelThickness + backPanelTongueDepth;

module terminal_screw_hole_local(x, y, z) {

    totalThk   = backPanelThickness + backPanelTongueDepth;
    screwDepth = totalThk * terminalScrewDepthFrac;

    // OUTER face is +backPanelThickness/2 in this model
    translate([x,
               y + backPanelThickness/2 - screwDepth/2,
               z])
        rotate([90,0,0])
            cylinder(
                r = terminalScrewHoleDia/2,
                h = screwDepth,
                center = true
            );
}

module terminal_cutout_rect_local(x, y, z, w, h) {
    translate([x, y, z])
        rotate([90,0,0])
            cube(
                [w,
                 backPanelThickness + backPanelTongueDepth + 4,
                 h],
                center = true
            );
}

// Two screws above/below a feature (same X, different Z)
module terminal_screws_tb_local(x, y, z, spacing_z) {
    terminal_screw_hole_local(x, y, z - spacing_z/2);
    terminal_screw_hole_local(x, y, z + spacing_z/2);
}

// Two screws left/right a feature (same Z, different X)
module terminal_screws_lr_local(x, y, z, spacing_x) {
    terminal_screw_hole_local(x - spacing_x/2, y, z);
    terminal_screw_hole_local(x + spacing_x/2, y, z);
}

// Screws on a bolt circle (2 or 4). Rotation in degrees.
module terminal_screws_bolt_circle_local(x, y, z, bolt_circle_d, count, rot_deg = 0) {
    r = bolt_circle_d/2;
    for (i = [0:count-1]) {
        ang = rot_deg + i * (360 / count);
        terminal_screw_hole_local(
            x + r * cos(ang),
            y,
            z + r * sin(ang)
        );
    }
}


// ======================================================================
// PANEL BACK-FACE CUTOUTS (PORT + TERMINALS) – LOCAL TO PANEL CENTER
// ======================================================================
module panel_back_face_cutouts_local() {
    // PORTS

    // Legacy single-port mode
    if (makePort && !multiPortEnabled) {
        // Main port hole through panel + tongue
        translate([portOffsetX, 0, portOffsetZ])
            rotate([90,0,0])
                cylinder(
                    r      = portInternalDiameter/2,
                    h      = 2*(printedPortLength + backPanelThickness + backPanelTongueDepth + 4),
                    center = true
                );

        if (portFlareOuterEnabled) {
            // Outer flare as a recess on the external face
            // We keep Y=0 here; correct thickness is handled by port_flare_outer_cone
            translate([portOffsetX, 0, portOffsetZ])
                rotate([90,0,0])
                    port_flare_outer_cone(
                        portInternalDiameter,
                        portFlareOuterDiameter,
                        portFlareOuterDepth,
                        backPanelThickness
                    );
        }
    }

    // Multi-port mode: up to 3 round ports on the back panel
    if (multiPortEnabled && multiPortCount_clamped > 0) {
        for (i = [0:multiPortCount_clamped-1]) {

            // Centered horizontally around multiPortOffsetX
            localX = multiPortOffsetX
                   + (i - (multiPortCount_clamped - 1)/2) * multiPortSpacing;

            localZ = multiPortOffsetZ;

            // Through-hole for each port
            translate([localX, 0, localZ])
                rotate([90,0,0])
                    cylinder(
                        r      = multiPortDiameter/2,
                        h      = 2*(multiPortLength + backPanelThickness + backPanelTongueDepth + 4),
                        center = true
                    );

            if (portFlareOuterEnabled) {
                translate([localX, 0, localZ])
                    rotate([90,0,0])
                        port_flare_outer_cone(
                            multiPortDiameter,
                            portFlareOuterDiameter,   // reuse same flare diameter
                            portFlareOuterDepth,
                            backPanelThickness
                        );
            }
        }
    }

// TERMINALS (on removable panel)
// Terminal cutouts must be pushed outward to clear Minkowski-rounded panel surface.
// Positive offset works for this model orientation.
    terminalYOffset = edge_round_radius;
    
    if (terminalType == 1) {   // single wire
        translate([terminalOffsetX, terminalYOffset, terminalOffsetZ])
            rotate([90,0,0])
                cylinder(r = wireDiameter/2,
                         h = backPanelThickness + backPanelTongueDepth + 4,
                         center = true);
    }
    else if (terminalType == 2) {  // dual wire
        for (sx = [-dualWireSpacing/2, dualWireSpacing/2]) {
            translate([terminalOffsetX + sx, terminalYOffset, terminalOffsetZ])
                rotate([90,0,0])
                    cylinder(r = wireDiameter/2,
                             h = backPanelThickness + backPanelTongueDepth + 4,
                             center = true);
        }
    }
    else if (terminalType == 3) {  // round cup

        // Main round cutout
        translate([terminalOffsetX, terminalYOffset, terminalOffsetZ])
            rotate([90,0,0])
                cylinder(
                    r = terminalRoundDiameter/2,
                    h = backPanelThickness + backPanelTongueDepth + 4,
                    center = true
                );

        // Two mounting screws above/below the circle
        // Use diameter + inset to keep screws outside the hole
        roundScrewSpacingZ = terminalRoundDiameter + 2*terminalScrewInset;

        terminal_screws_tb_local(
            terminalOffsetX,
            terminalYOffset,
            terminalOffsetZ,
            roundScrewSpacingZ
        );
    }

    
    else if (terminalType == 4) {

        // Main cutout
        terminal_cutout_rect_local(
            terminalOffsetX,
            terminalYOffset,
            terminalOffsetZ,
            terminalWidth,
            terminalHeight
        );

        screwX = terminalWidth/2 + terminalScrewInset;

        terminal_screw_hole_local(
            terminalOffsetX - screwX,
            terminalYOffset,
            terminalOffsetZ
        );

        terminal_screw_hole_local(
            terminalOffsetX + screwX,
            terminalYOffset,
            terminalOffsetZ
        );
    }

    else if (terminalType == 5) {  // legacy terminal pair cutout
        translate([terminalOffsetX, terminalYOffset, terminalOffsetZ])
            rotate([90,0,0])
                square_cutout(terminalPairWidth,
                              backPanelThickness + backPanelTongueDepth + 4);
    }
    else if (terminalType == 6) {  // NL2 Speakon

        // Main connector hole
        translate([terminalOffsetX, terminalYOffset, terminalOffsetZ])
            rotate([90,0,0])
                cylinder(
                    r = nl2HoleDiameter/2,
                    h = backPanelThickness + backPanelTongueDepth + 4,
                    center = true
                );

        // Mounting screws (choose 2 or 4 depending on your hardware)
        // These params should live in parameters.scad ideally
        nl2BoltCircleDia   = nl2HoleDiameter + 2*terminalScrewInset + terminalScrewHoleDia; 
        
        terminal_screws_bolt_circle_local(
            terminalOffsetX,
            terminalYOffset,
            terminalOffsetZ,
            nl2BoltCircleDia,
            nl2ScrewCount,
            nl2RotationDeg
        );
    }

    else if (terminalType == 7) {  // binding posts
        for (sx = [-bindingPostSpacingX/2, bindingPostSpacingX/2]) {
            translate([terminalOffsetX + sx, terminalYOffset, terminalOffsetZ])
                rotate([90,0,0])
                    cylinder(r = bindingPostHoleDiameter/2,
                             h = backPanelThickness + backPanelTongueDepth + 4,
                             center = true);
        }
    }
    else if (terminalType == 8) {  // spring clip

        // Main opening
        terminal_cutout_rect_local(
            terminalOffsetX,
            terminalYOffset,
            terminalOffsetZ,
            springClipWidth,
            springClipHeight
        );

        // Two mounting screws above/below the opening
        // Choose a spacing that sits outside the cutout
        springScrewSpacingZ = springClipHeight + 2*terminalScrewInset;

        terminal_screws_tb_local(
            terminalOffsetX,
            terminalYOffset,
            terminalOffsetZ,
            springScrewSpacingZ
        );
    }
}
