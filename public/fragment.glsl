varying vec2 vUv;
uniform float time;
uniform float heldTime;
uniform vec3 mouse;
uniform vec3 resolution;
uniform bool holding;
uniform float pixelation;

mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
	mat4 m = rotationMatrix(axis, angle);
	return (m * vec4(v, 1.0)).xyz;
}

float sdf_sphere(vec3 p, float r)
{
  return length(p) - r;
}

float sdf_cone( in vec3 p, in vec2 c, float h )
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
  vec2 q = h*vec2(c.x/c.y,-1.0);
    
  vec2 w = vec2( length(p.xz), p.y );
  vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
  return sqrt(d)*sign(s);
}

float sdf_box( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdf_torus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

// polynomial smooth min 1 (k=0.1)
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 smin2(vec2 a, vec2 b, float k){
  float minx = smin(a.x, b.x, k);
  float miny = mix(a.y, b.y, k);
  return vec2(minx, miny);
}

vec2 sdf(vec3 p){
  vec3 p1 = rotate(p, vec3(1.), time/2.);
  vec3 p2 = rotate(p, vec3(0.,1.,1.), time);
  

  float box = sdf_box(p1, vec3(0.4));
  float sphere = sdf_sphere(p, 0.001);

  vec2 final = smin2(vec2(box, 0.5), vec2(sphere,0.5), 0.5);
 

  if (holding){
    float mouseSphere = sdf_sphere(p - vec3(mouse.xy*resolution.xy*1.5, 0.), 0.15);
    vec3 p3 = mix(p +  vec3(mouse.xy*resolution.xy*1.5, 0), p - vec3(mouse.xy*resolution.xy*1.5, 0), pow(cos(heldTime*2.), 2.));
    
    float torus = sdf_torus(p3 ,vec2(0.05, 0.01));
    final = smin2(final, vec2(torus, -0.5), 1.0);

    final = smin2(vec2(mouseSphere,final.x*5.), final, 0.5);
  }
  else {
    float mouseSphere = sdf_sphere(p - vec3(mouse.xy*resolution.xy*1.5, 0.), 0.1);
    vec3 p3 = p - vec3(mouse.xy*resolution.xy*1.5, 0.) - vec3(0.5*cos(time*2.), 0.5*sin(time*4.), 0);

    float torus = sdf_torus(p3 ,vec2(0.05, 0.01));
    final = smin2(final, vec2(torus, -0.5), 1.0);

    final = smin2(vec2(mouseSphere,final.x*5.), final, 0.5);
  }
    /*
  for (int i = 0; i < 10; i++){
    float progress = fract(time/5.);
    float toCenter = sdf_sphere((vec3(sin(time), cos(time), 0.) - p*progress), 0.05);
    final = smin2(final,vec2(toCenter, 0), 0.3);
  }
  */


  return final;
}

vec2 pixelate(vec2 uv, float k){
  if (k > 0.){
  return floor(uv*k)/k;
  }
  return uv;
}


void main() {
  vec3 camPos = vec3(0., 0., 6);
  
  vec2 newUv = pixelate(vUv, pixelation);
  vec3 ray = normalize(vec3(newUv - vec2(0.5, 0.5),-1));


  float t = 0.;
  float tMax = 10.;
  float count = 0.;

  for(int i = 0; i < 128; i++){
    vec3 pos = camPos + t*ray;
    float h = sdf(pos).x;
    if (h < 0.0001 || t > tMax) {
      break;
    }
    t = t + h;
    count = count + 1.;
  }


  vec3 color = vec3(0.0, 0.0, 0.0);
  vec3 red = vec3(1.,0.,0.);
  vec3 blue = vec3(0.,0.,1.0);
  if (t<tMax){
    vec3 pos = camPos + t*ray;
    color = mix(red, blue, sdf(pos).y);
    color = mix(color, vec3(1., 1., 1.), count/16.);
  }

  
  gl_FragColor = vec4(color, 1.);

}