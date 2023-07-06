source vector.vim
source color.vim

" ------------------------------------------------------------- Vertex ------------------------------------------------------------
let Vertex = {}

function! Vertex.create(position)
	return #{ position: a:position }
endfunction

" ------------------------------------------------------------ Triangle -----------------------------------------------------------
let Triangle = {}

function! Triangle.create(vertex0, vertex1, vertex2)
	return #{ v0: a:vertex0, v1: a:vertex1, v2: a:vertex2 }
endfunction

" -------------------------------------------------------------- Mesh -------------------------------------------------------------
let Mesh = {}

function! Mesh.create(triangles, color)
	return #{ triangles: a:triangles, color: a:color }
endfunction

function! Mesh.create_from_file(filepath)
	let l:materialFileName = ''
	let l:positions = []
	let l:triangles = []
	let l:color = g:Color.create(255, 255, 255)

	for line in readfile(a:filepath)
		let l:tokens = split(line)
		
		if len(tokens) == 0
			continue
		endif

		if l:tokens[0] == "v"
			call add(l:positions, g:Vector.create(str2float(l:tokens[1]), str2float(l:tokens[2]), str2float(l:tokens[3])))
		elseif l:tokens[0] == "f"
			let l:vertices = []
			for i in range(1, 3)
				let l:indices = split(l:tokens[i], '/')
				call add(l:vertices, g:Vertex.create(l:positions[str2nr(l:indices[0]) - 1]))
			endfor
			call add(l:triangles, g:Triangle.create(l:vertices[0], l:vertices[1], l:vertices[2]))
		elseif l:tokens[0] == "mtllib"
			let l:materialFileName = l:tokens[1]
		endif
	endfor

	" Get material color
	let l:pathDirectories = split(a:filepath, '[/\\]')
	call remove(l:pathDirectories, -1)
	let l:materialFullPath = join(l:pathDirectories, '/') . '/' . l:materialFileName

	echo l:materialFullPath

	for line in readfile(l:materialFullPath)
		let l:tokens = split(line)
		
		if len(tokens) == 0
			continue
		endif

		if l:tokens[0] == "Kd"
			let l:color = g:Color.create(float2nr(str2float(l:tokens[1]) * 255), float2nr(str2float(l:tokens[2]) * 255), float2nr(str2float(l:tokens[3]) * 255))
		endif
	endfor

	return #{ triangles: l:triangles, color: l:color }
endfunction

