// speakerGUMBO_main.scad
// Top-level assembly and orchestration for G.U.M.B.O.
// GUMBO - Great Utility for Music Box Optimization
//
// Speaker GUMBO v0.1.0 - 2026-01-26
// Added slot port support and bracing patterns
version = "0.1.0";

export_mode = 0;           // 0=Full, 1=Box, 2=Back panel, 3=Baffle, 4=Slot Key, 5=Driver Fit Test
explodeMode = true;
explodeDistance = 40;      // mm — consider making dynamic: max(outerH, outerD, outerW) * 0.4 later

include <parameters.scad>
include <utils.scad>
include <view_logic.scad>
include <box.scad>
include <drivers.scad>
include <baffle.scad>
include <grill.scad>
include <slot_key.scad>
include <back_panel.scad>
include <driver_fit_test.scad>

// ────────────────────────────────────────────────
// VOLUME & DIMENSION CALCULATIONS
// ────────────────────────────────────────────────
Vb_sealed = (Qtc > Qts) ? Vas / ((Qtc / Qts)^2 - 1) : undef;
Vb_ported = Vas * ventedVasFactor;
Vb = sealed ? (is_undef(Vb_sealed) ? Vb_ported : Vb_sealed) : Vb_ported;

// Safety: prevent pow() from getting invalid input
Vb_safe = (is_undef(Vb) || Vb <= 0) ? 5 : Vb;   // fallback to 5L if broken

baseLen_raw = pow(Vb_safe * 1000000, 1/3);
baseLen = is_undef(baseLen_raw) || baseLen_raw <= 0 ? 100 : baseLen_raw;  // fallback

ratio_raw = boxHeightRatio * boxWidthRatio * boxDepthRatio;
ratioNorm = (is_undef(ratio_raw) || ratio_raw <= 0) ? 1 : pow(ratio_raw, 1/3);


// TEMP FORCE RATIOS IF UNDEF (fallback values from parameters.scad)
boxHeightRatio_safe = is_undef(boxHeightRatio) ? 1.15 : boxHeightRatio;
boxWidthRatio_safe  = is_undef(boxWidthRatio)  ? 0.9  : boxWidthRatio;
boxDepthRatio_safe  = is_undef(boxDepthRatio)  ? 1.0  : boxDepthRatio;

// Perform the calculation using safe ratios
boxIntHeight_calc = baseLen * boxHeightRatio_safe / ratioNorm;
boxIntWidth_calc  = baseLen * boxWidthRatio_safe  / ratioNorm;
boxIntDepth_calc  = baseLen * boxDepthRatio_safe  / ratioNorm;

// Apply final safety clamps (prevent negative/zero/undef sizes)
boxIntHeight = is_undef(boxIntHeight_calc) ? 120 : max(50, boxIntHeight_calc);
boxIntWidth  = is_undef(boxIntWidth_calc)  ? 100 : max(50, boxIntWidth_calc);
boxIntDepth  = is_undef(boxIntDepth_calc)  ? 110 : max(50, boxIntDepth_calc);

// Now compute outer dimensions
//outerW = boxIntWidth  + 2 * boxThickness;
//outerD = boxIntDepth  + 2 * boxThickness;
//outerH = boxIntHeight + 2 * boxThickness;

// Lock in outer dimensions with fallback
outerW = is_undef(boxIntWidth) ? 130 : max(100, boxIntWidth  + 2 * boxThickness);
outerD = is_undef(boxIntDepth) ? 140 : max(100, boxIntDepth + 2 * boxThickness);
outerH = is_undef(boxIntHeight) ? 160 : max(100, boxIntHeight + 2 * boxThickness);

/*
// Confirm final values
echo("FINAL OUTER DIMS (after all clamps):");
echo("outerW =", outerW);
echo("outerD =", outerD);
echo("outerH =", outerH);
/*

/*
// Debug prints — keep these
echo("DEBUG VOLUME CALC:");
echo("Vb =", Vb, "Vb_safe =", Vb_safe);
echo("baseLen_raw =", baseLen_raw, "→ baseLen =", baseLen);
echo("ratio_raw =", ratio_raw, "→ ratioNorm =", ratioNorm);
echo("boxIntHeight_calc (before clamp) =", boxIntHeight_calc);
echo("boxIntWidth_calc  (before clamp) =", boxIntWidth_calc);
echo("boxIntDepth_calc  (before clamp) =", boxIntDepth_calc);
echo("boxInt (H W D) after clamp =", boxIntHeight, boxIntWidth, boxIntDepth);
echo("outer (W D H) =", outerW, outerD, outerH);
*/

// ────────────────────────────────────────────────
// BACK PANEL DERIVED VALUES
// ────────────────────────────────────────────────
backOpenWidth  = boxIntWidth;
backOpenHeight = boxIntHeight;

backPanelRimFromCurve = edge_round_radius + backPanelInsetFromCurve;

backPanelPocketW_raw = boxIntWidth + boxThickness + 2 * backPanelEdgeMargin + 2 * backPanelFitClearance;
backPanelPocketH_raw = boxIntHeight + boxThickness + 2 * backPanelEdgeMargin + 2 * backPanelFitClearance;

pocketW = max(1, backPanelPocketW_raw - 2 * backPanelRimFromCurve);
pocketH = max(1, backPanelPocketH_raw - 2 * backPanelRimFromCurve);

backScrewPosX = pocketW / 2 - backPanelScrewEdgeInset;
backScrewPosZ = pocketH / 2 - backPanelScrewEdgeInset;

panelOuterW = pocketW - 2 * backPanelTolerance;
panelOuterH = pocketH - 2 * backPanelTolerance;

tongueWidth  = backOpenWidth  - 2 * backPanelTolerance;
tongueHeight = backOpenHeight - 2 * backPanelTolerance;

// ────────────────────────────────────────────────
// BOX INTERFACE ARRAY (for back_panel module)
// ────────────────────────────────────────────────
box_if = [
    0, 0, 0,                    // dummies 0-2
    boxThickness,               // 3
    boxIntWidth,                // 4
    boxIntHeight,               // 5
    boxIntDepth,                // 6
    0, 0, 0, 0,                 // dummies 7-10
    pocketW,                    // 11
    pocketH,                    // 12
    backScrewPosX,              // 13
    backScrewPosZ               // 14
];

// ────────────────────────────────────────────────
// DRIVER POSITIONING
// ────────────────────────────────────────────────
margin = getMargin(driverParams);
enabledDriverIdx = concat(
    [for (i = [0:len(driverParams)-1]) if (driverParams[i][3] && i == 0) i],
    [for (i = [0:len(driverParams)-1]) if (driverParams[i][3] && i == 1) i],
    [for (i = [0:len(driverParams)-1]) if (driverParams[i][3] && i == 2) i]
);

enabledFaceRadii = [for (k = [0:len(enabledDriverIdx)-1])
    let(j = enabledDriverIdx[k]) speakerFaceDiameters[j]/2
];

zPositions = compute_z_positions_ordered(enabledFaceRadii, boxIntHeight);

// ────────────────────────────────────────────────
// BAFFLE DERIVED VALUES
// ────────────────────────────────────────────────
coreW_raw = outerW - 2*baffleFrameInset;
coreH_raw = outerH - 2*baffleFrameInset;
coreW = coreW_raw > 10 ? coreW_raw : outerW * 0.7;
coreH = coreH_raw > 10 ? coreH_raw : outerH * 0.7;

ringW = outerW/2 - coreW/2;
ringH = outerH/2 - coreH/2;
pocketMargin = min(baffleLocMargin, min(ringW - 1, ringH - 1));

baffleSlotPosX = -outerW/2 + pocketMargin;
baffleSlotPosZ =  outerH/2 - pocketMargin;
baffleKeyPosX  =  outerW/2 - pocketMargin;
baffleKeyPosZ  = -outerH/2 + pocketMargin;

edgeR = (baffleEdgeStyle == 2) ? clampF(baffleEdgeSize, 0, 8) : 0;
THK = (edgeR > baffleThickness/2) ? (2*edgeR + 1) : baffleThickness;

// ────────────────────────────────────────────────
// MAIN ASSEMBLY (export_mode == 0)
// ────────────────────────────────────────────────
if (export_mode == 0) {
    // Box
    speaker_box();

    // Back panel (exploded backward)
    if (makeBackPanel) {
        y_explode = explodeMode ? -explodeDistance : 0;
        back_panel(box_if, y_explode);
    }

    // Baffle (exploded forward)
    baffleY = 
        outerD/2 
        - frontTrim 
        + baffleThickness/2 
        + (explodeMode ? explodeDistance : 0);

    baffleFrontMaxY = baffleY + baffleThickness/2 + baffleEdgeSize;

    translate([0, baffleY, 0])
        baffle_full(coreW, coreH, THK, outerW, outerH,
                    baffleSlotPosX, baffleSlotPosZ,
                    baffleKeyPosX,  baffleKeyPosZ);

    // Slot + Key (mid-explosion for clarity)
    if (show_slot_key) {
        mid_explode_y = outerD/2 + (explodeMode ? explodeDistance / 2 : 0);
        translate([0, mid_explode_y, 0]) {
            translate([baffleSlotPosX, 0, baffleSlotPosZ])
                rotate([90,0,0]) slot();
            translate([baffleKeyPosX, 0, baffleSlotPosZ])
                rotate([0,0,0]) key();
        }
    }

    
    // Grill — attached in normal view, jumps forward in exploded view
    if (grill_enable) {
        // Position of baffle's front face (exploded or not)
        baffle_front_y =
            outerD / 2
            - (is_undef(frontTrim) ? 0 : frontTrim)
            + baffleThickness
            + (explodeMode ? explodeDistance : 0)
            + (baffleEdgeStyle == 2 ? baffleEdgeSize : 0);

        // Grill back face = baffle front + extra explode separation
        grill_y = baffle_front_y
                  + (explodeMode ? explodeDistance * 1.0 : 0);

        echo("Grill placement:",
             " baffle front Y =", baffle_front_y,
             " extra explode separation =", explodeMode ? explodeDistance : 0,
             " final grill back Y =", grill_y,
             " gap from baffle front =", grill_y - baffle_front_y, " mm");

        // Group the grill + caps under one color/transform scope
        color("Silver") {
            translate([0, grill_y, 0]) {
                grill_panel_flat(
                    outerW,
                    outerH,
                    coreW,
                    coreH,
                    baffleCornerR
                );

                // Add installed caps (only in full assembly / preview)
                if (export_mode == 0) {
                    color("DimGray") {  // slightly darker for contrast
                        grill_installed_caps(outerW, outerH);
                    }
                }
            }
        }
    }
}
    
    
// ────────────────────────────────────────────────
// EXPORT MODES (single parts)
// ────────────────────────────────────────────────
else if (export_mode == 1) {
    speaker_box();
}
else if (export_mode == 2) {
    if (makeBackPanel)
        back_panel(box_if);
}
else if (export_mode == 3) {
    baffle_full(coreW, coreH, THK, outerW, outerH,
                baffleSlotPosX, baffleSlotPosZ,
                baffleKeyPosX,  baffleKeyPosZ);
}
else if (export_mode == 4) {
    // Slot + Key + magnet plugs — laid out for print bed
    translate([0, -10, 0]) slot();
    translate([0,  10, 0]) key();
    translate([-40, 20, 0])
        grill_magnet_plugs_array(
            grill_compute_plug_depth(baffleThickness)
        );
}
else if (export_mode == 5) {
    echo("EXPORT MODE 5: Driver fit-test puck for index ", fitTestDriverIndex);
    driver_fit_test_puck(fitTestDriverIndex);
}

// ────────────────────────────────────────────────
// FINAL SPECS SUMMARY (shown in full assembly or when showSpecs=true)
// ────────────────────────────────────────────────
if (showSpecs || export_mode == 0) {
    echo("--------------------------------------------------");
    echo(str("Enclosure Mode: ", sealed ? "Sealed" : "Ported"));
    
    echo(str("Vb sealed (L):   ", is_undef(Vb_sealed) ? "N/A" : str(floor(Vb_sealed * 100) / 100)));
    echo(str("Vb ported (L):   ", floor(Vb_ported * 100) / 100));
    echo(str("Using Vb (L):     ", floor(Vb * 100) / 100));
    
    echo(str("Internal dims (H × W × D mm): ", round(boxIntHeight), " × ", round(boxIntWidth), " × ", round(boxIntDepth)));
    echo(str("External dims (H × W × D mm): ", round(outerH), " × ", round(outerW), " × ", round(outerD)));
    
    volL   = boxIntWidth * boxIntDepth * boxIntHeight / 1000000;
    volFt3 = volL / 28.3168;
    echo(str("Internal volume: ", floor(volL * 100) / 100, " L  (", floor(volFt3 * 1000) / 1000, " ft³)"));
    
    echo(str("Enabled drivers (count / indices): ", len(enabledDriverIdx), " → ", enabledDriverIdx));
    echo(str("Driver Z positions (mm): ", zPositions));
    
    // Optional extras you can uncomment when needed
    // echo(str("Baffle thickness (mm): ", baffleThickness));
    // echo(str("Pocket opening (W × H mm): ", round(pocketW), " × ", round(pocketH)));
    // if (grill_enable) echo("Grill: Enabled");
    
    echo("--------------------------------------------------");
}
