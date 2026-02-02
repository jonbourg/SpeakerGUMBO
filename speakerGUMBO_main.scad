// speakerGUMBO_main.scad
// Top-level assembly and orchestration for G.U.M.B.O.
// GUMBO - Great Utility for Music Box Optimization
//
// Speaker GUMBO v0.1.1 - 2026-01-26
// Added slot port support and bracing patterns
version = "0.1.4";
echo("Speaker GUMBO version 0.1.4");

// 0=Full, 1=Box, 2=Back panel, 3=Baffle, 4=Grill, 5=Small Parts, 6=Driver Fit Test
export_mode = 0;           
explodeMode = true;
explodeDistance = 30;      // mm — consider making dynamic: max(outerH, outerD, outerW) * 0.4 later

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

// Lock in outer dimensions with fallback
outerW = is_undef(boxIntWidth) ? 130 : max(100, boxIntWidth  + 2 * boxThickness);
outerD = is_undef(boxIntDepth) ? 140 : max(100, boxIntDepth + 2 * boxThickness);
outerH = is_undef(boxIntHeight) ? 160 : max(100, boxIntHeight + 2 * boxThickness);


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
// SMALL PARTS EXPORT
// ────────────────────────────────────────────────
module export_small_parts() {

    spacing = 15;   // layout spacing
    
    // SLOT / KEY
    translate([-10, 1 * spacing, 0])
        slot();          // or whatever your key module is
    
    translate([10, 1 * spacing, 0])
        key();     // if separate
    
    // GRILL MAGNET CAPS
    translate([-40, 2 * spacing, 0])
        grill_mag_caps_array(6);
    
    // BAFFLE MAGNET PLUGS
    translate([-30, 3 * spacing, 0])
        grill_magnet_plugs_array(
            grill_compute_plug_depth(baffleThickness),
            6
        );
}


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
            // Upper right: slot
            translate([baffleSlotPosX, 0, baffleSlotPosZ])
                rotate([90,0,0]) slot();
            // Lower left: key
            translate([baffleKeyPosX, 0, baffleKeyPosZ])
                rotate([0,0,0]) key();
        }
    }

    
    // Grill — anchored to the baffle front face, with independent explode offsets
    if (grill_enable) {

        // This is the exact world-space Y of the baffle's front-most face
        baffle_front_y = baffleFrontMaxY;

        // Explode offsets (world-space)
        grill_explode_y = explodeMode ? explodeDistance : 0;

        // Caps trail the grill by 5mm when exploded
        caps_explode_y  = explodeMode ? max(explodeDistance - 5, 0) : 0;

        // Assembled positions (explode=0)
        // Caps sit directly on the baffle face
        caps_y  = baffle_front_y + grill_cap_total_h + caps_explode_y;

        // Grill sits in front of the caps in the assembled view
        // (If grill_cap_total_h is truly the cap thickness, this is correct)
        grill_y = baffle_front_y + grill_cap_total_h + grill_explode_y;

        echo("GRILL ANCHOR baffle_front_y=", baffle_front_y,
             "caps_y=", caps_y, "grill_y=", grill_y,
             "delta(grill-caps)=", grill_y - caps_y);

        // Caps (closest to baffle)
        color("DimGray")
            translate([0, caps_y, 0])
                grill_installed_caps(outerW, outerH);

        // Grill panel (in front of caps)
        color("Silver")
            translate([0, grill_y, 0])
                grill_panel_flat(outerW, outerH, coreW, coreH, baffleCornerR);
    }
}
    
    
// ────────────────────────────────────────────────
// EXPORT MODES (single parts)
// ────────────────────────────────────────────────
else if (export_mode == 1) {
    // BOX ONLY
    speaker_box();
}

else if (export_mode == 2) {
    // BACK PANEL ONLY
    if (makeBackPanel)
        back_panel(box_if);
}

else if (export_mode == 3) {
    // BAFFLE ONLY
    baffle_full(coreW, coreH, THK, outerW, outerH,
                baffleSlotPosX, baffleSlotPosZ,
                baffleKeyPosX,  baffleKeyPosZ);
}

else if (export_mode == 4) {
    grill_panel_flat(outerW, outerH, coreW, coreH, baffleCornerR);
    // Uncomment for visualization only:
    // grill_installed_caps(outerW, outerH);
}


else if (export_mode == 5) {
    // SMALL PARTS ONLY
    export_small_parts();
}

else if (export_mode == 6) {
    // FIT TEST
    echo("EXPORT MODE 6: Driver fit-test puck for index ", fitTestDriverIndex);
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
    
// ============================================================
// DRIVER DIMENSION SPECS (Baffle Interface Only)
// ============================================================

for (j = [0 : len(driverParams) - 1]) {

    shape = driverFaceShape[j];

    // Common driver parameters
    cutout_d  = driverParams[j][0];   // cutout diameter
    screw_pcd = driverParams[j][1];   // screw spacing / PCD

    echo("--------------------------------------------------");
    echo(str("Driver ", j, " dimensions:"));

    // Face shape (specs only – omit from fit test puck)
    if (shape == 0)        echo("  Face shape: Round");
    else if (shape == 1)   echo("  Face shape: Rectangular");
    else if (shape == 2)   echo("  Face shape: Rounded rectangle");
    else if (shape == 3)   echo("  Face shape: Rectangular (oval)");
    else if (shape == 4)   echo("  Face shape: Clipped circle (4 flats)");
    else if (shape == 5)   echo("  Face shape: Top / Bottom truncated circle");
    else if (shape == 6)   echo("  Face shape: Squircle");
    else if (shape == 7)   echo("  Face shape: Superellipse");

    // Fastener geometry (public spec)
    echo(str("  Screw PCD Ø (mm): ", round(screw_pcd)));

    // --------------------------------------------------------
    // ROUND
    // --------------------------------------------------------
    if (shape == 0) {
        d = speakerFaceDiameters[j];

        echo(str("  Cutout Ø (mm): ", round(d)));
        echo(str("  Bounding box (mm): ", round(d), " x ", round(d)));
    }

    // --------------------------------------------------------
    // RECTANGULAR / OVAL
    // --------------------------------------------------------
    else if (shape == 1 || shape == 3) {
        w = driverRectSizes[j][0];
        h = driverRectSizes[j][1];

        echo(str("  Cutout Ø (equiv mm): ", round(diag(w, h))));
        echo(str("  Bounding box (mm): ", round(w), " x ", round(h)));
    }

    // --------------------------------------------------------
    // ROUNDED RECTANGLE
    // --------------------------------------------------------
    else if (shape == 2) {
        w = driverRectSizes[j][0];
        h = driverRectSizes[j][1];
        r = driverCornerRadius[j];

        echo(str("  Cutout Ø (equiv mm): ", round(diag(w, h))));
        echo(str("  Bounding box (mm): ", round(w), " x ", round(h)));
        echo(str("  Corner Ø (mm): ", round(2 * r)));
    }

    // --------------------------------------------------------
    // CLIPPED CIRCLE (4 FLATS)
    // --------------------------------------------------------
    else if (shape == 4) {
        d = speakerFaceDiameters[j];

        userClip = driverClipDepth[j];
        autoClip = 0.08 * d;
        clip     = (userClip > 0) ? userClip : autoClip;

        flat_len     = clipped_flat_chord_length(d, clip);
        flat_to_flat = d - 2 * clip;

        echo(str("  Cutout Ø (nominal mm): ", round(d)));
        echo(str("  Clip depth per side (mm): ", driverClipDepth));
        echo(str("  Bounding box (mm): ", round(flat_to_flat), " x ", round(flat_to_flat)));
        echo(str("  Flat length (mm): ", round(flat_len)));
    }

    // --------------------------------------------------------
    // TOP / BOTTOM CLIPPED CIRCLE
    // --------------------------------------------------------
    else if (shape == 5) {
        d = speakerFaceDiameters[j];

        userClip = driverClipDepth[j];
        autoClip = 0.08 * d;
        clip     = (userClip > 0) ? userClip : autoClip;

        flat_to_flat = d - 2 * clip;

        echo(str("  Cutout Ø (nominal mm): ", round(d)));
        echo(str("  Clip depth per side (mm): ", driverClipDepth));
        echo(str("  Bounding box (mm): ", round(d), " x ", round(flat_to_flat)));
    }

    // --------------------------------------------------------
    // SQUIRCLE / SUPERELLIPSE
    // --------------------------------------------------------
    else if (shape == 6 || shape == 7) {
        d = speakerFaceDiameters[j];

        echo(str("  Cutout Ø (nominal mm): ", round(d)));
        echo(str("  Bounding box (mm): ", round(d), " x ", round(d)));
        echo(str("  Corner Ø (equiv mm): ", round(diag(d, d))));
    }
}
    echo("--------------------------------------------------");
}
