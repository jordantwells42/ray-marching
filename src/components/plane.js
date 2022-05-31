import React, {useState, useEffect} from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'


export default function Plane(props){

    useEffect(() => { async function init(){ 

    const loader = new THREE.TextureLoader()
    // Canvas
    const canvas = document.querySelector("canvas.viewport")

    // Scene

    const sizes = {
        width: window.innerWidth,
        height: window.innerHeight
    }

    let scale = 1000;
    const world_sizes = {
      width: sizes.width/scale,
      height: sizes.height/scale
    }
    const scene = new THREE.Scene()

    // Objects
    //const geometry = new THREE.TorusGeometry( .7, .2, 160, 100 );
    const resolution = new THREE.Vector2(world_sizes.width, world_sizes.height)
    const geometry = new THREE.PlaneGeometry(2, 2, 1, 1)
    //geometry.rotateX(Math.PI * -0.5);

    // Materials
      let vertex;
      let fragment;
      fragment = await (await fetch('/fragment.glsl')).text();
      vertex = await (await fetch('/vertex.glsl')).text();
      
    
      const material = new THREE.ShaderMaterial({
        extensions: {derivatives: '#extension GL_OES_standard_derivatives : enable'},
          uniforms: {
              time: {value: 0},
              heldTime: {value: 0},
              mouse: {value: new THREE.Vector3(-10, -10, 0)},
              resolution: {value: resolution},
              holding: {value: false}
          },
          vertexShader: vertex,
          fragmentShader:  fragment
  
      })



    material.color = new THREE.Color(0xff0000)

    // Mesh
    const sphere = new THREE.Mesh(geometry,material)
    scene.add(sphere)

    // Lights

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.6)
    directionalLight.position.set(-0.5, 10, -10)
    scene.add(directionalLight)
    
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.3)
    scene.add(ambientLight)

    /**
     * Sizes
     */

    window.addEventListener('resize', () =>
    {
        // Update sizes
        sizes.width = window.innerWidth
        sizes.height = window.innerHeight

       world_sizes.width = sizes.width/scale;
       world_sizes.height = sizes.height/scale;

        // Update camera
        // camera.aspect = sizes.width / sizes.height
        camera.left = world_sizes.width / - 2
        camera.right = world_sizes.width / 2
        camera.top = world_sizes.height / 2
        camera.bottom = world_sizes.height / - 2
        camera.updateProjectionMatrix()
        
        material.uniforms.resolution.value = new THREE.Vector2(world_sizes.width, world_sizes.height)
        material.uniforms.resolution.needsUpdate = true
        // Update renderer
        renderer.setSize(sizes.width, sizes.height)
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    })

    document.addEventListener('mousemove', (event) => {
        let vector = new THREE.Vector3();
        vector.set(
            (event.clientX / sizes.width) * 2 - 1,
            - (event.clientY / sizes.height) * 2 + 1,
            0
        );
        //vector.unproject(camera);

        material.uniforms.mouse.value = vector
        material.uniforms.mouse.needsUpdate = true
        //console.log(material.uniforms.mouse.value)
    })

    document.addEventListener('mousedown', (event) => {
        console.log("lmao")
        material.uniforms.holding.value = true
        material.uniforms.heldTime.value = 0
        material.uniforms.heldTime.needsUpdate = true
        material.uniforms.holding.needsUpdate = true
    })


    document.addEventListener('mouseup', (event) => {
        console.log("unlmao")
        material.uniforms.holding.value = false
        material.uniforms.holding.needsUpdate = true
        
    })


    /**
     * Camera
     */
    // Base camera  
    let near = 1;
    let far = 100;
    const camera = new THREE.OrthographicCamera(world_sizes.width / - 2, world_sizes.width / 2,world_sizes.height / 2, world_sizes.height / -2, -1, 100 )
    camera.position.x = 0
    camera.position.y = 0
    camera.position.z = 2
    scene.add(camera)

    // Controls
    const controls = new OrbitControls(camera, canvas)
    controls.enableDamping = true

    /**
     * Renderer
     */
    const renderer = new THREE.WebGLRenderer({
        canvas: canvas
    })
    renderer.setSize(sizes.width, sizes.height)
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))

    /**
     * Animate
     */

    const clock = new THREE.Clock()

    const tick = () =>
    {

        const elapsedTime = clock.getElapsedTime()
        material.uniforms.time.value = elapsedTime
        material.uniforms.heldTime.value += 1 / 60;
        material.uniforms.heldTime.needsUpdate = true

        // Update objects
        //sphere.rotation.y = .5 * elapsedTime

        // Update Orbital Controls
        // controls.update()
        controls.enabled = false;

        // Render
        renderer.render(scene, camera)

        // Call tick again on the next frame
        window.requestAnimationFrame(tick)
    }
    tick()
} init()}, [])
    




    return (
        <canvas className='viewport'>

        </canvas>
    )




}