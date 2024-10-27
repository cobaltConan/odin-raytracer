package raytracer

import os "core:os"
import fmt "core:fmt"
import math "core:math"
import la "core:math/linalg"

vec3 :: la.Vector3f64

Ctx :: struct {
    width: int,
    height: int,
};

Sphere :: struct {
    centre: vec3,
    radius: f64,
};

main :: proc() {
    ctx := Ctx{1024, 768};
    sphere: Sphere = {vec3{-3, 0, -16}, 2};
    fov: f64 = math.PI / 2

    framebuffer: [dynamic]vec3
    resize(&framebuffer, ctx.width * ctx.height);
    
    for j in 0..< ctx.height {
        for i in 0..< ctx.width {
            x: f64 = (2 * (f64(i)+ 0.5) / f64(ctx.width) - 1) * math.tan(fov/2)*f64(ctx.width)/f64(ctx.height);
            y: f64 = -(2 * (f64(j) + 0.5) / f64(ctx.height) - 1) * math.tan(fov/2);
            dir: vec3 = la.normalize(vec3{x, y, -1});
            framebuffer[j * ctx.width + i] = cast_ray(&vec3{0,0,0}, &dir, &sphere)
        }
    }

    write_PPM(&framebuffer, &ctx);
}


write_PPM :: proc(framebuffer: ^[dynamic]vec3, ctx: ^Ctx) {
    bytes: [dynamic]u8
    // ppm file setup
    append_elem_string(&bytes, "P3\n")
    append_elem_string(&bytes, fmt.aprint(ctx.width))
    append_elem_string(&bytes, " ")
    append_elem_string(&bytes, fmt.aprint(ctx.height))
    append_elem_string(&bytes, "\n")
    append_elem_string(&bytes, "255\n")

    for i in 0..< ctx.height * ctx.width {
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


ray_intersect :: proc(orig: ^vec3, dir: ^vec3, t0: f64, sphere: ^Sphere) -> bool {
    L: vec3 = sphere.centre - orig^;
    tca: f64 = la.dot(L,dir^);
    d2 := la.dot(L, L) - tca*tca;
    if (d2 > sphere.radius*sphere.radius) {return false};
    thc := math.sqrt(sphere.radius*sphere.radius - d2);
    t0 := tca - thc;
    t1 := tca + thc;
    if (t0 < 0) {t0 = t1};
    if (t0 < 0) {return false};
    return true;
}


cast_ray :: proc(orig: ^vec3, dir: ^vec3, sphere: ^Sphere) -> vec3 {
    sphere_dist: f64 = 10000000;
    if (!ray_intersect(orig, dir, sphere_dist, sphere)) {
        return vec3{0.2, 0.7, 0.8};
    }

    return vec3{0.4, 0.4, 0.3};
}
