Cannon = require 'cannon'
{Signal} = require './signal.ls'
jStat = require 'jstat'
P = require 'bluebird'
Co = P.coroutine
{loadCollada, mergeObject} = require './utils.ls'

{perlin=noise} = require './vendor/perlin.js'

# Todo: ugly
window.THREE = THREE = require 'three'
require './three.js/examples/js/SkyShader.js'

# TODO: Find a good fidelity/performance
# compromise parameters
export class Scene
	({@stepDuration=1/240}={}) ->
		@physics = new Cannon.World
			..gravity.set 0, -9.81, 0
			..defaultContactMaterial
				..friction = 0.7
				..restitution = 0.3
			..solver.iterations = 100
			..broadphase = new Cannon.SAPBroadphase @physics

		@visual = new THREE.Scene

		@camera = new THREE.PerspectiveCamera 50, 1, 0.01, 450000

		@time = 0

		@onPhysics.add (dt) ~>
			stepdur = Math.min dt, @stepDuration
			@physics.step stepdur, dt

	tick: (dt) ->
		@beforePhysics.dispatch dt
		@onPhysics.dispatch dt
		@afterPhysics.dispatch dt

		@beforeRender.dispatch dt
		@onRender.dispatch dt
		@afterRender.dispatch dt

		@time += dt
		@onTickHandled.dispatch dt

	beforePhysics: new Signal
	onPhysics: new Signal
	afterPhysics: new Signal

	beforeRender: new Signal
	onRender: new Signal
	afterRender: new Signal

	onTickHandled: new Signal

	onExit: new Signal

	bindPhys: (physical, visual) ->
		@afterPhysics.add ->
			visual.position.copy physical.position
			visual.quaternion.copy physical.quaternion

export addSky = (scene) ->
	sky = new THREE.Sky
	sky.uniforms.sunPosition.value.y = 4500
	scene.visual.add sky.mesh

	sunlight = new THREE.DirectionalLight 0xffffff, 0.6
	sunlight.position.set 0, 4500, 0
	scene.visual.add sunlight
	hemiLight = new THREE.HemisphereLight 0xffffff, 0xffffff, 0.1
		..position.set 0, 4500, 0
	scene.visual.add hemiLight
	scene.visual.add new THREE.AmbientLight 0x606060
	position = new THREE.Vector3
	scene.beforeRender.add ->
		position.setFromMatrixPosition scene.camera.matrixWorld
		sky.mesh.position.z = position.z


generateRock = (seed=Math.random()) ->
	perlin.seed seed
	radius = 1
	scale = radius
	noiseScale = 100
	geo = new THREE.IcosahedronGeometry radius, 1
	dir = new THREE.Vector3
	for vert in geo.vertices
		dir.copy vert
		dir.normalize()
		rnd = perlin.simplex3(vert.x*noiseScale, vert.y*noiseScale, vert.z*noiseScale)*scale
		dir.multiplyScalar Math.abs(rnd)*scale
		vert.add dir
	geo.verticesNeedUpdate = true
	geo.computeVertexNormals()
	geo.computeFaceNormals()
	rock = new THREE.Mesh geo, new THREE.MeshLambertMaterial color: 0xd3ab6d
	return rock

export loadTrafficLight = Co ->*
	data = yield loadCollada 'res/signs/TrafficLight.dae'
	model = data.scene.children[0]
	model.scale.set 0.03, 0.03, 0.03

	lights =
		red: model.getObjectByName 'Red'
		yellow: model.getObjectByName 'Yellow'
		green: model.getObjectByName 'Green'

	for let name, light of lights
		materials = light.children[0].material.materials
		materials = for material in materials
			material = material.clone()
			hsl = material.color.getHSL()
			material.color.setHSL hsl.h, hsl.s, 0.1
			material

		light.children[0].material.materials = materials

		light.on = ->
			for material in materials
				hsl = material.color.getHSL()
				material.emissive.setHSL hsl.h, 0.9, 0.5
		light.off = ->
			for material in materials
				hsl = material.color.getHSL()
				material.emissive.setHSL hsl.h, 0.0, 0.0

	#lights.red.on()
	#lights.yellow.on()
	lights.green.on()

	state: 'green'
	visual: model
	addTo: (scene) ->
		scene.visual.add model

export addGround = (scene) ->
	groundTex = THREE.ImageUtils.loadTexture 'res/world/sandtexture.jpg'
	terrainSize = 1000
	textureSize = 5
	textureRep = terrainSize/textureSize
	groundNorm = THREE.ImageUtils.loadTexture 'res/world/sandtexture.norm.jpg'
	groundTex.wrapS = groundTex.wrapT = THREE.RepeatWrapping
	groundNorm.wrapS = groundNorm.wrapT = THREE.RepeatWrapping
	groundTex.repeat.set textureRep, textureRep
	groundNorm.repeat.set textureRep, textureRep
	groundTex.anisotropy = 12 #renderer.getMaxAnisotropy()
	groundMaterial = new THREE.MeshPhongMaterial do
		color: 0xffffff
		map: groundTex
		normalMap: groundNorm
	terrain = new THREE.Object3D

	groundGeometry = new THREE.PlaneGeometry terrainSize, terrainSize, 0, 0
	ground = new THREE.Mesh groundGeometry, groundMaterial
	ground.rotation.x = -Math.PI/2.0
	# To avoid z-fighting. Should be handled by
	# polygon offset, but it gives very weird results
	ground.position.y = -0.1
	groundBody = new Cannon.Body mass: 0
		..addShape new Cannon.Plane
		..quaternion.setFromAxisAngle new Cannon.Vec3(1,0,0), -Math.PI/2.0
	terrain.add ground
	scene.physics.add groundBody

	roadWidth = 7
	roadGeo = new THREE.PlaneGeometry terrainSize, roadWidth, 0, 0
	roadTex = THREE.ImageUtils.loadTexture 'res/world/road_texture.jpg'
	roadNorm = THREE.ImageUtils.loadTexture 'res/world/road_texture.norm.jpg'
	roadTex.anisotropy = 12#renderer.getMaxAnisotropy()
	#roadTex.minFilter = THREE.LinearMipMapLinearFilter
	roadTex.minFilter = THREE.LinearFilter
	roadTex.wrapS = roadTex.wrapT = THREE.RepeatWrapping
	roadNorm.wrapS = roadNorm.wrapT = THREE.RepeatWrapping
	roadTex.repeat.set textureRep/2.0, 1
	roadNorm.repeat.set textureRep/2.0, 1
	roadMat = new THREE.MeshPhongMaterial do
		map: roadTex
		#normalMap: roadNorm
	road = new THREE.Mesh roadGeo, roadMat
	road.rotation.x = -Math.PI/2.0
	road.rotation.z = -Math.PI/2.0
	road.position.y = 0
	terrain.add road

	rocks = new THREE.Object3D()
	nRockTypes = 10
	rockPool = for i from 0 til nRockTypes
		generateRock()
	randomRock = ->
		rock = rockPool[Math.floor(Math.random()*rockPool.length)]
		return new THREE.Mesh rock.geometry, rock.material
	nRocks = Math.round(terrainSize*(2*200)/500)
	sizeDist = jStat.uniform(0.1, 0.6)
	zDist = jStat.uniform(-terrainSize/2, terrainSize/2)
	xDist = jStat.uniform(-200, 200)
	for i from 0 til nRocks
		x = xDist.sample()
		size = sizeDist.sample()
		if Math.abs(x) - Math.abs(size) < roadWidth
			continue
		z = zDist.sample()
		rock = randomRock()
		rock.position.x = x
		rock.position.z = z
		rock.scale.multiplyScalar size
		rock.scale.y *= 0.8
		rock.updateMatrix()
		rock.matrixAutoUpdate = false
		rocks.add rock

	terrain.add mergeObject rocks

	scene.visual.add terrain
	doubler = terrain.clone()
	scene.visual.add doubler

	position = new THREE.Vector3
	scene.beforeRender.add ->
		position.setFromMatrixPosition scene.camera.matrixWorld
		nTerrains = Math.floor (position.z+terrainSize/2.0)/terrainSize
		terrain.position.z = nTerrains*terrainSize
		doubler.position.z = terrain.position.z + terrainSize

