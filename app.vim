source math/matrix.vim
source math/vector.vim
source graphics/mesh.vim
source graphics/renderer.vim
source graphics/color.vim
source graphics/camera.vim

function! Initialize()
	" Create and setup window buffer
	enew
	set lazyredraw
	set noswapfile
	setlocal buftype=nofile
	set termguicolors
	set encoding=utf-8

	let s:time = 0
	let s:isRunning = 1

	" Create renderer
	let l:wininfo = getwininfo(win_getid())[0]
	let s:renderer = g:Renderer.create(l:wininfo.width, l:wininfo.height)
	call s:renderer.initialize()

	" Create scene
	let s:camera = g:Camera.create(3.14 / 3.0, 16.0 / 9.0)
	
	let s:sphereMesh = g:Mesh.create_from_file('models/sphere.obj')
	let s:sphereTransform = g:Matrix.translation(g:Vector.create(-3.0, 0.8, -7.0))

	let s:cubeMesh = g:Mesh.create_from_file('models/cube.obj')
	let s:cubeTransform = g:Matrix.multiply(g:Matrix.translation(g:Vector.create(0.0, 0.8, -7.0)), g:Matrix.rotationY(3.14 / 4.0))

	let s:coneMesh = g:Mesh.create_from_file('models/cone.obj')
	let s:coneTransform = g:Matrix.translation(g:Vector.create(3.0, 0.8, -7.0))

	let s:torusMesh = g:Mesh.create_from_file('models/torus.obj')
	let s:torusTransform = g:Matrix.multiply(g:Matrix.translation(g:Vector.create(0.0, 0.8, -4.0)), g:Matrix.rotationX(3.14 / 3.0))

	let s:planeMesh = g:Mesh.create_from_file('models/plane.obj')
	let s:planeTransform = g:Matrix.multiply(g:Matrix.translation(g:Vector.create(0.0, -1.0, 0.0)), g:Matrix.scale(g:Vector.create(5.0, 1.0, 5.0)))

	"let s:carMesh = g:Mesh.create_from_file('models/car.obj')
	"let s:carTransform = g:Matrix.multiply(g:Matrix.translation(g:Vector.create(0.0, -0.5, -1.7)), g:Matrix.rotationY(3.14 / 4.0))
endfunction

function! Close()
	set nolazyredraw
endfunction

function! Update()
	let l:dt = 0.016667
	let s:time = s:time + l:dt

	call s:camera.update_camera(l:dt)

	let input = getchar(0)
	if input == 27 " Esc
		let s:isRunning = 0
	elseif input == 114 " r
		let s:renderer.isWireframe = !s:renderer.isWireframe
	endif
endfunction

function! Render()
	call s:renderer.clear_screen()
	call s:renderer.begin_scene(s:camera)
	call s:renderer.submit_mesh(s:planeMesh, s:planeTransform, s:planeMesh.color)
	call s:renderer.submit_mesh(s:cubeMesh, s:cubeTransform, s:cubeMesh.color)
	call s:renderer.submit_mesh(s:sphereMesh, s:sphereTransform, s:sphereMesh.color)
	call s:renderer.submit_mesh(s:coneMesh, s:coneTransform, s:coneMesh.color)
	call s:renderer.submit_mesh(s:torusMesh, s:torusTransform, s:torusMesh.color)
	"call s:renderer.submit_mesh(s:carMesh, s:carTransform, s:carMesh.color)
	call s:renderer.flush()
	call s:renderer.present()
endfunction

function! EngineLoop()
	while s:isRunning
		call Update()
		call Render()
	endwhile
endfunction

function! Main()
	call Initialize()
	call EngineLoop()
	call Close()
endfunction

call Main()
