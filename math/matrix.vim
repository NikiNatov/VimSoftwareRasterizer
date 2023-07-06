source vector.vim

let Matrix = {}

" ------------------------------------------------------------- Constructors ------------------------------------------------------------
function! Matrix.create()
	let l:data = [
		\ 0, 0, 0, 0,
		\ 0, 0, 0, 0,
		\ 0, 0, 0, 0,
		\ 0, 0, 0, 0
		\ ]

	return #{ data: l:data }
endfunction

function! Matrix.identity()
	let l:data = [
		\ 1, 0, 0, 0,
		\ 0, 1, 0, 0,
		\ 0, 0, 1, 0,
		\ 0, 0, 0, 1
		\ ]

	return #{ data: l:data }
endfunction

function! Matrix.translation(translation)
	let l:data = [
		\ 1, 0, 0, a:translation.x,
		\ 0, 1, 0, a:translation.y,
		\ 0, 0, 1, a:translation.z,
		\ 0, 0, 0, 1
		\ ]

	return #{ data: l:data }
endfunction

function! Matrix.rotationX(angle)
	let l:data = [
		\ 1, 0, 	    0, 	          0,
		\ 0, cos(a:angle), -sin(a:angle), 0,
		\ 0, sin(a:angle),  cos(a:angle), 0,
		\ 0, 0, 	    0, 	          1
		\ ]

	return #{ data: l:data }
endfunction

function! Matrix.rotationY(angle)
	let l:data = [
		\ cos(a:angle),  0, sin(a:angle), 0,
		\ 0, 		 1, 0, 		  0,
		\ -sin(a:angle), 0, cos(a:angle), 0,
		\ 0, 		 0, 0, 		  1
		\ ]

	return #{ data: l:data }
endfunction

function! Matrix.rotationZ(angle)
	let l:data = [
		\ cos(a:angle), -sin(a:angle), 0, 0,
		\ sin(a:angle),  cos(a:angle), 0, 0,
		\ 0, 		 0, 	       1, 0,
		\ 0, 		 0, 	       0, 1
		\ ]

	return #{ data: l:data }
endfunction

function! Matrix.scale(scale)
	let l:data = [
		\ a:scale.x, 0, 	0, 	   0,
		\ 0, 	     a:scale.y, 0, 	   0,
		\ 0, 	     0, 	a:scale.z, 0,
		\ 0, 	     0, 	0, 	   1
		\ ]

	return #{ data: l:data }
endfunction

function! Matrix.projection(fov, aspectRatio, near, far)
	let l:data = [
		\ 1.0 / (a:aspectRatio * tan(a:fov / 2.0)), 0, 			    0, 			    	          0,
		\ 0, 				    	    1 / tan(a:fov / 2.0),   0, 			    	          0,
		\ 0, 				    	    0, 			   -(a:far + a:near) / (a:far - a:near), -2 * a:far * a:near / (a:far - a:near),
		\ 0, 				    	    0, 			   -1, 					  0
		\ ]

	return #{ data: l:data }
endfunction

function! Matrix.from_column_vectors(column0, column1, column2, column3)
	let l:data = [
		\ a:column0.x, a:column1.x, a:column2.x, a:column3.x,
		\ a:column0.y, a:column1.y, a:column2.y, a:column3.y,
		\ a:column0.z, a:column1.z, a:column2.z, a:column3.z,
		\ 0, 	       0, 	    0, 		 1
		\ ]

	return #{ data: l:data }
endfunction

" --------------------------------------------------------- Arithmetic operation --------------------------------------------------------
function! Matrix.multiply(matA, matB)
	let l:result = self.create()

	let l:result.data[0] = a:matA.data[0] * a:matB.data[0] + a:matA.data[1] * a:matB.data[4] + a:matA.data[2] * a:matB.data[8]  + a:matA.data[3] * a:matB.data[12]
	let l:result.data[1] = a:matA.data[0] * a:matB.data[1] + a:matA.data[1] * a:matB.data[5] + a:matA.data[2] * a:matB.data[9]  + a:matA.data[3] * a:matB.data[13]
	let l:result.data[2] = a:matA.data[0] * a:matB.data[2] + a:matA.data[1] * a:matB.data[6] + a:matA.data[2] * a:matB.data[10] + a:matA.data[3] * a:matB.data[14]
	let l:result.data[3] = a:matA.data[0] * a:matB.data[3] + a:matA.data[1] * a:matB.data[7] + a:matA.data[2] * a:matB.data[11] + a:matA.data[3] * a:matB.data[15]

	let l:result.data[4] = a:matA.data[4] * a:matB.data[0] + a:matA.data[5] * a:matB.data[4] + a:matA.data[6] * a:matB.data[8]  + a:matA.data[7] * a:matB.data[12]
	let l:result.data[5] = a:matA.data[4] * a:matB.data[1] + a:matA.data[5] * a:matB.data[5] + a:matA.data[6] * a:matB.data[9]  + a:matA.data[7] * a:matB.data[13]
	let l:result.data[6] = a:matA.data[4] * a:matB.data[2] + a:matA.data[5] * a:matB.data[6] + a:matA.data[6] * a:matB.data[10] + a:matA.data[7] * a:matB.data[14]
	let l:result.data[7] = a:matA.data[4] * a:matB.data[3] + a:matA.data[5] * a:matB.data[7] + a:matA.data[6] * a:matB.data[11] + a:matA.data[7] * a:matB.data[15]

	let l:result.data[8]  = a:matA.data[8] * a:matB.data[0] + a:matA.data[9] * a:matB.data[4] + a:matA.data[10] * a:matB.data[8]  + a:matA.data[11] * a:matB.data[12]
	let l:result.data[9]  = a:matA.data[8] * a:matB.data[1] + a:matA.data[9] * a:matB.data[5] + a:matA.data[10] * a:matB.data[9]  + a:matA.data[11] * a:matB.data[13]
	let l:result.data[10] = a:matA.data[8] * a:matB.data[2] + a:matA.data[9] * a:matB.data[6] + a:matA.data[10] * a:matB.data[10] + a:matA.data[11] * a:matB.data[14]
	let l:result.data[11] = a:matA.data[8] * a:matB.data[3] + a:matA.data[9] * a:matB.data[7] + a:matA.data[10] * a:matB.data[11] + a:matA.data[11] * a:matB.data[15]

	let l:result.data[12] = a:matA.data[12] * a:matB.data[0] + a:matA.data[13] * a:matB.data[4] + a:matA.data[14] * a:matB.data[8]  + a:matA.data[15] * a:matB.data[12]
	let l:result.data[13] = a:matA.data[12] * a:matB.data[1] + a:matA.data[13] * a:matB.data[5] + a:matA.data[14] * a:matB.data[9]  + a:matA.data[15] * a:matB.data[13]
	let l:result.data[14] = a:matA.data[12] * a:matB.data[2] + a:matA.data[13] * a:matB.data[6] + a:matA.data[14] * a:matB.data[10] + a:matA.data[15] * a:matB.data[14]
	let l:result.data[15] = a:matA.data[12] * a:matB.data[3] + a:matA.data[13] * a:matB.data[7] + a:matA.data[14] * a:matB.data[11] + a:matA.data[15] * a:matB.data[15]

	return l:result
endfunction

function! Matrix.multiply_vector(matA, vec)
	let l:result = g:Vector.create(0.0, 0.0, 0.0)

	let l:result.x = a:matA.data[0] * a:vec.x + a:matA.data[1] * a:vec.y + a:matA.data[2] * a:vec.z  + a:matA.data[3] * 1.0
	let l:result.y = a:matA.data[4] * a:vec.x + a:matA.data[5] * a:vec.y + a:matA.data[6] * a:vec.z  + a:matA.data[7] * 1.0
	let l:result.z = a:matA.data[8] * a:vec.x + a:matA.data[9] * a:vec.y + a:matA.data[10] * a:vec.z  + a:matA.data[11] * 1.0
	let l:result.w = a:matA.data[12] * a:vec.x + a:matA.data[13] * a:vec.y + a:matA.data[14] * a:vec.z  + a:matA.data[15] * 1.0

	return l:result
endfunction

" ---------------------------------------------------------------- Utils ----------------------------------------------------------------
function! Matrix.print(matrix)
	echon a:matrix.data[0] . ' '
	echon a:matrix.data[1] . ' '
	echon a:matrix.data[2] . ' '
	echon a:matrix.data[3] . ' '
	echo  a:matrix.data[4] . ' '
	echon a:matrix.data[5] . ' '
	echon a:matrix.data[6] . ' '
	echon a:matrix.data[7] . ' '
	echo  a:matrix.data[8] . ' '
	echon a:matrix.data[9] . ' '
	echon a:matrix.data[10] . ' '
	echon a:matrix.data[11] . ' '
	echo  a:matrix.data[12] . ' '
	echon a:matrix.data[13] . ' '
	echon a:matrix.data[14] . ' '
	echon a:matrix.data[15] . ' '
endfunction
