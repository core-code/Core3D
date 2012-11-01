#
#  generateOctreeFromObj.rb
#  Core3D
#
#  Created by CoreCode on 16.11.07.
#  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see _MIT_LICENSE.txt
#

require './vecmath'

TEXTURING = 1
GENTEX = 0
MAX_FLOAT = 1e+308
MIN_FLOAT = -1e308
MAX_USHORT = 0xFFFF
MAX_FACES_PER_TREELEAF = 1000
MAX_RECURSION_DEPTH = 10
SCALE = 1.0
vertices = []
faces = []
normals = []
texcoords = []

def faceContent(f, i)
	if i == 0
		if f.count("/") == 0 then return f
		else return f[0...f.find("/")]
		end
	elsif i == 1
		if f.count("/") == 0 or f.count("//") == 1 then return 0
		else
			if f.count("/") == 2 then return f[f.find("/")+1...f.rfind("/")]
			else return f[f.find("/")+1..-1]
			end
		end
	else
		if f.count("/") != 2 then return 0
		else return f[f.rfind("/")+1..-1]
		end
	end
end

def calculateAABB(faces)
	mi = [MAX_FLOAT, MAX_FLOAT,MAX_FLOAT]
	ma =  [MIN_FLOAT, MIN_FLOAT, MIN_FLOAT]
	for face in faces
		for i in 0..2
			for v in 0..2
				ma[i] = max(ma[i], vertices[face[v]][i])
				mi[i] = min(mi[i], vertices[face[v]][i])
			end
		end
	end
	return mi,ma
end


print flip([1,2,3])