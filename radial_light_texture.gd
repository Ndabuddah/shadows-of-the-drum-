@tool
extends EditorScript

# Script to generate a radial light texture for Hollow Knight-style lighting
# Run this script in the editor to create the texture

func _run():
	var size = 512
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2, size / 2)
	var max_radius = size / 2
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			var normalized_distance = distance / max_radius
			
			# Create smooth radial falloff
			var alpha = 0.0
			if normalized_distance <= 1.0:
				# Smooth falloff curve for natural light distribution
				alpha = 1.0 - pow(normalized_distance, 1.5)
				alpha = smoothstep(0.0, 1.0, alpha)
			
			# Set pixel with warm white color and calculated alpha
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	
	# Save the texture
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	var save_path = "res://radial_light_texture.tres"
	ResourceSaver.save(texture, save_path)
	
	print("Radial light texture created at: ", save_path)