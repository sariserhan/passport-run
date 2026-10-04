class_name RoutePurchase
extends Node

signal changed
const PRODUCT_ID := "com.serhansari.passportrun.special_routes"
const CINEMA_PRODUCT_ID := "com.serhansari.passportrun.cinema_worlds"
var product_id := PRODUCT_ID
var unlocked := false
var busy := false
var price := ""
var is_character_pack := false
var message := "Route-pack purchases are available on iPhone."
var store: Object

func _init(id: String = PRODUCT_ID) -> void:
	product_id = id
	is_character_pack = id == "com.serhansari.passportrun.travelers"

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
		message = "This pack is unavailable right now. Your earned rewards are ready."
		return
	price = str(info.get("localized_price", ""))
	# Native StoreKit reports only Apple-verified current entitlements. Never read a saved premium flag.
	unlocked = info.get("is_purchased", false) == true
	if product_id == AdService.PRODUCT_ID:
		message = "Ads removed. Thank you for supporting Passport Run!" if unlocked else "One purchase removes the ad that plays after every few retries. Kids Mode never shows ads."
		return
	message = ("Traveler pack unlocked." if unlocked else "Unlock all milestone travelers. World Champion requires completing the world tour.") if is_character_pack else ("Route pack unlocked." if unlocked else "One purchase unlocks every destination in this route.")

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
			_: message = "Purchase could not be completed. You have not unlocked the pack."
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
		message = "No purchase was found for this Apple account."
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
