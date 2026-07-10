precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    
    // Ajusta este valor: 1.0 = normal, 1.5 = más saturado, 2.0 = mucho
    float saturation = 1.4;
    
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(gray), color.rgb, saturation);
    
    gl_FragColor = color;
}
