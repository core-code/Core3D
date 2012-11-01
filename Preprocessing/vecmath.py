#
#  vecmath.py
#  Core3D
#
#  Created by CoreCode on 14.11.07.
#  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
#


import math


def normalize(a):
	d = magnitude(a)
	if d: return [a[0]/d, a[1]/d, a[2]/d]
	else: return a
def crossProduct(a,b):
	return [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]
def substract(a,b):
	return [a[0]-b[0], a[1]-b[1], a[2]-b[2]]
def multiply(a,b):
	return [a[0]*b, a[1]*b, a[2]*b]
def add(a,b):
	return [a[0]+b[0], a[1]+b[1], a[2]+b[2]]
def magnitude(a):
	return math.sqrt(a[0] ** 2 + a[1] ** 2 + a[2] ** 2)
def flip(a):
	return [-a[0], -a[1], -a[2]]
def rad(a):
	return a * math.pi / 180.0
def deg(a):
	return a * 180.0 / math.pi
def transform(v, m):
	return [m[0][0]*v[0] + m[0][1]*v[1] + m[0][2]*v[2], m[1][0]*v[0] + m[1][1]*v[1] + m[1][2]*v[2], m[2][0]*v[0] + m[2][1]*v[1] + m[2][2]*v[2]]
def mat_rot_x(angle):
	return [[1, 0, 0], [0, math.cos(angle), -math.sin(angle)], [0, math.sin(angle), math.cos(angle)]]
def mat_rot_y(angle):
	return [[math.cos(angle), 0, math.sin(angle)], [0, 1, 0],[-math.sin(angle), 0, math.cos(angle)]]
def mat_rot_z(angle):
	return [[math.cos(angle), -math.sin(angle), 0], [math.sin(angle), math.cos(angle), 0], [0, 0, 1]]
def mat_mul(m1, m2):
	res = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]
	for r in range(0, 3):
		for s in range(0, 3):
			for i in range(0, 3):
				res[r][s] = res[r][s] + m1[r][i] * m2[i][s]