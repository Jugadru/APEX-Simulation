extends RefCounted
const ManagementHub = preload("res://scripts/apex_management_hub.gd")
static func _build_garage(host) -> void:
    host.garage_root = host._full_cover()
    # Retain the legacy layout anchor for compatibility with scene consumers.
    var anchor := PanelContainer.new()
    anchor.name = "GarageCard"
    anchor.hide()
    host.garage_root.add_child(anchor)
    var hub := ManagementHub.new()
    hub.setup(host)
