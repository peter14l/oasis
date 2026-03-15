import sys
from PIL import Image, ImageDraw

def process_icon(input_path, color_out, mono_out):
    img = Image.open(input_path).convert("RGB")
    width, height = img.size
    
    # Create the gradient background
    bg = Image.new("RGBA", (width, height))
    draw = ImageDraw.Draw(bg)
    color1 = (0, 210, 255) # vibrant cyan
    color2 = (58, 123, 213) # deep blue
    for y in range(height):
        r = int(color1[0] + (color2[0] - color1[0]) * y / height)
        g = int(color1[1] + (color2[1] - color1[1]) * y / height)
        b = int(color1[2] + (color2[2] - color1[2]) * y / height)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))
        
    mono = Image.new("RGBA", (width, height), (0,0,0,0))
    colored = bg.copy()
    
    pixels = img.load()
    mono_pixels = mono.load()
    colored_pixels = colored.load()
    
    for y in range(height):
        for x in range(width):
            r, g, b = pixels[x, y]
            brightness = sum([r,g,b])/3
            
            # Since the original is a dark shape on white background:
            # 255 brightness = background (alpha 0 for mono)
            # 0 brightness = shape foreground (alpha 255 for mono, coloring it white)
            alpha = int(255 - brightness)
            
            # Set mono to pure white with varying alpha based on darkness
            if alpha > 0:
                mono_pixels[x, y] = (255, 255, 255, alpha)
                
                # Composite the white onto the gradient for the colored image
                bgr, bgg, bgb, bga = colored_pixels[x, y]
                
                # standard alpha compositing over an opaque background
                out_r = int((255 * alpha + bgr * (255 - alpha)) / 255)
                out_g = int((255 * alpha + bgg * (255 - alpha)) / 255)
                out_b = int((255 * alpha + bgb * (255 - alpha)) / 255)
                
                colored_pixels[x, y] = (out_r, out_g, out_b, 255)
                
    mono.save(mono_out, "PNG")
    colored.save(color_out, "PNG")
    print(f"Saved {color_out} and {mono_out}")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python script.py <input> <color_out> <mono_out>")
        sys.exit(1)
    process_icon(sys.argv[1], sys.argv[2], sys.argv[3])
