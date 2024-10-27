package raytracer

import os "core:os"
import fmt "core:fmt"
import vec "core:math/linalg"

vec3 :: vec.Vector3f64

main :: proc() {
    width :: 1024;
    height :: 768;

    bytes: [dynamic]u8
    framebuffer: [dynamic]vec3
    resize(&framebuffer, width * height);
    
    for j in 0..< height {
        for i in 0..< width {
            framebuffer[j * width + i] = vec3{f64(j) / f64(height), f64(i) / f64(width), 0}
        }
    }

    // ppm file setup
    append_elem_string(&bytes, "P3\n")
    append_elem_string(&bytes, fmt.aprint(width))
    append_elem_string(&bytes, " ")
    append_elem_string(&bytes, fmt.aprint(height))
    append_elem_string(&bytes, "\n")
    append_elem_string(&bytes, "255\n")

    for i in 0..< height*width {
        for j in 0..< 3 {
            append_elem_string(&bytes, fmt.aprint(byte(255 * max(0, min(1, framebuffer[i][j])))))
            if (j != 3) {
                append_elem_string(&bytes, " ")
            }
        }
        append_elem_string(&bytes, "\n")
    }

    os.write_entire_file("some-bytes.ppm", bytes[:])
}
