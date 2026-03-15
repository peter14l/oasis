from PIL import Image
import sys

def make_transparent(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()

    newData = []
    # If the image is white icon on black background:
    # We want to keep white and make black transparent.
    # Alternatively, we could just copy the R channel to alpha and set all pixels to white, 
    # which is perfectly solid white with alpha varying by brightness.
    for item in datas:
        # Get grayscale value for alpha
        # item is (R, G, B, A)
        brightness = int(0.299 * item[0] + 0.587 * item[1] + 0.114 * item[2])
        # Set pixel to white, but alpha based on brightness
        newData.append((255, 255, 255, brightness))

    img.putdata(newData)
    img.save(output_path, "PNG")

if __name__ == "__main__":
    make_transparent(sys.argv[1], sys.argv[2])
