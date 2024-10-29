package raytracer

import os "core:os"
import fmt "core:fmt"
import math "core:math"
import la "core:math/linalg"

vec3 :: la.Vector3f64
vec2 :: la.Vector2f64

Ctx :: struct {
    width: int,
    height: int,
};

Sphere :: struct {
    centre: vec3,
    radius: f64,
    material: Material,
};

Material :: struct {
    diffuse_color: vec3,
    albedo: vec2,
    specular_exponent: f64,
}

Light :: struct {
    position: vec3,
    intensity: f64,
}

main :: proc() {
    ctx := Ctx{1024, 768};
    spheres: [dynamic]Sphere;
    append_elem(&spheres, Sphere{vec3{-3, 0, -16}, 2, Material{vec3{0.5,0.5,0.5}, vec2{0.6, 0.3}, 50}});
    append_elem(&spheres, Sphere{vec3{-1, -1.5, -12}, 2, Material{vec3{0.3,0.1,0.1}, vec2{0.9, 0.1}, 10}});
    append_elem(&spheres, Sphere{vec3{1.5, -0.5, -18}, 4, Material{vec3{0.1,0.1,0.1}, vec2{0.9, 0.9}, 8}});

    fov: f64 = math.PI / 2

    framebuffer: [dynamic]vec3
    resize(&framebuffer, ctx.width * ctx.height);

    lights: [dynamic]Light;
    append_elem(&lights, Light{vec3{-20,20,20}, 1.5});
    append_elem(&lights, Light{vec3{30,50,-25}, 1.8});
    append_elem(&lights, Light{vec3{30,20,30}, 1.7});

    for j in 0..< ctx.height {
        for i in 0..< ctx.width {
            x: f64 = (2 * (f64(i)+ 0.5) / f64(ctx.width) - 1) * math.tan(fov/2)*f64(ctx.width)/f64(ctx.height);
            y: f64 = -(2 * (f64(j) + 0.5) / f64(ctx.height) - 1) * math.tan(fov/2);
            dir: vec3 = la.normalize(vec3{x, y, -1});
            framebuffer[j * ctx.width + i] = cast_ray(&vec3{0,0,0}, &dir, &spheres, &lights)
        }
    }

    see: ^vec3
    c: vec3
    maxi: f64
    
    for i in 0..< ctx.height * ctx.width {
        see = &framebuffer[i];
        c = see^;
        maxi = max(c[0], max(c[1], c[2])) 
        if (maxi > 1) {c = c * (1/maxi)};
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

reflect :: proc(I: ^vec3, N: ^vec3) -> vec3 {
    return (I^ - N^ * 2 * I^ * N^);
}

ray_intersect :: proc(orig: ^vec3, dir: ^vec3, t0: ^f64, sphere: ^Sphere) -> bool {
    L: vec3 = sphere.centre - orig^;
    tca: f64 = la.dot(L,dir^);
    d2 := la.dot(L, L) - tca*tca;
    if (d2 > sphere.radius*sphere.radius) {return false};
    thc := math.sqrt(sphere.radius*sphere.radius - d2);
    t0^ = tca - thc;
    t1 := tca + thc;
    if (t0^ < 0) {t0^ = t1};
    if (t0^ < 0) {return false};
    return true;
}


scene_intersect :: proc(orig: ^vec3, dir: ^vec3, spheres: ^[dynamic]Sphere, hit: ^vec3, N: ^vec3, material: ^Material) -> bool {
    spheres_dist: f64 = 10000000;

    for i in 0..< len(spheres) {
        dist_i: f64;
        if (ray_intersect(orig, dir, &dist_i, &spheres[i]) && dist_i < spheres_dist) {
            spheres_dist = dist_i;
            hit^ = orig^ + dir^ * dist_i;
            N^ = la.normalize(hit^ - spheres[i].centre);
            material^ = spheres[i].material;
        }
    }

    return spheres_dist < 1000;
}


cast_ray :: proc(orig: ^vec3, dir: ^vec3, spheres: ^[dynamic]Sphere, lights: ^[dynamic]Light) -> vec3 {
    point: vec3;
    N: vec3;
    material: Material;

    if (!scene_intersect(orig, dir, spheres, &point, &N, &material)) {
        return vec3{0.2, 0.7, 0.8};
    }

    diffuse_light_intensity: f64;
    specular_light_intensity: f64;

    for i in 0..< len(lights) {
        light_dir: vec3 = la.normalize(lights[i].position - point);
        diffuse_light_intensity += lights[i].intensity * max(0, la.dot(light_dir,N));
        light_dir = -light_dir;
        specular_light_intensity += math.pow(max(0, la.dot(-reflect(&light_dir, &N),dir^)), material.specular_exponent) * lights[i].intensity;
    }

    return material.diffuse_color * diffuse_light_intensity * material.albedo[0] + vec3{1,1,1} * specular_light_intensity * material.albedo[1];
}
