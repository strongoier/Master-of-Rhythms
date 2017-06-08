from PIL import Image

def dec2bin(n, l):
    s = str(bin(n))
    return '0' * (l + 2 - len(s)) + s[2:]

def createMif(filename):
    mif = open(filename + '.mif', 'w')
    mif.write('WIDTH = 9;\n')
    mif.write('DEPTH = 65536;\n')
    mif.write('ADDRESS_RADIX = BIN;\n')
    mif.write('DATA_RADIX = BIN;\n')
    mif.write('CONTENT BEGIN\n')
    return mif

def closeMif(mif):
    mif.write('END;\n')
    mif.close()

mif = createMif("background")
image = Image.open("V3.jpg").convert("RGB")
for i in range(256):
    s1 = dec2bin(i, 8)
    for j in range(256):
        s2 = dec2bin(j, 8)
        if i < 160 and j < 240:
            pixel = image.getpixel((i, j))
            r = dec2bin(pixel[0], 8)[:3]
            g = dec2bin(pixel[1], 8)[:3]
            b = dec2bin(pixel[2], 8)[:3]
            mif.write(s1 + s2 + ' : ' + r + g + b + ';\n')
        else:
            mif.write(s1 + s2 + ' : 000000000;\n')
closeMif(mif)
