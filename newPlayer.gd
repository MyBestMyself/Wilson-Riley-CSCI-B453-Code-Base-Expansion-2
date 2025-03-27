extends Area2D

@export var maxSpeed = 15
@export var velocityCap = 5

var milk_tea_level: Control
var left_boundary: float
var right_boundary: float
var top_boundary: float
var bottom_boundary: float

var currentSpeed = 0
var direction = Vector2(0, 0)
var velocity = Vector2(0, 0)
var touching_boba = false
var boba_acceleration = 0

var immune

func _process(delta: float) -> void:
	if Input.is_action_pressed("m1"):
		direction = (get_global_mouse_position() - position).normalized()
		if currentSpeed < maxSpeed:
			currentSpeed += 1
			if currentSpeed > maxSpeed:
				currentSpeed = maxSpeed
	elif currentSpeed > 0:
		currentSpeed -= 1
		if currentSpeed < 0:
			currentSpeed = 0
	
	
	velocity = direction * maxSpeed * currentSpeed
	
	var new_position = position + velocity * delta
	
	#move up if touching boba
	if touching_boba and boba_acceleration < maxSpeed:
		boba_acceleration += 1
	elif boba_acceleration > 0:
		boba_acceleration -= 0.5
	elif boba_acceleration < 0:
		boba_acceleration = 0
	new_position.y -= boba_acceleration
	
	look_at(get_global_mouse_position())
	rotation -= deg_to_rad(90)
	
	# Clamp the player's position within the boundaries
	new_position.x = clamp(new_position.x, left_boundary, right_boundary)
	new_position.y = clamp(new_position.y, top_boundary, bottom_boundary)

	# Update position
	if !Input.is_action_pressed("m1") or position.distance_to(get_global_mouse_position()) > 5:
		position = new_position
	
	if velocity.x != 0:
		$AnimatedSprite2D.animation = &"default"
		$AnimatedSprite2D.flip_v = false
		$Trail.rotation = 0
		$Trail.visible = true
		#$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = &"default"
		rotation = PI if velocity.y > 0 else 0
		$Trail.visible = true
	else:
		$Trail.visible = false
	
	if Input.is_action_just_pressed("test_immunity"):
		immune = !immune

func start(pos, mtl: ColorRect, left: float, right: float):
	position = pos
	show()
	$CollisionShape2D.disabled = false
	milk_tea_level = mtl
	left_boundary = left
	right_boundary = right
	update_vertical_boundaries()

func _on_body_entered(_body):
	if _body.is_in_group("falling_boba"):
		touching_boba = true
		
	if _body.is_in_group("straw") and not immune:
		#Game over
		hide()
		get_parent().game_over()
		$CollisionShape2D.set_deferred(&"disabled", true)

func _on_body_exited(_body):
	if _body.is_in_group("falling_boba"):
		touching_boba = false

func push_from_explosion(explosion_position):
	var direction = global_position - explosion_position
	var distance = direction.length()
	var throw_distance = 200  # Distance threshold for throwing the player
	var throw_strength = 500  # Strength of the throw
	var push_strength = 3000  # Normal push strength
	
	if distance < throw_distance:
		# Player is close enough to be thrown
		var throw_vector = direction.normalized() * throw_strength
		var throw_duration = 0.5  # Duration of the throw in seconds
		
		# Calculate the target position
		var target_position = position + throw_vector
		
		# Clamp the target position within boundaries
		target_position.x = clamp(target_position.x, left_boundary, right_boundary)
		# Assuming you have top and bottom boundaries as well
		target_position.y = clamp(target_position.y, top_boundary, bottom_boundary)
		
		# Use a Tween to animate the throw
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "position", target_position, throw_duration)
		
		# Optional: Add a slight rotation for effect
		tween.parallel().tween_property(self, "rotation", randf_range(-PI/4, PI/4), throw_duration)
		
		# Reset rotation after throw
		tween.tween_property(self, "rotation", 0, 0.2)
	else:
		# Normal push if not close enough
		var push_vector = direction.normalized() * (push_strength / (distance + 1))
		position += push_vector
		
		# Clamp position immediately for normal push
		position.x = clamp(position.x, left_boundary, right_boundary)
		position.y = clamp(position.y, top_boundary, bottom_boundary)

func update_vertical_boundaries():
	var fill_amount = milk_tea_level.material.get_shader_parameter("fill_amount")
	top_boundary = milk_tea_level.global_position.y + milk_tea_level.size.y * (1 - fill_amount)
	bottom_boundary = milk_tea_level.global_position.y + milk_tea_level.size.y
