class_name RoutePurchase
extends Node

signal changed
const PRODUCT_ID := "com.serhansari.passportrun.special_routes"
const CINEMA_PRODUCT_ID := "com.serhansari.passportrun.cinema_worlds"
var product_id := PRODUCT_ID
var unlocked := false
var busy := false
var price := ""
var message := "Route-pack purchases are available on iPhone."
var store: Object

func _init(id: String = PRODUCT_ID) -> void:
	product_id = id

func _ready() -> void:
	if ClassDB.class_exists("GodotStoreKit2"):
		store = ClassDB.instantiate("GodotStoreKit2")
		store.transaction_state_changed.connect(on_transaction)
		refresh.call_deferred()

func refresh() -> void:
	if busy or not store:
		return
	busy = true
	changed.emit()
	await load_product()
	busy = false
	changed.emit()

func load_product() -> void:
	var info: Dictionary = await store.request_product_info(product_id)
	price = ""
	unlocked = false
	if info.get("error", "") != "" or info.get("product_id", "") != product_id:
		message = "The route pack is unavailable right now. Your free tour is ready."
		return
	price = str(info.get("localized_price", ""))
	# Native StoreKit reports only Apple-verified current entitlements. Never read a saved premium flag.
	unlocked = info.get("is_purchased", false) == true
	message = "Route pack unlocked." if unlocked else "One purchase unlocks every destination in this route."

func purchase() -> void:
	if busy or not store or price.is_empty() or unlocked:
		return
	busy = true
	message = "Waiting for the App Store…"
	changed.emit()
	var result: Dictionary = await store.purchase_product(product_id, 1)
	await load_product()
	if not unlocked:
		match int(result.get("transaction_state", -1)):
			2, 3: message = "Purchase is awaiting approval."
			7: message = "Purchase cancelled."
			_: message = "Purchase could not be completed. You have not unlocked the route pack."
	busy = false
	changed.emit()

func restore() -> void:
	if busy or not store:
		return
	busy = true
	message = "Restoring your App Store purchase…"
	changed.emit()
	await store.sync()
	await load_product()
	if not unlocked and not price.is_empty():
		message = "No route-pack purchase was found for this Apple account."
	busy = false
	changed.emit()

func on_transaction(transaction: Dictionary) -> void:
	if transaction.get("product_id", "") != product_id:
		return
	if int(transaction.get("transaction_state", -1)) in [1, 6]:
		unlocked = false
		changed.emit()
	if not busy:
		refresh.call_deferred()
