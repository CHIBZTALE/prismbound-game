extends Node3D

# Android debug APK builds are automated through GitHub Actions.

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
            var dx: float = event.position.x - touch_start.x
            if abs(dx) > 28:
                _change_lane(1 if dx > 0 else -1)
            dragging = false
    elif event is InputEventScreenDrag:
        var dx: float = event.position.x - touch_start.x
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
    sky_mat.sky_top_color = Color(0.008, 0.014, 0.055)
    sky_mat.sky_horizon_color = Color(0.075, 0.018, 0.16)
    sky_mat.ground_bottom_color = Color(0.004, 0.006, 0.02)
    sky_mat.ground_horizon_color = Color(0.025, 0.012, 0.065)
    env.sky.sky_material = sky_mat
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.34, 0.43, 0.78)
    env.ambient_light_energy = 0.8
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = true
    env.glow_intensity = 0.9
    env.glow_strength = 1.15
    env.glow_bloom = 0.12
    env.fog_enabled = true
    env.fog_light_color = Color(0.045, 0.025, 0.12)
    env.fog_density = 0.012
    world_environment = WorldEnvironment.new()
    world_environment.environment = env
    add_child(world_environment)

    var camera := Camera3D.new()
    camera.position = Vector3(0, 8.1, 14.2)
    camera.rotation_degrees = Vector3(-26, 0, 0)
    camera.fov = 54
    add_child(camera)
    camera.current = true

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48, -25, 0)
    key.light_color = Color(0.65, 0.82, 1.0)
    key.light_energy = 1.65
    key.shadow_enabled = true
    add_child(key)

    var rim := OmniLight3D.new()
    rim.position = Vector3(0, 5.5, -12)
    rim.light_color = Color(0.16, 0.28, 1.0)
    rim.light_energy = 2.4
    rim.omni_range = 24.0
    add_child(rim)

    _add_box("ObsidianTrack", Vector3(9.2, 0.42, 72), Vector3(0, -1.18, -15), Color(0.012, 0.018, 0.045), 0.92, 0.16)
    _add_box("TrackGlass", Vector3(7.8, 0.035, 70), Vector3(0, -0.955, -15), Color(0.025, 0.045, 0.105), 0.72, 0.12)
    for x in [-4.45, 4.45]:
        _add_box("ChromeOuterRail", Vector3(0.18, 0.24, 72), Vector3(x, -0.91, -15), Color(0.32, 0.48, 0.72), 0.96, 0.11)
        _add_box("CyanRailLight", Vector3(0.045, 0.055, 72), Vector3(x * 0.975, -0.77, -15), Color(0.02, 0.72, 1.0), 0.35, 0.1, true)
    for x in [-1.2, 1.2]:
        _add_box("LaneDivider", Vector3(0.035, 0.018, 70), Vector3(x, -0.925, -15), Color(0.08, 0.24, 0.55), 0.8, 0.18, true)
    for z in range(-48, 18, 4):
        _add_box("LanePulse", Vector3(0.045, 0.022, 1.25), Vector3(0, -0.925, z), Color(0.12, 0.3, 0.72), 0.65, 0.18, true)
    for z in range(-48, 12, 12):
        for side in [-1.0, 1.0]:
            _add_box("RiftPylon", Vector3(0.42, 5.2, 0.48), Vector3(side * 6.0, 1.25, z), Color(0.035, 0.045, 0.12), 0.86, 0.18)
            _add_box("PylonNeon", Vector3(0.055, 4.4, 0.07), Vector3(side * 5.76, 1.25, z), Color(0.16, 0.22, 1.0), 0.5, 0.12, true)
        _add_box("DistantRiftBeam", Vector3(12.0, 0.12, 0.18), Vector3(0, 4.05, z), Color(0.18, 0.12, 0.58), 0.75, 0.14, true)


func _build_player() -> void:
    player = Node3D.new()
    player.position = Vector3(0, -0.05, PLAYER_Z)
    add_child(player)

    var hull_mat := _gloss(Color(0.035, 0.09, 0.19), 0.94, 0.1)
    var chrome := _gloss(Color(0.48, 0.72, 0.92), 0.98, 0.08)
    var cyan := _gloss(Color(0.015, 0.72, 1.0), 0.55, 0.12, Color(0.015, 0.68, 1.0), 2.4)
    var gold := _gloss(Color(1.0, 0.58, 0.12), 0.9, 0.1, Color(1.0, 0.22, 0.015), 1.6)

    var hull := BoxMesh.new()
    _visual_part(player, hull, Vector3(0, 0.0, 0), Vector3(0.92, 0.42, 1.55), hull_mat, Vector3(0, 0, 0))
    var nose := PrismMesh.new()
    _visual_part(player, nose, Vector3(0, 0.02, -0.78), Vector3(0.9, 0.48, 0.72), chrome, Vector3(0, 0, 0))
    var canopy := SphereMesh.new()
    _visual_part(player, canopy, Vector3(0, 0.31, -0.05), Vector3(0.54, 0.34, 0.72), cyan)
    var core := SphereMesh.new()
    _visual_part(player, core, Vector3(0, 0.03, 0.32), Vector3(0.42, 0.22, 0.48), gold)
    for side in [-1.0, 1.0]:
        var wing := BoxMesh.new()
        _visual_part(player, wing, Vector3(side * 0.78, -0.02, 0.22), Vector3(0.72, 0.12, 0.72), chrome, Vector3(0, 0, side * -0.12))
        var wing_light := BoxMesh.new()
        _visual_part(player, wing_light, Vector3(side * 0.82, 0.055, 0.18), Vector3(0.58, 0.035, 0.12), cyan)
        var thruster := CylinderMesh.new()
        _visual_part(player, thruster, Vector3(side * 0.38, -0.08, 0.78), Vector3(0.2, 0.16, 0.2), gold, Vector3(PI / 2.0, 0, 0))
    var front_light := BoxMesh.new()
    _visual_part(player, front_light, Vector3(0, -0.06, -1.04), Vector3(0.42, 0.07, 0.08), cyan)
    var underglow := OmniLight3D.new()
    underglow.position = Vector3(0, -0.42, 0.1)
    underglow.light_color = Color(0.02, 0.55, 1.0)
    underglow.light_energy = 1.8
    underglow.omni_range = 4.5
    player.add_child(underglow)

func _spawn_pattern() -> void:
    var obstacle_lane := randi_range(0, 2)
    _spawn_object(obstacle_lane, false, SPAWN_Z)
    var shard_lane := randi_range(0, 2)
    if shard_lane == obstacle_lane:
        shard_lane = (shard_lane + 1 + randi_range(0, 1)) % 3
    _spawn_object(shard_lane, true, SPAWN_Z - 5.0)


func _spawn_object(target_lane: int, is_shard: bool, z: float) -> void:
    var node := Node3D.new()
    node.position = Vector3(LANES[target_lane], 0.0, z)
    add_child(node)
    var chrome := _gloss(Color(0.28, 0.38, 0.56), 0.96, 0.12)
    var amber := _gloss(Color(1.0, 0.56, 0.08), 0.9, 0.08, Color(1.0, 0.24, 0.015), 2.0)
    var crimson := _gloss(Color(0.38, 0.012, 0.075), 0.82, 0.13, Color(1.0, 0.008, 0.09), 1.8)
    var neon := _gloss(Color(0.02, 0.78, 1.0), 0.55, 0.1, Color(0.02, 0.72, 1.0), 2.5)

    if is_shard:
        var crystal := PrismMesh.new()
        _visual_part(node, crystal, Vector3(0, 0.12, 0), Vector3(0.72, 0.9, 0.72), amber, Vector3(0.15, 0.2, 0.12))
        var inner := SphereMesh.new()
        _visual_part(node, inner, Vector3(0, 0.12, 0), Vector3(0.22, 0.42, 0.22), neon)
        var ring := CylinderMesh.new()
        ring.top_radius = 0.58
        ring.bottom_radius = 0.58
        ring.height = 0.055
        _visual_part(node, ring, Vector3(0, -0.38, 0), Vector3(1, 1, 1), chrome)
    else:
        var block := BoxMesh.new()
        _visual_part(node, block, Vector3(0, 0.05, 0), Vector3(1.45, 1.75, 0.92), crimson)
        var face := BoxMesh.new()
        _visual_part(node, face, Vector3(0, 0.05, -0.48), Vector3(1.18, 1.48, 0.035), _gloss(Color(0.055, 0.008, 0.035), 0.75, 0.16))
        for side in [-1.0, 1.0]:
            var trim := BoxMesh.new()
            _visual_part(node, trim, Vector3(side * 0.63, 0.05, -0.51), Vector3(0.07, 1.72, 0.06), neon)
        var crown := BoxMesh.new()
        _visual_part(node, crown, Vector3(0, 0.96, 0), Vector3(1.58, 0.09, 1.02), chrome)

    var light := OmniLight3D.new()
    light.light_color = Color(1.0, 0.48, 0.08) if is_shard else Color(1.0, 0.015, 0.12)
    light.light_energy = 1.5
    light.omni_range = 3.6
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

func _gloss(color: Color, metallic: float, roughness: float, glow: Color = Color.BLACK, glow_energy: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metallic
    mat.roughness = roughness
    mat.clearcoat_enabled = true
    mat.clearcoat = 1.0
    mat.clearcoat_roughness = 0.06
    if glow_energy > 0.0:
        mat.emission_enabled = true
        mat.emission = glow
        mat.emission_energy_multiplier = glow_energy
    return mat

func _visual_part(parent: Node3D, mesh: Mesh, pos: Vector3, part_scale: Vector3, material: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = pos
    instance.scale = part_scale
    instance.rotation = rot
    instance.material_override = material
    parent.add_child(instance)
    return instance

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
