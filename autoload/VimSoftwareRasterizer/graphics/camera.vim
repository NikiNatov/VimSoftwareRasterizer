let Camera = {}

" ------------------------------------------------------------- Camera -------------------------------------------------------------
function! Camera.create(fov, aspectRatio)
	let l:instance = #{ 
			\ projectionMatrix: g:Matrix.projection(a:fov, a:aspectRatio, 0.1, 1000.0),
			\ viewMatrix: g:Matrix.identity(),
			\ position: g:Vector.create(0.0, 0.0, 0.0),
			\ rotation: g:Vector.create(0.0, 0.0, 0.0),
			\ rotationSpeed: 20.0,
			\ moveSpeed: 5.0
			\ }

	function! l:instance.update_camera(dt)
		let input = getchar(0)
		if input == 105 " i
			let self.rotation.x = self.rotation.x + self.rotationSpeed * a:dt
		elseif input == 107 " k
			let self.rotation.x = self.rotation.x - self.rotationSpeed * a:dt
		elseif input == 106 " j
			let self.rotation.y = self.rotation.y + self.rotationSpeed * a:dt
		elseif input == 108 " l
			let self.rotation.y = self.rotation.y - self.rotationSpeed * a:dt
		endif

		" Calculate view matrix
		let l:cosPitch = cos(self.rotation.x * 3.14 / 180.0)
    		let l:sinPitch = sin(self.rotation.x * 3.14 / 180.0)
    		let l:cosYaw = cos(self.rotation.y * 3.14 / 180.0)
    		let l:sinYaw = sin(self.rotation.y * 3.14 / 180.0)
 
    		let l:xAxis = g:Vector.normalized(g:Vector.create(l:cosYaw, 0.0, -l:sinYaw))
    		let l:yAxis = g:Vector.normalized(g:Vector.create(l:sinYaw * l:sinPitch, l:cosPitch, l:cosYaw * l:sinPitch))
    		let l:zAxis = g:Vector.normalized(g:Vector.create(l:sinYaw * l:cosPitch, -l:sinPitch, l:cosPitch * l:cosYaw))

		if input == 119 " w
			let self.position = g:Vector.subtract(self.position, g:Vector.multiply_scalar(l:zAxis, self.moveSpeed * a:dt))
		elseif input == 115 " s
			let self.position = g:Vector.add(self.position, g:Vector.multiply_scalar(l:zAxis, self.moveSpeed * a:dt))
		elseif input == 97 " a
			let self.position = g:Vector.subtract(self.position, g:Vector.multiply_scalar(l:xAxis, self.moveSpeed * a:dt))
		elseif input == 100 " d
			let self.position = g:Vector.add(self.position, g:Vector.multiply_scalar(l:xAxis, self.moveSpeed * a:dt))
		elseif input == 113 " q
			let self.position = g:Vector.add(self.position, g:Vector.create(0.0, self.moveSpeed * a:dt, 0.0))
		elseif input == 101 " e
			let self.position = g:Vector.subtract(self.position, g:Vector.create(0.0, self.moveSpeed * a:dt, 0.0))
		endif

		let self.viewMatrix = g:Matrix.from_column_vectors(
					\ g:Vector.create(l:xAxis.x, l:yAxis.x, l:zAxis.x),
					\ g:Vector.create(l:xAxis.y, l:yAxis.y, l:zAxis.y),
					\ g:Vector.create(l:xAxis.z, l:yAxis.z, l:zAxis.z),
					\ g:Vector.create(-g:Vector.dot(l:xAxis, self.position), -g:Vector.dot(l:yAxis, self.position), -g:Vector.dot(l:zAxis, self.position))
					\ )
	endfunction

	return l:instance
endfunction
