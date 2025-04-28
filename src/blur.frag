#version 330 core

in vec2 TexCoords;
out vec4 FragColor;

uniform sampler2D screenTexture;  // The scene's rendered texture
uniform float blurRadius;         // e.g., 4.0
uniform vec4 tintColor;           // e.g., vec4(1.0, 1.0, 1.0, 0.3)
uniform vec2 resolution;          // Screen resolution (width, height)

void main()
{
    vec2 tex_offset = 1.0 / resolution; // Size of 1 pixel
    vec3 result = vec3(0.0);
    float count = 0.0;

    // Simple box blur
    for (int x = -2; x <= 2; ++x) {
        for (int y = -2; y <= 2; ++y) {
            vec2 offset = vec2(float(x), float(y)) * tex_offset * blurRadius;
            result += texture(screenTexture, TexCoords + offset).rgb;
            count += 1.0;
        }
    }

    vec3 blurred = result / count;
    vec4 finalColor = vec4(blurred, 1.0);

    // Blend with tint
    FragColor = mix(finalColor, tintColor, tintColor.a);
}