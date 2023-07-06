source graphics/color.vim

let PIXEL_SOLID_SHADE = '█'
let PIXEL_DARK_SHADE = '▓'
let PIXEL_MEDIUM_SHADE = '▒'
let PIXEL_LIGHT_SHADE = '░'

let Renderer = {}

" ------------------------------------------------------------- Constructor -------------------------------------------------------------
function! Renderer.create(screenWidth, screenHeight)
	let l:instance = #{ 
			\ screenWidth: a:screenWidth,
			\ screenHeight: a:screenHeight,
			\ screenBuffer: [],
			\ clearColor: g:Color.create(128, 128, 128),
			\ projectionMatrix: g:Matrix.create(),
			\ viewMatrix: g:Matrix.create(),
			\ cameraPosition: g:Vector.create(0.0, 0.0, 0.0),
			\ drawCommands: [],
			\ isWireframe: 0
			\ }

	function! l:instance.initialize()
		" Initialize the screen buffer
		let self.screenBuffer = []
		for i in range(self.screenHeight)
			call add(self.screenBuffer, [])
			for j in range(self.screenWidth)
				call add(self.screenBuffer[i], #{ symbol: g:PIXEL_SOLID_SHADE, color: self.clearColor })
			endfor
		endfor
	endfunction

	function! l:instance.begin_scene(camera)
		let self.projectionMatrix = a:camera.projectionMatrix
		let self.viewMatrix = a:camera.viewMatrix
		let self.cameraPosition = a:camera.position
		let self.drawCommands = []
	endfunction

	function! l:instance.clear_screen()
		for i in range(self.screenHeight)
			for j in range(self.screenWidth)
				let self.screenBuffer[i][j].symbol = g:PIXEL_SOLID_SHADE
				let self.screenBuffer[i][j].color = self.clearColor
			endfor
		endfor
	endfunction

	function! l:instance.submit_mesh(mesh, transform, color)
		call add(self.drawCommands, #{ mesh: a:mesh, transform: a:transform, color: a:color })
	endfunction

	function! l:instance.flush()
		let l:rasterizedTriangles = []
		for drawCmd in self.drawCommands
			for triangle in drawCmd.mesh.triangles
				" Transform to world space
				let l:triWorldSpace = g:Triangle.create(
					\ g:Vertex.create(g:Matrix.multiply_vector(drawCmd.transform, triangle.v0.position)), 
					\ g:Vertex.create(g:Matrix.multiply_vector(drawCmd.transform, triangle.v1.position)),
					\ g:Vertex.create(g:Matrix.multiply_vector(drawCmd.transform, triangle.v2.position))
					\ )

				" Calculate normal vector
				let l:line1 = g:Vector.subtract(l:triWorldSpace.v1.position, l:triWorldSpace.v0.position)
				let l:line2 = g:Vector.subtract(l:triWorldSpace.v2.position, l:triWorldSpace.v0.position)
				let l:normal = g:Vector.normalized(g:Vector.cross(l:line1, l:line2))

				" Face culling
				if g:Vector.dot(g:Vector.subtract(self.cameraPosition, l:triWorldSpace.v0.position), l:normal) > 0.0
					" Calculate lighting
					let l:lightDir = g:Vector.normalized(g:Vector.create(0.68, -0.93, -2.0))
					let l:dp = g:Vector.dot(g:Vector.multiply_scalar(l:lightDir, -1.0), l:normal)
					if l:dp < 0.1
						let l:dp = 0.1
					endif

					let l:finalColor = g:Color.create(float2nr(drawCmd.color.r * l:dp), float2nr(drawCmd.color.g * l:dp), float2nr(drawCmd.color.b * l:dp))

					if l:dp >= 0.1 && l:dp < 0.25
						let l:finalSymbol = g:PIXEL_LIGHT_SHADE
					elseif l:dp >= 0.25 && l:dp < 0.50
						let l:finalSymbol = g:PIXEL_MEDIUM_SHADE
					elseif l:dp >= 0.50 && l:dp < 0.75
						let l:finalSymbol = g:PIXEL_DARK_SHADE
					elseif l:dp >= 0.75 && l:dp < 1.0
						let l:finalSymbol = g:PIXEL_SOLID_SHADE
					endif

					" Transform to view space
					let l:triViewSpace = g:Triangle.create(
						\ g:Vertex.create(g:Matrix.multiply_vector(self.viewMatrix, l:triWorldSpace.v0.position)), 
						\ g:Vertex.create(g:Matrix.multiply_vector(self.viewMatrix, l:triWorldSpace.v1.position)),
						\ g:Vertex.create(g:Matrix.multiply_vector(self.viewMatrix, l:triWorldSpace.v2.position))
						\ )

					" Do Z-clipping here before we lose information about depth after projecting the vertices
					let l:clippedTriangles = self._clip_triangle(g:Vector.create(0.0, 0.0, -0.1), g:Vector.create(0.0, 0.0, -1.0), l:triViewSpace)

					for clippedTriangle in l:clippedTriangles
						" Project vertices
						let l:triProjected = g:Triangle.create(
							\ g:Vertex.create(g:Matrix.multiply_vector(self.projectionMatrix, clippedTriangle.v0.position)), 
							\ g:Vertex.create(g:Matrix.multiply_vector(self.projectionMatrix, clippedTriangle.v1.position)),
							\ g:Vertex.create(g:Matrix.multiply_vector(self.projectionMatrix, clippedTriangle.v2.position))
							\ )

						
						" Do perspective division
						let l:triProjected.v0.position = g:Vector.divide_scalar(l:triProjected.v0.position, l:triProjected.v0.position.w)
						let l:triProjected.v1.position = g:Vector.divide_scalar(l:triProjected.v1.position, l:triProjected.v1.position.w)
						let l:triProjected.v2.position = g:Vector.divide_scalar(l:triProjected.v2.position, l:triProjected.v2.position.w)

						" Map to pixel coords
						let l:triProjected.v0.position = g:Vector.add(l:triProjected.v0.position, g:Vector.create(1.0, 1.0, 0.0))
						let l:triProjected.v1.position = g:Vector.add(l:triProjected.v1.position, g:Vector.create(1.0, 1.0, 0.0))
						let l:triProjected.v2.position = g:Vector.add(l:triProjected.v2.position, g:Vector.create(1.0, 1.0, 0.0))

						let l:triProjected.v0.position = g:Vector.multiply(l:triProjected.v0.position, g:Vector.create(0.5 * self.screenWidth, 0.5 * self.screenHeight, 1.0))
						let l:triProjected.v1.position = g:Vector.multiply(l:triProjected.v1.position, g:Vector.create(0.5 * self.screenWidth, 0.5 * self.screenHeight, 1.0))
						let l:triProjected.v2.position = g:Vector.multiply(l:triProjected.v2.position, g:Vector.create(0.5 * self.screenWidth, 0.5 * self.screenHeight, 1.0))

						call add(l:rasterizedTriangles, #{ triangle: l:triProjected, color: l:finalColor, symbol: l:finalSymbol })
					endfor
					
				endif
			endfor
		endfor

		" Sort triangles from back to front
		function! SortTriangles(t1, t2)
			let l:z1 = (a:t1.triangle.v0.position.z + a:t1.triangle.v1.position.z + a:t1.triangle.v2.position.z) / 3.0
			let l:z2 = (a:t2.triangle.v0.position.z + a:t2.triangle.v1.position.z + a:t2.triangle.v2.position.z) / 3.0
			return l:z1 == l:z2 ? 0 : l:z1 < l:z2 ? 1 : -1
		endfunction

		for entry in sort(l:rasterizedTriangles, 'SortTriangles')
			" Do screen space clipping
			let l:triangleQueue = [entry]
			for i in range(4)
				let l:newTrianglesCount = len(l:triangleQueue)
				while l:newTrianglesCount > 0
					" Take the next triangle in the queue
					let l:currentEntry = l:triangleQueue[0]
					let l:triangleQueue = l:triangleQueue[1:]
					let l:newTrianglesCount = l:newTrianglesCount - 1

					if i == 0
						let l:clippedTriangles = self._clip_triangle(g:Vector.create(0.0, 0.0, 0.0), g:Vector.create(0.0, 1.0, 0.0), l:currentEntry.triangle)
					elseif i == 1
						let l:clippedTriangles = self._clip_triangle(g:Vector.create(0.0, self.screenHeight - 1.0, 0.0), g:Vector.create(0.0, -1.0, 0.0), l:currentEntry.triangle)
					elseif i == 2
						let l:clippedTriangles = self._clip_triangle(g:Vector.create(0.0, 0.0, 0.0), g:Vector.create(1.0, 0.0, 0.0), l:currentEntry.triangle)
					elseif i == 3
						let l:clippedTriangles = self._clip_triangle(g:Vector.create(self.screenWidth - 1.0, 0.0, 0.0), g:Vector.create(-1.0, 0.0, 0.0), l:currentEntry.triangle)
					endif

					" Add the new triangles to the queue
					for clippedTri in l:clippedTriangles
						call add(l:triangleQueue, #{ triangle: clippedTri, color: l:currentEntry.color, symbol: l:currentEntry.symbol })
					endfor
				endwhile
			endfor

			" Rasterize
			for entry in l:triangleQueue
				let l:x0 = entry.triangle.v0.position.x
				let l:y0 = self.screenHeight - entry.triangle.v0.position.y
				let l:x1 = entry.triangle.v1.position.x
				let l:y1 = self.screenHeight - entry.triangle.v1.position.y
				let l:x2 = entry.triangle.v2.position.x
				let l:y2 = self.screenHeight - entry.triangle.v2.position.y

				if !self.isWireframe
					call self._draw_filled_triangle(l:x0, l:y0, l:x1, l:y1, l:x2, l:y2, entry.color, entry.symbol)
				else
					call self._draw_wireframe_triangle(l:x0, l:y0, l:x1, l:y1, l:x2, l:y2, entry.color, entry.symbol)
				endif
			endfor
			
		endfor
	endfunction

	function! l:instance.present()
		" Clear all lines in the buffer
		execute "%d"

		" Render the new contents
		let l:lines = []
		for i in range(self.screenHeight)
			let l:line = ''
			for j in range(self.screenWidth)
				let l:line = l:line . self.screenBuffer[i][j].symbol
			endfor

			call add(l:lines, l:line)
		endfor

		call append(0, l:lines)

		for i in range(self.screenHeight)
			" Set colors
			for j in range(self.screenWidth)
				call prop_add(i + 1, byteidx(l:line, j) + 1, { 'type': self.screenBuffer[i][j].color.get_hex_string() })
			endfor
		endfor

		redraw
	endfunction

	function! l:instance._set_pixel(x, y, color, symbol)
		if a:x < 0 || a:x > self.screenWidth - 1 || a:y < 0 || a:y > self.screenHeight - 1
			return
		endif

		let self.screenBuffer[a:y][a:x].symbol = a:symbol
		let self.screenBuffer[a:y][a:x].color = a:color
	endfunction

	" Bresenham's line algorithm: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
	function! l:instance._draw_line(x0, y0, x1, y1, color, symbol)
		let l:y0 = float2nr(a:y0)
		let l:x0 = float2nr(a:x0)
		let l:y1 = float2nr(a:y1)
		let l:x1 = float2nr(a:x1)

    		let l:dx = abs(l:x1 - l:x0)
    		let l:dy = -abs(l:y1 - l:y0)
    		let l:sx = l:x0 < l:x1 ? 1 : -1
    		let l:sy = l:y0 < l:y1 ? 1 : -1
    		let l:error = l:dx + l:dy
    
    		let l:currentX = l:x0
    		let l:currentY = l:y0

    		while 1
        		call self._set_pixel(l:currentX, l:currentY, a:color, a:symbol)

        		if l:currentX == l:x1 && l:currentY == l:y1
				break
			endif

        		let l:e2 = 2 * l:error
        		if l:e2 >= l:dy
            			if l:currentX == l:x1
		    			break
	    			endif

            			let l:error = l:error + l:dy
            			let l:currentX = l:currentX + l:sx
        		endif

        		if l:e2 <= l:dx
            			if l:currentY == l:y1
		    			break
	    			endif

            			let l:error = l:error + l:dx
            			let l:currentY = l:currentY + l:sy
        		endif
    		endwhile
	endfunction

	function! l:instance._draw_wireframe_triangle(x0, y0, x1, y1, x2, y2, color, symbol)
		call self._draw_line(a:x0, a:y0, a:x1, a:y1, a:color, a:symbol)
		call self._draw_line(a:x0, a:y0, a:x2, a:y2, a:color, a:symbol)
		call self._draw_line(a:x1, a:y1, a:x2, a:y2, a:color, a:symbol)
	endfunction

	" Algorithm: https://gabrielgambetta.com/computer-graphics-from-scratch/07-filled-triangles.html#drawing-filled-triangles
	function! l:instance._draw_filled_triangle(x0, y0, x1, y1, x2, y2, color, symbol)
		let l:y0 = float2nr(a:y0)
		let l:x0 = float2nr(a:x0)
		let l:y1 = float2nr(a:y1)
		let l:x1 = float2nr(a:x1)
		let l:y2 = float2nr(a:y2)
		let l:x2 = float2nr(a:x2)

		" Sort the points so that y0 <= y1 <= y2
		if l:y1 < l:y0
			let l:temp = l:y0
			let l:y0 = l:y1
			let l:y1 = l:temp

			let l:temp = l:x0
			let l:x0 = l:x1
			let l:x1 = l:temp
		endif
		if l:y2 < l:y0
			let l:temp = l:y0
			let l:y0 = l:y2
			let l:y2 = l:temp

			let l:temp = l:x0
			let l:x0 = l:x2
			let l:x2 = l:temp
		endif
		if l:y2 < l:y1
			let l:temp = l:y1
			let l:y1 = l:y2
			let l:y2 = l:temp

			let l:temp = l:x1
			let l:x1 = l:x2
			let l:x2 = l:temp
		endif

		" Compute x step for each side of the triangle
		let l:distY0Y1 = l:y1 - l:y0
		let l:distX0X1 = l:x1 - l:x0 + 0.0000000001
		let l:stepX0X1 = 0
		if l:distY0Y1 != 0
			let l:stepX0X1 = l:distX0X1 / abs(l:distY0Y1)
		endif

		let l:distY0Y2 = l:y2 - l:y0
		let l:distX0X2 = l:x2 - l:x0 + 0.0000000001
		let l:stepX0X2 = 0
		if l:distY0Y2 != 0
			let l:stepX0X2 = l:distX0X2 / abs(l:distY0Y2)
		endif

		let l:distY1Y2 = l:y2 - l:y1
		let l:distX1X2 = l:x2 - l:x1 + 0.0000000001
		let l:stepX1X2 = 0
		if l:distY1Y2 != 0
			let l:stepX1X2 = l:distX1X2 / abs(l:distY1Y2)
		endif

		" Rasterize top half
		if l:distY0Y1 != 0
			for i in range(l:y0, l:y1)
				let l:xStart = float2nr(l:x0 + (i - l:y0) * l:stepX0X1)
				let l:xEnd = float2nr(l:x0 + (i - l:y0) * l:stepX0X2)

				" Swap if needed
				if l:xStart > l:xEnd
					let l:temp = l:xStart
					let l:xStart = l:xEnd
					let l:xEnd = l:temp
				endif

				" Draw pixels
				for j in range(l:xStart, l:xEnd - 1)
					call self._set_pixel(j, i, a:color, a:symbol)
				endfor
			endfor
		endif

		" Rasterize bottom half
		if l:distY1Y2 != 0
			for i in range(l:y1, l:y2)
				let l:xStart = float2nr(l:x1 + (i - l:y1) * l:stepX1X2)
				let l:xEnd = float2nr(l:x0 + (i - l:y0) * l:stepX0X2)

				" Swap if needed
				if l:xStart > l:xEnd
					let l:temp = l:xStart
					let l:xStart = l:xEnd
					let l:xEnd = l:temp
				endif

				" Draw pixels
				for j in range(l:xStart, l:xEnd - 1)
					call self._set_pixel(j, i, a:color, a:symbol)
				endfor
			endfor
		endif
	endfunction

	" Algorithm: https://github.com/OneLoneCoder/Javidx9/blob/master/ConsoleGameEngine/BiggerProjects/Engine3D/OneLoneCoder_olcEngine3D_Part3.cpp
	function! l:instance._clip_triangle(planePoint, planeNormal, triangle)

		" Returns signed shortest distance from a point to a plane, assumes that planeNormal is normalized
		function! SignedDistanceToPlane(planePoint, planeNormal, point)
			return a:planeNormal.x * a:point.x + a:planeNormal.y * a:point.y + a:planeNormal.z * a:point.z - g:Vector.dot(a:planeNormal, a:planePoint)
		endfunction

		" Returns intersection point of a line and a plane, assumes that planeNormal is normalized
		function! IntersectPlane(planePoint, planeNormal, lineStartPoint, lineEndPoint)
			let l:d = -g:Vector.dot(a:planeNormal, a:planePoint)
			let l:ad = g:Vector.dot(a:lineStartPoint, a:planeNormal)
			let l:bd = g:Vector.dot(a:lineEndPoint, a:planeNormal)
			let l:t = (-l:d - l:ad) / (l:bd - l:ad)
		        let l:lineStartToEnd = g:Vector.subtract(a:lineEndPoint, a:lineStartPoint)
			let l:lineToIntersect = g:Vector.multiply_scalar(l:lineStartToEnd, l:t)
			return g:Vector.add(a:lineStartPoint, l:lineToIntersect)
		endfunction

		let l:planeNormal = g:Vector.normalized(a:planeNormal)

		let l:insideVertices = []
		let l:outsideVertices = []

		" Get signed distance of each vertex of the triangle to plane
		let l:d0 = SignedDistanceToPlane(a:planePoint, l:planeNormal, a:triangle.v0.position)
		let l:d1 = SignedDistanceToPlane(a:planePoint, l:planeNormal, a:triangle.v1.position)
		let l:d2 = SignedDistanceToPlane(a:planePoint, l:planeNormal, a:triangle.v2.position)

		if l:d0 >= 0
			call add(l:insideVertices, a:triangle.v0)
		else
			call add(l:outsideVertices, a:triangle.v0)
		endif

		if l:d1 >= 0
			call add(l:insideVertices, a:triangle.v1)
		else
			call add(l:outsideVertices, a:triangle.v1)
		endif

		if l:d2 >= 0
			call add(l:insideVertices, a:triangle.v2)
		else
			call add(l:outsideVertices, a:triangle.v2)
		endif

		let l:numInsideVertices = len(l:insideVertices)
		let l:numOutsideVertices = len(l:outsideVertices)

		if l:numInsideVertices == 0
			" Clip the whole triangle
			return []
		endif

		if l:numInsideVertices == 3
			" Return the original triangle
			return [a:triangle]
		endif

		if l:numInsideVertices == 1 && l:numOutsideVertices == 2
			" Original triangle becomes just a smaller triangle
			let l:intersectPointA = IntersectPlane(a:planePoint, l:planeNormal, l:insideVertices[0].position, l:outsideVertices[0].position)
			let l:intersectPointB = IntersectPlane(a:planePoint, l:planeNormal, l:insideVertices[0].position, l:outsideVertices[1].position)
			return [g:Triangle.create(l:insideVertices[0], g:Vertex.create(l:intersectPointA), g:Vertex.create(l:intersectPointB))]
		endif

		if l:numInsideVertices == 2 && l:numOutsideVertices == 1
			" Original triangle becomes a quad that we need to split into 2 new triangles
			let l:intersectPointA = IntersectPlane(a:planePoint, l:planeNormal, l:insideVertices[0].position, l:outsideVertices[0].position)
			let l:triangleA = g:Triangle.create(l:insideVertices[0], l:insideVertices[1], g:Vertex.create(l:intersectPointA))

			let l:intersectPointB = IntersectPlane(a:planePoint, l:planeNormal, l:insideVertices[1].position, l:outsideVertices[0].position)
			let l:triangleB = g:Triangle.create(l:insideVertices[1], l:triangleA.v2, g:Vertex.create(l:intersectPointB))

			return [l:triangleA, l:triangleB]
		endif

	endfunction

	return l:instance
endfunction
