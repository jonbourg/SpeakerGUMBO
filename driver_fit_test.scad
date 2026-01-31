// fit_test_puck.scad
// Dedicated module for GUMBO driver fit-test pucks

include <parameters.scad>
include <utils.scad>
include <drivers.scad>

// Puck-specific tunables
fit_text_size = 7.0;
fit_text_depth = 0.6;
fit_max_name_chars = 18;
fit_inner_text_scale = 0.85;
fit_min_text_radius = 4;
fit_puck_margin_base = 8;
fit_puck_extra_per_row = 12;
fit_char_width_factor = 1.5;
fit_outer_text_margin = 3;   // mm beyond outer text
fit_two_row_extra     = 3;   // mm extra if inner row exists

// engraved_label_curved module (unchanged)
module engraved_label_curved(label, radius, depth, size, font="DejaVu Sans Bold:style=Bold", reverse = false) {
    len_label = len(label);
    
    // Direction: positive for outer (clockwise), negative for inner (counter-clockwise)
    dir_multiplier = reverse ? 1 : 1;
    
    // Tighter spacing
    char_angle = dir_multiplier * (360 / (len_label * 1.0));
    
    // Start offset - adjust for reverse to flip the starting point
    start_offset = reverse ? -90 : 90;
    
    for (i = [0 : len_label - 1]) {
        ch = label[i];
        rotate(start_offset + i * char_angle)
            translate([radius, 0, 0])
                rotate(90 * dir_multiplier)  // flip rotation for reverse
                    linear_extrude(height = depth)
                        text(
                            ch,
                            size = size,
                            font = font,
                            halign = "center",
                            valign = "center"
                        );
    }
}

// Main puck module
module driver_fit_test_puck(driver_idx = 2) {
    echo("DRIVER FIT TEST PUCK CALLED");
    name_full = driverModelNames[driver_idx];
    params = driverParams[driver_idx];
    outer_dia = speakerFaceDiameters[driver_idx];
    cutout_dia = params[0];
    screw_pcd = params[1];
    face_shape = driverFaceShape[driver_idx];
    clip_depth = driverClipDepth[driver_idx];
    flush_depth = driverRecessDepth[driver_idx];
    corner_r = driverCornerRadius[driver_idx];
    super_n = driverAdjustCurvature[driver_idx];
    
    total_thickness = flush_depth + underFlangeThickness;
    
    name = name_full; // temporary - comment out substr for now
    
    base_str = str(name, "   CUT|", round(cutout_dia), "   ");
    
    extras_parts = [
    (screw_pcd > 0)
        ? str(" SCREW D|", screw_pcd, " ")
        : "",

    (flush_depth > 0)
        ? str(" FLUSH D|", flush_depth, " ")
        : "",
    
    (face_shape == 2 || face_shape == 6) && corner_r > 0
        ? str(" CORN R|", 2 * corner_r, " ")
        : "",

    (face_shape == 4 || face_shape == 5) && clip_depth > 0
        ? str(
            " CLIP D|", clip_depth, " ",
            " F2F|", (outer_dia - 2 * clip_depth), " "
          )
        : "",

    (face_shape == 7) && super_n != 1.0
        ? str("n", super_n)
        : ""
];

    //extras_str = str_join(extras_parts, " ");
    extras_str =
    str(
        extras_parts[0],
        extras_parts[1],
        extras_parts[2],
        extras_parts[3]
    );

    
    full_str = str(base_str, " ", extras_str);
    
    use_two_rows = (len(full_str) > 28) || (len(name) > 16 && len(extras_str) > 10);
    
    row_outer = use_two_rows ? base_str : full_str;
    row_inner = use_two_rows ? extras_str : "";
    
    // Dynamic sizing
    outer_size = fit_text_size;
    inner_size = fit_text_size * fit_inner_text_scale;

    est_outer_w = len(row_outer) * outer_size * fit_char_width_factor;
    est_inner_w = len(row_inner) * inner_size * fit_char_width_factor;

    // Outer radius - push farther out for bigger ring
    text_radius_outer = max(
        outer_dia / 2 + 16,   // increased base clearance (was 4)
        est_outer_w / (2 * PI) + 10  // extra buffer for longer text
    );

    // Inner radius - start closer to center, inside outer ring
    text_radius_inner = max(
        outer_dia / 2 + 7,               // min inside outer ring
        text_radius_outer - outer_size * 1.3 - est_inner_w / (2 * PI)  // pull inward more aggressively
    );

    // Puck radius - based on the outermost text
    // puck_radius = text_radius_outer + fit_puck_margin_base + 5;  // extra margin beyond outer text

    // extra_for_inner = use_two_rows ? 10 : 0;  // small extra if 2 rows (optional)
    // puck_radius_final = puck_radius + extra_for_inner;
    
    puck_radius = text_radius_outer + fit_outer_text_margin;
    puck_radius_final = puck_radius + (use_two_rows ? fit_two_row_extra : 0);

    puck_dia = 2 * puck_radius_final;
    
    echo(str("Puck dia: ", puck_dia, " mm"));
    echo(str("Extra for inner: ", extra_for_inner));
    echo(str("Use 2 rows: ", use_two_rows));
    
    difference() {
    flush_fit_test_puck(
        face_shape,
        outer_dia,
        cutout_dia,
        flush_depth,
        underFlangeThickness,
        driverScrewCount[driver_idx],
        screw_pcd,
        params[2],
        45,
        clip_depth,
        shape_fit_tolerance,
        cutout_fit_tolerance,
        puck_dia  // dynamic size
    );

    // Outer ring (bigger, farther out)
    translate([0, 0, total_thickness - fit_text_depth - 0.1])
        engraved_label_curved(
            row_outer,
            text_radius_outer,
            fit_text_depth + 0.2,
            outer_size
        );

    // Inner ring (smaller, closer in)
    if (use_two_rows && row_inner != "") {
        translate([0, 0, total_thickness - fit_text_depth - 0.1])
            engraved_label_curved(
                row_inner,
                text_radius_inner,
                fit_text_depth + 0.2,
                inner_size
                // no reverse needed if direction is now matching
            );
        }
    }
}

// Safe str_join (non-recursive)
function str_join(arr, delim = " ") =
    let(
        parts = [
            for (i = [0 : len(arr) - 1])
                if (arr[i] != "") arr[i]
        ]
    )
    len(parts) == 0 ? "" :
    str(
        parts[0],
        [ for (i = [1 : len(parts) - 1]) str(delim, parts[i]) ]
    );



/*
// Uncomment this to only see the driver fit test within this file
// Recomment this before using Speaker GUMBO
// Standalone preview - MUST BE OUTSIDE ANY MODULE
if ($preview) {
    driver_fit_test_puck(fitTestDriverIndex);
}
*/