
attribute vec4 a_position;
attribute vec2 a_texture;

varying vec2 v_texture;

void main()
{
    v_texture = a_texture;
    gl_Position = a_position;
}
