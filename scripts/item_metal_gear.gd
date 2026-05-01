extends RigidBody2D

@onready var hit_box = $Hitbox
@onready var notifier = $VisibleOnScreenNotifier2D

var damage = 4 
var hit_zombies: Array = [] 
var is_dashing = false 

func _ready():
	z_index = 1
	angular_velocity = 30.0 
	gravity_scale = 1.0 
	
	body_entered.connect(_on_body_entered)
	hit_box.body_entered.connect(_on_hitbox_body_entered)
	notifier.screen_exited.connect(queue_free) 

func _physics_process(delta):
	if is_dashing:
		linear_velocity.x = 600.0 
		linear_velocity.y = 0.0

func _on_body_entered(body):
	if body.name == "Ground" and not is_dashing:
		is_dashing = true
		set_deferred("gravity_scale", 0.0)

func _on_hitbox_body_entered(body):
	if body.has_method("take_damage") and not body in hit_zombies:
		print(">> Metal Gear memotong Zombie!")
		hit_zombies.append(body)
		body.take_damage(damage)
		
		if body.has_method("apply_knockback"):
			body.apply_knockback(25.0)
