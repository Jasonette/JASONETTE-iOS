
uniform sampler2D u_samplerY;
uniform sampler2D u_samplerUV;

varying highp vec2 v_texture;

void main()
{
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    yuv.x = texture2D(u_samplerY, v_texture).r;
    yuv.yz = texture2D(u_samplerUV, v_texture).rg - vec2(0.5, 0.5);
    
    // BT.709, the standard for HDTV
    rgb = mat3(      1,       1,      1,
                     0, -.18732, 1.8556,
               1.57481, -.46813,      0) * yuv;
    
    gl_FragColor = vec4(rgb, 1);
}

