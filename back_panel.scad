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

module panel_back_face_cutouts_local() {
    // Stub: Add terminal and port cutouts here when ready
    // For now, this is empty to prevent "unknown module" warning
    // Example: if you add terminals later:
    // translate([terminalOffsetX, 0, terminalOffsetZ])
    //     cylinder(d=wireDiameter, h=backPanelThickness+2, center=true);
}