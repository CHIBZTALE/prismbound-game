extends Node3D

const LANES := [-2.4, 0.0, 2.4]
const PLAYER_Z := 5.0
const SPAWN_Z := -34.0
const DESPAWN_Z := 12.0

var lane := 1
var score := 0
var score_progress := 0.0
var shards := 0
var speed := 13.0
var elapsed := 0.0
var ended := false
var spawn_clock := 0.0
var spawn_interval := 1.25
var objects: Array[Node3D] = []
var touch_start := Vector2.ZERO
var dragging := false

var player: Node3D
var hud: CanvasLayer
var score_label: Label
var shard_label: Label
var message_label: Label
var world_environment: WorldEnvironment

func _ready() -> void:
    _build_world()
    _build_player()
    _build_hud()
    _spawn_pattern()

func _process(delta: float) -> void:
    if ended:
        if Input.is_action_just_pressed("restart"):
            _restart()
        return
    elapsed += delta
    speed = min(23.0, 13.0 + elapsed * 0.22)
    spawn_interval = max(0.72, 1.25 - elapsed * 0.004)
    _read_controls()
    spawn_clock += delta
    if spawn_clock >= spawn_interval:
        spawn_clock = 0.0
        _spawn_pattern()
    for item in objects.duplicate():
        item.position.z += speed * delta
        if item.position.z > DESPAWN_Z:
            objects.erase(item)
            item.queue_free()
    player.position.x = lerp(player.position.x, LANES[lane], min(1.0, delta * 14.0))
    player.rotation.z = lerp(player.rotation.z, (LANES[lane] - player.position.x) * -0.10, min(1.0, delta * 8.0))
    _update_hud()

func _input(event: InputEvent) -> void:
    if ended:
        if event is InputEventScreenTouch and event.pressed:
            _restart()
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_start = event.position
            dragging = true
        elif dragging:
            var dx := event.position.x - touch_start.x
            if abs(dx) > 28:
                _change_lane(1 if dx > 0 else -1)
            dragging = false
    elif event is InputEventScreenDrag:
        var dx := event.position.x - touch_start.x
        if abs(dx) > 65:
            _change_lane(1 if dx > 0 else -1)
            touch_start = event.position

func _read_controls() -> void:
    if Input.is_action_just_pressed("move_left"):
        _change_lane(-1)
    if Input.is_action_just_pressed("move_right"):
        _change_lane(1)

func _change_lane(direction: int) -> void:
    lane = clampi(lane + direction, 0, 2)

func _build_world() -> void:
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.012, 0.025, 0.09)
    sky_mat.sky_horizon_color = Color(0.10, 0.035, 0.19)
    sky_mat.ground_bottom_color = Color(0.008, 0.012, 0.035)
    sky_mat.ground_horizon_color = Color(0.035, 0.018, 0.09)
    env.sky.sky_material = sky_mat
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.45, 0.50, 0.85)
    env.ambient_light_energy = 0.65
    env.glow_enabled = true
    env.glow_intensity = 0.75
    world_environment = WorldEnvironment.new()
    world_environment.environment = env
    add_child(world_environment)

    var camera := Camera3D.new()
    camera.position = Vector3(0, 8.5, 13.5)
    camera.rotation_degrees = Vector3(-27, 0, 0)
    camera.fov = 55
    add_child(camera)
    camera.current = true

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48, -25, 0)
    key.light_energy = 1.8
    key.shadow_enabled = true
    add_child(key)

    _add_box("Track", Vector3(8.8, 0.35, 62), Vector3(0, -1.15, -12), Color(0.025, 0.035, 0.095), 0.32, 0.8)
    for x in [-3.65, -1.2, 1.2, 3.65]:
        _add_box("NeonRail", Vector3(0.055, 0.08, 62), Vector3(x, -0.88, -12), Color(0.05, 0.78, 1.0), 0.18, 0.22, true)
    for z in range(-40, 13, 4):
        _add_box("TrackMark", Vector3(0.035, 0.018, 1.1), Vector3(0, -0.96, z), Color(0.15, 0.23, 0.48), 0.1, 0.2)

func _build_player() -> void:
    player = Node3D.new()
    player.position = Vector3(0, 0, PLAYER_Z)
    add_child(player)
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.05, 1.15, 0.82)
    body.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.05, 0.88, 1.0)
    mat.metallic = 0.82
    mat.roughness = 0.12
    mat.emission_enabled = true
    mat.emission = Color(0.02, 0.55, 1.0)
    mat.emission_energy_multiplier = 1.5
    body.material_override = mat
    player.add_child(body)
    var crown := MeshInstance3D.new()
    var prism := PrismMesh.new()
    prism.size = Vector3(0.82, 0.72, 0.72)
    crown.mesh = prism
    crown.position.y = 0.83
    var gold := StandardMaterial3D.new()
    gold.albedo_color = Color(1.0, 0.68, 0.15)
    gold.metallic = 0.92
    gold.roughness = 0.09
    gold.emission_enabled = true
    gold.emission = Color(1.0, 0.28, 0.025)
    gold.emission_energy_multiplier = 1.0
    crown.material_override = gold
    player.add_child(crown)

func _spawn_pattern() -> void:
    var obstacle_lane := randi_range(0, 2)
    _spawn_object(obstacle_lane, false, SPAWN_Z)
    var shard_lane := randi_range(0, 2)
    if shard_lane == obstacle_lane:
        shard_lane = (shard_lane + 1 + randi_range(0, 1)) % 3
    _spawn_object(shard_lane, true, SPAWN_Z - 5.0)

func _spawn_object(target_lane: int, is_shard: bool, z: float) -> void:
    var node := Node3D.new()
    node.position = Vector3(LANES[target_lane], -0.05, z)
    add_child(node)
    var mesh_instance := MeshInstance3D.new()
    if is_shard:
        var mesh := SphereMesh.new()
        mesh.radius = 0.43
        mesh.height = 0.86
        mesh_instance.mesh = mesh
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(1.0, 0.55, 0.08)
        mat.metallic = 0.88
        mat.roughness = 0.08
        mat.emission_enabled = true
        mat.emission = Color(1.0, 0.24, 0.015)
        mat.emission_energy_multiplier = 2.1
        mesh_instance.material_override = mat
    else:
        var mesh := BoxMesh.new()
        mesh.size = Vector3(1.45, 1.75, 1.05)
        mesh_instance.mesh = mesh
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.95, 0.035, 0.22)
        mat.metallic = 0.65
        mat.roughness = 0.16
        mat.emission_enabled = true
        mat.emission = Color(0.9, 0.015, 0.08)
        mat.emission_energy_multiplier = 1.2
        mesh_instance.material_override = mat
    node.add_child(mesh_instance)
    var light := OmniLight3D.new()
    light.light_color = Color(1.0, 0.35, 0.12) if is_shard else Color(1.0, 0.02, 0.12)
    light.light_energy = 1.4
    light.omni_range = 3.0
    node.add_child(light)
    node.set_meta("is_shard", is_shard)
    objects.append(node)

func _physics_process(delta: float) -> void:
    if ended:
        return
    score_progress += delta * 10.0
    score = int(score_progress)
    for item in objects.duplicate():
        if abs(item.position.z - PLAYER_Z) < 0.85 and abs(item.position.x - player.position.x) < 0.95:
            if item.get_meta("is_shard", false):
                shards += 1
                score += 100
                objects.erase(item)
                item.queue_free()
            else:
                _game_over()
                return

func _build_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var panel := PanelContainer.new()
    panel.position = Vector2(22, 22)
    panel.size = Vector2(300, 112)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.035, 0.085, 0.86)
    style.border_color = Color(0.05, 0.78, 1.0, 0.8)
    style.set_border_width_all(2)
    style.set_corner_radius_all(18)
    style.content_margin_left = 18
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    panel.add_theme_stylebox_override("panel", style)
    hud.add_child(panel)
    var vbox := VBoxContainer.new()
    panel.add_child(vbox)
    score_label = Label.new()
    score_label.add_theme_font_size_override("font_size", 30)
    score_label.add_theme_color_override("font_color", Color(0.85, 0.97, 1))
    vbox.add_child(score_label)
    shard_label = Label.new()
    shard_label.add_theme_font_size_override("font_size", 18)
    shard_label.add_theme_color_override("font_color", Color(1.0, 0.68, 0.18))
    vbox.add_child(shard_label)

    var title := Label.new()
    title.text = "P R I S M B O U N D"
    title.position = Vector2(0, 145)
    title.size = Vector2(720, 45)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 26)
    title.add_theme_color_override("font_color", Color(0.52, 0.9, 1.0))
    hud.add_child(title)

    message_label = Label.new()
    message_label.position = Vector2(35, 450)
    message_label.size = Vector2(650, 270)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    message_label.add_theme_font_size_override("font_size", 32)
    message_label.add_theme_color_override("font_color", Color(1, 1, 1))
    hud.add_child(message_label)
    _update_hud()

func _update_hud() -> void:
    score_label.text = "SCORE  %06d" % score
    shard_label.text = "✦  SHARDS  %02d" % shards

func _game_over() -> void:
    ended = true
    message_label.text = "RIFT COLLAPSE\n\nSCORE  %d\nSHARDS  %d\n\nTAP TO RETRY" % [score, shards]

func _restart() -> void:
    get_tree().reload_current_scene()

func _add_box(label: String, size: Vector3, pos: Vector3, color: Color, metallic: float, roughness: float, emissive := false) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metallic
    mat.roughness = roughness
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.4
    mesh_instance.material_override = mat
    add_child(mesh_instance)
