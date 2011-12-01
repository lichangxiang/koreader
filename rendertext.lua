glyphcache_max_memsize = 256*1024 -- 256kB glyphcache
glyphcache_current_memsize = 0
glyphcache = {}
glyphcache_max_age = 4096
function glyphcacheclaim(size)
	if(size > glyphcache_max_memsize) then
		error("too much memory claimed")
		return false
	end
	while glyphcache_current_memsize + size > glyphcache_max_memsize do
		for k, _ in pairs(glyphcache) do
			if glyphcache[k].age > 0 then
				glyphcache[k].age = glyphcache[k].age - 1
			else
				glyphcache_current_memsize = glyphcache_current_memsize - glyphcache[k].size
				glyphcache[k] = nil
			end
		end
	end
	glyphcache_current_memsize = glyphcache_current_memsize + size
	return true
end
function getglyph(face, facehash, charcode)
	local hash = glyphcachehash(facehash, charcode)
	if glyphcache[hash] == nil then
		print("render glyph")
		local glyph = face:renderGlyph(charcode)
		local size = glyph.bb:getWidth() * glyph.bb:getHeight() / 2 + 32
		print("cache claim")
		glyphcacheclaim(size);
		glyphcache[hash] = {
			age = glyphcache_max_age,
			size = size,
			g = glyph
		}
	else
		glyphcache[hash].age = glyphcache_max_age
	end
	return glyphcache[hash].g
end
function glyphcachehash(face, charcode)
	return face..'_'..charcode;
end
function clearglyphcache()
	glyphcache = {}
end

function renderUtf8Text(x, y, face, facehash, text)
	local pen_x = 0
	for uchar in string.gfind(text, "([%z\1-\127\194-\244][\128-\191]*)") do
		local glyph = getglyph(face, facehash, util.utf8charcode(uchar))
		fb:blitFrom(glyph.bb, x + pen_x + glyph.l, y - glyph.t, 0, 0, glyph.bb:getWidth(), glyph.bb:getHeight())
		print(uchar, x + pen_x + glyph.l, y - glyph.t, glyph.bb:getWidth(), glyph.bb:getHeight())
		pen_x = pen_x + glyph.ax
	end
end

