#
#  vecMath.rb
#  Core3D
#
#  Created by CoreCode on 14.11.07.
#  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see _MIT_LICENSE.txt
#

def normalize(a)
	d = magnitude(a)
	if d
		return [a[0]/d, a[1]/d, a[2]/d]
	else
		return a
	end
end
def crossProduct(a,b)
	return [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]
end
def substract(a,b)
	return [a[0]-b[0], a[1]-b[1], a[2]-b[2]]
end
def multiply(a,b)
	return [a[0]*b, a[1]*b, a[2]*b]
end
def add(a,b)
	return [a[0]+b[0], a[1]+b[1], a[2]+b[2]]
end
def magnitude(a)
	return Math.sqrt(a[0] ** 2 + a[1] ** 2 + a[2] ** 2)
end
def flip(a)
	return [-a[0], -a[1], -a[2]]
end
def rad(a)
	return a * Math::PI / 180.0
end
def deg(a)
	return a * 180.0 / Math::PI
end
def transform(v, m)
	return [m[0][0]*v[0] + m[0][1]*v[1] + m[0][2]*v[2], m[1][0]*v[0] + m[1][1]*v[1] + m[1][2]*v[2], m[2][0]*v[0] + m[2][1]*v[1] + m[2][2]*v[2]]
end
def mat_rot_x(angle)
	return [[1, 0, 0],   [0, Math.cos(angle), -Math.sin(angle)],   [0, Math.sin(angle), Math.cos(angle)]]
end
def mat_rot_y(angle)
	return [[Math.cos(angle), 0, Math.sin(angle)],   [0, 1, 0],   [-Math.sin(angle), 0, Math.cos(angle)]]
end
def mat_rot_z(angle)
	return [[Math.cos(angle), -Math.sin(angle), 0],   [Math.sin(angle), Math.cos(angle), 0],   [0, 0, 1]]
end
def mat_mul(m1, m2)
	res = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]
	for r in 0..2
		for s in 0..2
			for i in 0..2
				res[r][s] = res[r][s] + m1[r][i] * m2[i][s]
			end
		end
	end
end