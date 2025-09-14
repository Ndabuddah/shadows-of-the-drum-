extends PointLight2D

# Hollow Knight-style lantern script
# Adds subtle flickering and dynamic lighting effects

@export var base_energy: float = 1.2
@export var flicker_intensity: float = 0.15
@export var flicker_speed: float = 8.0
@export var pulse_intensity: float = 0.1
@export var pulse_speed: float = 2.0

var time_passed: float = 0.0
var noise: FastNoiseLite

func _ready():
	# Initialize noise for organic flickering
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.5
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Set initial properties
	energy = base_energy

func _process(delta):
	time_passed += delta
	
	# Create subtle flickering effect
	var flicker_noise = noise.get_noise_1d(time_passed * flicker_speed)
	var flicker_offset = flicker_noise * flicker_intensity
	
	# Add gentle pulsing
	var pulse_offset = sin(time_passed * pulse_speed) * pulse_intensity
	
	# Apply combined effects
	energy = base_energy + flicker_offset + pulse_offset
	
	# Ensure energy stays within reasonable bounds
	energy = clamp(energy, base_energy * 0.7, base_energy * 1.3)
	
	# Subtle color temperature variation
	var temp_variation = sin(time_passed * 0.5) * 0.05
	color = Color(1.0, 0.9 + temp_variation, 0.7 + temp_variation * 0.5, 1.0)