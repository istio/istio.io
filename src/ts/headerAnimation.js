
var SEPARATION = 40, AMOUNTX = 130, AMOUNTY = 25;
var PARTICLE_COLOR = "#6ba2d5";
var ANIMATION_SPEED = 0.015;

var container;
var camera, scene, renderer;

var particles, particle, count = 0;

var windowHalfX = window.innerWidth / 2;
var windowHalfY = window.innerHeight / 2;

document.onreadystatechange = () => {
	if(document.readyState === "interactive") {
		init();
		animate();
	}
}

function init() {
	container = document.getElementById( "banner" );

	camera = new THREE.PerspectiveCamera( 120, container.offsetWidth / container.offsetHeight, 1, 10000 );
	camera.position.y = 150;	// Changes how far back you can see i.e the particles towards horizon
	camera.position.z = 150;	// This is how close or far the particles are seen
	
	camera.rotation.x = 0.35;
	camera.rotation.y = 0.75;
	
	scene = new THREE.Scene();

	particles = new Array();

	var PI2 = Math.PI * 2;
	var material = new THREE.SpriteCanvasMaterial( {
		color: PARTICLE_COLOR,	// Changes color of particles
		program: function ( context ) {
			context.beginPath();
			context.arc( 0, 0, 0.1, 0, PI2, true );
			context.fill();
		}
	} );

	var i = 0;

	for ( var ix = 0; ix < AMOUNTX; ix ++ ) {
		for ( var iy = 0; iy < AMOUNTY; iy ++ ) {
			particle = particles[ i ++ ] = new THREE.Sprite( material );
			particle.position.y = ix * SEPARATION - ( ( AMOUNTX * SEPARATION ) / 2 );
			particle.position.z = iy * SEPARATION - ( ( AMOUNTY * SEPARATION ) - 10 );
			scene.add( particle );
		}
	}

	renderer = new THREE.CanvasRenderer({ alpha: true });
	renderer.setSize( container.offsetWidth, container.offsetHeight );
	renderer.setClearColor( 0xffffff, 0);
	renderer.domElement.id = "banner-animation";
	container.appendChild( renderer.domElement );

	window.addEventListener( 'resize', onWindowResize, false );
}

function onWindowResize() {
	windowHalfX = window.innerWidth / 2;
	windowHalfY = window.innerHeight / 2;

	container = document.getElementById( "banner" );

	camera.aspect = container.offsetWidth / container.offsetHeight;
	camera.updateProjectionMatrix();

	renderer.setSize( container.offsetWidth, container.offsetHeight );
}

function animate() {
	requestAnimationFrame( animate );
	render();
}

function render() {
	var i = 0;

	for ( var ix = 0; ix < AMOUNTX; ix ++ ) {
		for ( var iy = 0; iy < AMOUNTY; iy ++ ) {
			particle = particles[ i++ ];
			particle.position.x = ( Math.sin( ( iy + count ) * 0.5 ) * 50 ) + ( Math.sin( ( ix + count ) * 0.5 ) * 120 );
			particle.scale.x = particle.scale.y = ( Math.sin( ( ix + count ) * 0.3 ) + 2 ) * 6 + ( Math.sin( ( iy + count ) * 0.5 ) + 1 ) * 6;
		}
	}

	renderer.render( scene, camera );

	// This increases or decreases speed
	count += ANIMATION_SPEED;
}