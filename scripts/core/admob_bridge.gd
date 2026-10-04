extends RefCounted

# Everything that touches the AdMob plugin. AdService load()s this only on iOS, because
# referencing the plugin's classes on desktop creates mock singletons that leak at exit.
signal loaded
signal closed

var ad: InterstitialAd
var started := false

func begin() -> void:
	var on_error := func(_error): start()
	UserMessagingPlatform.consent_information.update(ConsentRequestParameters.new(), func():
		if UserMessagingPlatform.consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
			UserMessagingPlatform.load_consent_form(func(form: ConsentForm): form.show(func(_error): start()), on_error)
		else:
			start()
	, on_error)

func start() -> void:
	if started: return
	started = true
	MobileAds.initialize()
	load_ad()

func load_ad() -> void:
	if not started or ad: return
	var request := AdRequest.new()
	request.extras = {"npa": "1"} # non-personalized
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_failed_to_load = func(error: LoadAdError): print("AdMob: interstitial failed to load: ", error.message)
	callback.on_ad_loaded = func(new_ad: InterstitialAd):
		print("AdMob: interstitial loaded")
		ad = new_ad
		ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = close
		ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_error): close()
		loaded.emit()
	InterstitialAdLoader.new().load(ProjectSettings.get_setting(AdService.UNIT_SETTING, AdService.TEST_UNIT), request, callback)

func ready_to_show() -> bool:
	return ad != null

func show() -> void:
	ad.show()

func close() -> void:
	if ad: ad.destroy()
	ad = null
	closed.emit()
	load_ad()

func privacy_options_required() -> bool:
	return started and UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

func show_privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form()
