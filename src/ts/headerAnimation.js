// Vertex shader for the points animation
const vertexShader = `
      #define PI 3.14159265359
  
      // Uniform variables for time and point size, as well as parameters for two transformations
      uniform float u_time;
      uniform float u_pointsize;
      uniform float u_transformation_amp_1;
      uniform float u_transformation_freq_1;
      uniform float u_transformation_speed_1;
      uniform float u_transformation_amp_2;
      uniform float u_transformation_freq_2;
      uniform float u_transformation_speed_2;
  
      void main() {
        // Initialize position with the vertex's original position
        vec3 pos = position;
        
        // Apply two sinusoidal transformations to the z-coordinate of the position
        pos.z += sin(pos.x * u_transformation_freq_1 + u_time * u_transformation_speed_1) * u_transformation_amp_1;
        pos.z += cos(pos.y * u_transformation_freq_2 - u_time * u_transformation_speed_2 * 0.6) * u_transformation_amp_2;
        
        // Adjust the point size based on the absolute z-coordinate
        gl_PointSize = max(u_pointsize + abs(pos.z) * 6.0, 0.0);
        
        // Apply model-view and projection transformations to the position
        vec4 mvm = modelViewMatrix * vec4(pos, 1.0);
        gl_Position = projectionMatrix * mvm;
      }
    `;

// Fragment shader for the points animation
const fragmentShader = `
      // Uniform variable for time
      uniform float u_time;
      #ifdef GL_ES
      precision mediump float;
      #endif
  
      void main() {
        // Calculate the distance from the center of the point
        vec2 st = gl_PointCoord - vec2(0.5);
        float r = length(st);
  
        // Discard fragments outside a circular region
        if (r > 0.5) {
          discard;
        }
  
        // Calculate alpha (transparency) based on the depth of the fragment
        float alpha = 1.0 - gl_FragCoord.z * 1.095;
        alpha = clamp(alpha, 0.0, 1.0);

        // Set the final fragment color with a blue tone and transparency
        gl_FragColor = vec4(vec3(0.42, 0.635, 0.835), alpha);
      }
    `;


// Function to create a camera with specified parameters
function createCamera(
    fov = 45,
    near = 0.1,
    far = 100,
    camPos = { x: 0, y: 0, z: 0 },
    camLookAt = { x: 0, y: 0, z: 0 },
    aspect = window.innerWidth / window.innerHeight
) {
    const camera = new THREE.PerspectiveCamera(fov, aspect, near, far);
    camera.position.set(camPos.x, camPos.y, camPos.z);
    camera.lookAt(camLookAt.x, camLookAt.y, camLookAt.z);
    camera.updateProjectionMatrix();
    return camera;
}

// Function to create a WebGLRenderer with specified properties
function createRenderer(rendererProps = {}) {
    const container = document.getElementById("banner");
    const renderer = new THREE.WebGLRenderer({ ...rendererProps, alpha: true });
    renderer.domElement.id = "banner-animation";
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.setSize(container.offsetWidth, container.offsetHeight);
    renderer.setClearColor(0xffffff, 0);
    renderer.domElement.id = "banner-animation";
    return renderer;
}

// Function to run the animation loop
function runAnimation(
    app,
    scene,
    renderer,
    camera,
    enableAnimation = false,
    uniforms = getDefaultUniforms()
) {
    // Append banner-animation canvas to banner
    const container = document.getElementById("banner");
    container.appendChild(renderer.domElement);

    // Register resize listener
    window.addEventListener("resize", () => {
        let container = document.getElementById("banner");
        camera.aspect = container.offsetWidth / container.offsetHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(container.offsetWidth, container.offsetHeight);
        // Update uniforms.u_resolution
        if (uniforms.u_resolution !== undefined) {
            uniforms.u_resolution.value.x =
                window.innerWidth * window.devicePixelRatio;
            uniforms.u_resolution.value.y =
                window.innerHeight * window.devicePixelRatio;
        }
    });

    // If the updateScene function is not defined in the app, assign an empty function
    if (app.updateScene === undefined) {
        app.updateScene = (delta, elapsed) => { };
    }
    Object.assign(app, { ...app, container });

    const clock = new THREE.Clock();
    const animate = () => {
        if (enableAnimation) {
            requestAnimationFrame(animate);
        }

        const delta = clock.getDelta();
        const elapsed = clock.getElapsedTime();
        uniforms.u_time.value = elapsed;

        // Call the app's updateScene function and render the scene
        app.updateScene(delta, elapsed);
        renderer.render(scene, camera);
    };

    // Initialize the scene, start the animation loop, and reset renderer info
    app
        .initScene()
        .then(animate)
        .then(() => {
            renderer.info.reset();
        })
        .catch((error) => {
            console.log(error);
        });
}

// Create a new THREE scene, renderer, and camera
let scene = new THREE.Scene();
let renderer = createRenderer({ antialias: false });
let camera = createCamera(60, 1, 100, { x: 0, y: 0, z: 4.5 });

// Define uniform variables for the shaders
const uniforms = {
    u_time: { value: 0.0 },
    // Resolution of the canvas (width and height)
    u_resolution: {
        value: {
            x: window.innerWidth * window.devicePixelRatio,
            y: window.innerHeight * window.devicePixelRatio,
        },
    },
    // Point size for rendering
    u_pointsize: { value: 6.0 },

    // Parameters for the wave1 animation
    u_transformation_freq_1: { value: 3.0 },
    u_transformation_amp_1: { value: 0.8 },
    u_transformation_speed_1: { value: 0.25 },

    // Parameters for the wave2 animation
    u_transformation_freq_2: { value: 2.0 },
    u_transformation_amp_2: { value: 0.7 },
    u_transformation_speed_2: { value: 0.20 },
};

// Define the app object containing shaders and scene initialization
let app = {
    vertexShader,
    fragmentShader,

    async initScene() {
        // Create a plane geometry for the points
        this.geometry = new THREE.PlaneGeometry(10, 5, 50, 40);

        // Create a shader material using the provided vertex and fragment shaders
        const material = new THREE.ShaderMaterial({
            uniforms: {
                ...uniforms,
                cameraPosition: { value: camera.position },
            },
            vertexShader: this.vertexShader,
            fragmentShader: this.fragmentShader,
            transparent: true,
            depthTest: false,
        });

        // Create a points mesh and add it to the scene
        this.mesh = new THREE.Points(this.geometry, material);
        scene.add(this.mesh);

        // Set initial rotations for the mesh
        this.mesh.rotation.x = 3.1415 / 2;
        this.mesh.rotation.y = 3.1415 / 4;
    },

    // Update function for the animation loop
    updateScene(interval, elapsed) {
        // Update the time uniform and camera position uniform in the shader
        uniforms.u_time.value += interval * 0.001;
        this.mesh.material.uniforms.cameraPosition.value.copy(camera.position);
    },
};

// Run the animation loop with the defined app, scene, renderer, camera, and uniforms
runAnimation(app, scene, renderer, camera, true, uniforms);
