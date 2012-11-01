#!/usr/bin/env python
#
#  generatePathFromObj.py
#  Core3D
#
#  Created by CoreCode on 16.12.07.
#  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
#

import sys, random
from struct import *
from vecmath import *

try:
	from numpy import *
	from scipy.interpolate import splprep, splev
except:
	print "Error: NumPy or SkiPy not found"
	sys.exit(2)

x = []
y = []
z = []
SCALE = 1.0
reverse = 0
numberOfPoints = 3600
pointsPerUnit = 0
enemyPointsPerUnit = 0
splineOrder = 3
smoothnessParameter = 0.5
filename = ""
enemyPointNum = 1000

try:
	if (len(sys.argv)) == 1:							raise Exception('input', 'error')
	f = open(sys.argv[len(sys.argv) - 1], 'r')
	of = 0
	for i in range(1, len(sys.argv) - 1):
		if sys.argv[i].startswith("-p="):				smoothnessParameter = float(sys.argv[i][3:])
		elif sys.argv[i].startswith("-i="):				splineOrder = int(sys.argv[i][3:])
		elif sys.argv[i].startswith("-r="):				reverse = int(sys.argv[i][3:])
		elif sys.argv[i].startswith("-s="):				SCALE = float(sys.argv[i][3:])
		elif sys.argv[i].startswith("-f="):				numberOfPoints = int(sys.argv[i][3:])
		elif sys.argv[i].startswith("-u="):				pointsPerUnit = float(sys.argv[i][3:])
		elif sys.argv[i].startswith("-o="):				filename = sys.argv[i][3:]
		elif sys.argv[i].startswith("-n="):				enemyPointNum = int(sys.argv[i][3:])
		elif sys.argv[i].startswith("-k="):				enemyPointsPerUnit = float(sys.argv[i][3:])
		else:											raise Exception('input', 'error')
	if filename == "":									filename = sys.argv[len(sys.argv) - 1][:sys.argv[len(sys.argv) - 1].rfind(".")] + ".path"
except:
	print """Usage: generateInterpolatedPathFromObj [options] obj_file
Options:
 -s=<scale>		Scale all coordinates by <scale>
 -p=<smoothness>	Use <smoothness> as smoothness parameter (Default: 0.5)
 -i=<spline_order>	Use interpolation of order <spline_order> (Default: 3)
 -f=<num_points>	Produce <num_points> points (Default: 3600)
 -r=<reverse>	Interpret the spline as reverse (Default: 0)
 -u=<points_per_unit>	Produce <points_per_unit> points per unit of path length
 -o=<path_file>		Place the output path into <path_file>
 -n=<enemy_points>	Use <enemy_points> points for generating the enemy path
 -k=<enemy_points_per_unit>	Produce <enemy_points_per_unit> enemy points per unit of path length"""
	sys.exit(1)


of = open(filename, 'w')
lines = f.readlines()
if (lines[0].startswith("<?xml")):
	print "parsing allplan xml"
	for line in lines:
		if (line.startswith("<noi:GEO_POINT ")):
			line = line.replace("\"", "")
			c = line.split(" ")
			x.append(SCALE * float(c[1][2:]))
			y.append(SCALE * float(c[3][2:]))
			z.append(SCALE * -float(c[2][2:]))
else:
	print "parsing obj"
	for line in lines:
		c = line.split(" ")
		if c[0] == "v":
			x.append(SCALE * float(c[1]))
			y.append(SCALE * float(c[2]))
			z.append(SCALE * float(c[3]))

x.append(x[0])
y.append(y[0])
z.append(z[0])

print "input number of points"
print len(x)

if pointsPerUnit != 0 or enemyPointsPerUnit != 0:
	distance = 0
	for i in range(len(x)-1):
		prevvec = [x[i], y[i], z[i]]
		vec = [x[i+1], y[i+1], z[i+1]]
		distance += magnitude(substract(vec, prevvec))
	if pointsPerUnit != 0:
		numberOfPoints = distance * pointsPerUnit
		print "setting number of points to"
		print numberOfPoints
	if enemyPointsPerUnit != 0:
		enemyPointNum = distance * enemyPointsPerUnit
		print "setting enemy number of points to"
		print enemyPointNum


smooth = (enemyPointNum-math.sqrt(2*enemyPointNum),enemyPointNum+math.sqrt(2*enemyPointNum))


#out = ""
#for i in range(len(x)):
#	out += pack('fff', x[i], y[i], z[i])
#of.write(out)
#sys.exit(1)

	#TODO: dont use input values only for enemies
tckp,u = splprep([array(x), array(y), array(z)], s=3, k=1, nest=-1) # find the knot points

xnew, ynew, znew = splev(linspace(0, 1, numberOfPoints), tckp) # evaluate spline, including interpolated points



distSum = 0
minDist = 9999999
maxDist = 0
for i in range(len(xnew)-1):
	prevvec = [xnew[i], ynew[i], znew[i]]
	vec = [xnew[i+1], ynew[i+1], znew[i+1]]
	distance = magnitude(substract(vec, prevvec))
	distSum += distance
	if (distance < minDist): minDist = distance
	if (distance > maxDist): maxDist = distance
avgDist = distSum / (len(xnew)-1)



print "setting number of points for interpolated path to"
intPoints = len(x) * 2 
print intPoints
xint, yint, zint = splev(linspace(0, 1, intPoints), tckp) # evaluate spline, including interpolated points

print "distance min / avg / max"
print minDist
print avgDist
print maxDist

out = ""
if (reverse):
	for i in reversed(range(len(xnew))):
		out += pack('fff', xnew[i], ynew[i], znew[i])
else:
	for i in range(len(xnew)):
		out += pack('fff', xnew[i], ynew[i], znew[i])
of.write(out)


nearest = []

for i in range(len(xint)):
	nearest.append([1000, 0])
	for v in range(len(xnew)-1):
		vec1 = [xint[i], yint[i], zint[i]]
		vec2 = [xnew[v], ynew[v], znew[v]]
		dist = magnitude(substract(vec1, vec2))
		if (dist < nearest[i][0]):
			nearest[i] = [dist, v]

random.seed()
for v in range(12):
	xr = []
	yr = []
	zr = []
	fewrandom = []
	manyrandom = []

	for i in range((len(nearest) / 10)):
		fewrandom.append(random.uniform(-15,15))
	fewrandom.append(fewrandom[0])
	fewrandom.append(fewrandom[0])

	for i in range(len(nearest)):
		manyrandom.append(fewrandom[i / 10] * ((10 - (i % 10)) / 10.0) + fewrandom[i / 10 + 1] * ((i % 10) / 10.0))

	for i in range(len(nearest)):
		vec = [0,0,0]
		if (i > 0):
			prevtocurr = subtract([xnew[nearest[i][1]], ynew[nearest[i][1]], znew[nearest[i][1]]], [xnew[nearest[i-1][1]], ynew[nearest[i-1][1]], znew[nearest[i-1][1]]])
			vec = add(vec, prevtocurr)
		if (i < len(nearest) - 1):
			currtonext = subtract([xnew[nearest[i+1][1]], ynew[nearest[i+1][1]], znew[nearest[i+1][1]]], [xnew[nearest[i][1]], ynew[nearest[i][1]], znew[nearest[i][1]]])
			vec = add(vec, currtonext)
		perpendicular = normalize([vec[2], 0, -vec[0]])
		perpendicular = multiply(perpendicular, manyrandom[i])
		xr.append(xnew[nearest[i][1]] + perpendicular[0])
		yr.append(ynew[nearest[i][1]])
		zr.append(znew[nearest[i][1]] + perpendicular[2])

	xr.append(xr[0])
	yr.append(yr[0])
	zr.append(zr[0])
	tckp,u = splprep([array(xr), array(yr), array(zr)], s=(smooth[0] + smoothnessParameter * (smooth[1] - smooth[0])), k=splineOrder, nest=-1) # find the knot points
	xs, ys, zs = splev(linspace(0, 1, numberOfPoints), tckp) # evaluate spline, including interpolated points

	off = open(filename + str(v), 'w')
	out = ""
	if (reverse):
		for i in reversed(range(len(xnew))):
			out += pack('fff', xs[i], ys[i], zs[i])
	else:
		for i in range(len(xnew)):
			out += pack('fff', xs[i], ys[i], zs[i])
	off.write(out)
