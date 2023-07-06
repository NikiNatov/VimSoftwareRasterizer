let Vector = {}

" ------------------------------------------------------------- Constructor -------------------------------------------------------------
function! Vector.create(x, y, z)
	let l:instance = #{ x: a:x, y: a:y, z: a:z, w: 1.0 }

	function! l:instance.length()
		return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
	endfunction

	return l:instance
endfunction

" -------------------------------------------------------- Arithmetic operations --------------------------------------------------------
function! Vector.add(vecA, vecB)
	return self.create(a:vecA.x + a:vecB.x, a:vecA.y + a:vecB.y, a:vecA.z + a:vecB.z)
endfunction

function! Vector.add_scalar(vec, scalar)
	return self.create(a:vec.x + a:scalar, a:vec.y + a:scalar, a:vec.z + a:scalar)
endfunction

function! Vector.subtract(vecA, vecB)
	return self.create(a:vecA.x - a:vecB.x, a:vecA.y - a:vecB.y, a:vecA.z - a:vecB.z)
endfunction

function! Vector.subtract_scalar(vec, scalar)
	return self.create(a:vec.x - a:scalar, a:vec.y - a:scalar, a:vec.z - a:scalar)
endfunction

function! Vector.multiply(vecA, vecB)
	return self.create(a:vecA.x * a:vecB.x, a:vecA.y * a:vecB.y, a:vecA.z * a:vecB.z)
endfunction

function! Vector.multiply_scalar(vec, scalar)
	return self.create(a:vec.x * a:scalar, a:vec.y * a:scalar, a:vec.z * a:scalar)
endfunction

function! Vector.divide(vecA, vecB)
	return self.create(a:vecA.x / a:vecB.x, a:vecA.y / a:vecB.y, a:vecA.z / a:vecB.z)
endfunction

function! Vector.divide_scalar(vec, scalar)
	return self.create(a:vec.x / a:scalar, a:vec.y / a:scalar, a:vec.z / a:scalar)
endfunction

" ------------------------------------------------------------- Functions ---------------------------------------------------------------
function! Vector.normalized(vec)
	let length = a:vec.length()
	return self.create(a:vec.x / length, a:vec.y / length, a:vec.z / length)
endfunction

function! Vector.dot(vecA, vecB)
	return a:vecA.x * a:vecB.x + a:vecA.y * a:vecB.y + a:vecA.z * a:vecB.z
endfunction

function! Vector.cross(vecA, vecB)
	return self.create(a:vecA.y * a:vecB.z - a:vecA.z * a:vecB.y, a:vecA.z * a:vecB.x - a:vecA.x * a:vecB.z, a:vecA.x * a:vecB.y - a:vecA.y * a:vecB.x)
endfunction

function! Vector.reflect(vec, normal)
	let vecDotNormal = self.dot(a:vec, a:normal)
	return self.subtract(a:vec, self.multiply_scalar(a:normal, 2 * vecDotNormal))
endfunction
