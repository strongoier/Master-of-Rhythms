from PIL import Image
import math

def dec2bin(n, l):
    s = str(bin(n))
    return '0' * (l + 2 - len(s)) + s[2:]

mif = open('default.mif', 'w')
mif.write('WIDTH = 10;\n')
mif.write('DEPTH = 16384;\n')
mif.write('ADDRESS_RADIX = BIN;\n')
mif.write('DATA_RADIX = BIN;\n')
mif.write('CONTENT BEGIN\n')

for index in range(10):
    image = Image.open("default-" + str(index) + ".png").convert("RGBA")
    newImage = Image.new("RGBA", (50, 75))
    left = math.floor((newImage.size[0] - image.size[0]) / 2)
    top = math.floor((newImage.size[1] - image.size[1]) / 2)
    width = image.size[0]
    height = image.size[1]
    newWidth = newImage.size[0]
    newHeight = newImage.size[1]
    for i in range(top):
        for j in range(newWidth):
            newImage.putpixel((j, i), (255, 255, 255, 0))
    for i in range(top, top + height):
        for j in range(left):
            newImage.putpixel((j, i), (255, 255, 255, 0))
        for j in range(left, left + width):
            newImage.putpixel((j, i), image.getpixel((j - left, i - top)))
        for j in range(left + width, newWidth):
            newImage.putpixel((j, i), (255, 255, 255, 0))
    for i in range(top + height, newHeight):
        for j in range(newWidth):
            newImage.putpixel((j, i), (255, 255, 255, 0))
    newImage.thumbnail((20, 30))
    newImage.save("small-default-" + str(index) + ".png")

    s1 = dec2bin(index, 4)
    for x in range(32):
        s2 = dec2bin(x, 5)
        for y in range(32):
            s3 = dec2bin(y, 5)
            if x < 20 and y < 30:
                pixel = newImage.getpixel((x, y))
                r = dec2bin(pixel[0], 8)[:3]
                g = dec2bin(pixel[1], 8)[:3]
                b = dec2bin(pixel[2], 8)[:3]
                a = '0' if pixel[3] == 0 else '1'
                mif.write(s1 + s2 + s3 + ' : ' + r + g + b + a +';\n')
            else:
                mif.write(s1 + s2 + s3 + ' : 1111111110;\n')

for index in range(10, 16):
    s1 = dec2bin(index, 4)
    for x in range(32):
        s2 = dec2bin(x, 5)
        for y in range(32):
            s3 = dec2bin(y, 5)
            mif.write(s1 + s2 + s3 + ' : 0000000000;\n')

mif.write('END;\n')
mif.close()
