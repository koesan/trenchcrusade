extends Control

## Marker harcama seçim overlay'i. CombatChoice tarafından gösterilir; oyuncu Blessing/Blood
## marker harcama miktarını (veya Bloodbath'ı) seçer. Seçim yapılmazsa geri sayım sonunda
## güvenli varsayılan (harcama yok) uygulanır — akış kilitlenmez.

@onready var title: Label = $Center/Panel/Margin/VBox/Title
@onready var info: Label = $Center/Panel/Margin/VBox/Info
@onready var buttons: HBoxContainer = $Center/Panel/Margin/VBox/Buttons
## MİMARİ DÜZELTME (kullanıcı isteği): Evet/Hayır ikilisi üç ayrı yerde `Button.new()` ile
## KOD İÇİNDE tekrar tekrar inşa ediliyordu (aynı metin/renk/boyutla) — artık .tscn'de SABİT,
## tek örnek olarak tanımlı; kod yalnız gösterip/gizliyor ve metni günceller.
@onready var yes_no_buttons: HBoxContainer = $Center/Panel/Margin/VBox/YesNoButtons
@onready var no_button: Button = $Center/Panel/Margin/VBox/YesNoButtons/NoButton
@onready var yes_button: Button = $Center/Panel/Margin/VBox/YesNoButtons/YesButton
@onready var countdown: Label = $Center/Panel/Margin/VBox/Countdown

var _callback: Callable = Callable()
var _time_left: float = 0.0
const AUTO_SECONDS: float = 20.0

func _ready() -> void:
	visible = false
	set_process(false)
	no_button.pressed.connect(func(): _choose(0))
	yes_button.pressed.connect(func(): _choose(1))

## Evet/Hayır ikilisini gösterir, sayısal/özel buton konteynerini gizler.
func _show_yes_no() -> void:
	buttons.visible = false
	yes_no_buttons.visible = true
	no_button.text = LocalizationManager.tr_t("CHOICE_NO")
	yes_button.text = LocalizationManager.tr_t("CHOICE_YES")

## Sayısal/özel butonlar için: Evet/Hayır ikilisini gizler, `buttons` konteynerini gösterir.
func _show_dynamic_buttons() -> void:
	yes_no_buttons.visible = false
	buttons.visible = true
	for c in buttons.get_children():
		c.queue_free()

## kind: "blessing" | "blood" | "infection" (Injury Roll) | "blessing_success" | "blood_success"
##       | "infection_success" (Success Roll,
## P0-1) | "time_slip"/"eye_of_god" (P1-1, Evet/Hayır ikili onay — bkz. _YES_NO_KINDS). extra:
## blood için Bloodbath maliyeti (6 veya 3) — success/ikili-onay varyantlarında hep 0.
const _YES_NO_KINDS := ["time_slip", "eye_of_god", "pilgrim_bodyguard", "sound_retreat", "skirmisher_evade"]

func show_prompt(kind: String, target_name: String, maxv: int, extra: int, callback: Callable) -> void:
	_callback = callback
	# GOETIC SPELL (Court of the Seven-Headed Serpent, P1-1): "goetic_cost_<SPELL_DISPLAY_KEY>" —
	# değişken maliyetli büyülerde ödenecek Blood Marker sayısını sorar. target_name burada
	# spell_key'in kendisi (CombatChoice.request_goetic_cost bunu display_name lokalizasyon
	# anahtarı olarak geçer), maxv=üst sınır, extra=alt sınır (buton aralığı 0'dan DEĞİL buradan
	# başlar — diğer "kind"lerden FARKLI).
	if kind.begins_with("goetic_cost_"):
		title.text = LocalizationManager.tr_t(target_name)
		info.text = LocalizationManager.tr_t("GOETIC_COST_INFO")
		_show_dynamic_buttons()
		for i in range(extra, maxv + 1):
			var gb := Button.new()
			gb.theme_type_variation = &"ButtonSecondary"
			gb.custom_minimum_size = Vector2(48, 40)
			gb.text = str(i)
			var gval: int = i
			gb.pressed.connect(func(): _choose(gval))
			buttons.add_child(gb)
		GothicThemeHelper.init_ui(self)
		_time_left = AUTO_SECONDS
		countdown.text = LocalizationManager.tr_t("HINT_AUTO_CANCEL") % int(_time_left)
		visible = true
		set_process(true)
		return
	# GOETIC SPELL (P1-1): reaktif büyüler (Blessings of the Serpent Moon, Blood Magic, Oracle
	# Beast Cloak, Shadow Walker) için "bu büyüyü cast etmek ister misin?" Evet/Hayır onayı.
	# target_name burada spell'in display_name lokalizasyon anahtarı.
	if kind.begins_with("goetic_cast_confirm_"):
		title.text = LocalizationManager.tr_t(target_name)
		info.text = LocalizationManager.tr_t("GOETIC_CAST_CONFIRM_INFO")
		_show_yes_no()
		GothicThemeHelper.init_ui(self)
		_time_left = AUTO_SECONDS
		countdown.text = LocalizationManager.tr_t("HINT_AUTO_CANCEL") % int(_time_left)
		visible = true
		set_process(true)
		return
	# BOW OF LETHE (Hunter of the Left Hand Path, P1-1): Injury Roll'dan ÖNCE +2 Injury Dice mi
	# yoksa Ignore Armour mu seçilir — Y/N değil, iki İSİMLİ seçenek.
	# TREAT (Medi-Kit): compendium başarıda İKİ etkiden BİRİNİ seçtirir — Y/N değil,
	# iki İSİMLİ seçenek (special_ammunition ile AYNI desen).
	# MASTERY OF THE ELEMENTS (Jabirean Alchemist): üç element arasından biri seçilir.
	if kind == "element_choice":
		title.text = LocalizationManager.tr_t("ELEMENT_CHOICE_TITLE")
		info.text = LocalizationManager.tr_t("ELEMENT_CHOICE_INFO") % target_name
		_show_dynamic_buttons()
		var elem_keys := ["ELEMENT_FIRE", "ELEMENT_GAS", "ELEMENT_SHRAPNEL"]
		for i in range(elem_keys.size()):
			var eb := Button.new()
			eb.theme_type_variation = &"ButtonSecondary"
			eb.custom_minimum_size = Vector2(150, 44)
			eb.text = LocalizationManager.tr_t(elem_keys[i])
			var idx := i
			eb.pressed.connect(func(): _choose(idx))
			buttons.add_child(eb)
		GothicThemeHelper.init_ui(self)
		_time_left = AUTO_SECONDS
		countdown.text = LocalizationManager.tr_t("HINT_AUTO_CANCEL") % int(_time_left)
		visible = true
		set_process(true)
		return
	if kind == "treat_choice":
		title.text = LocalizationManager.tr_t("TREAT_CHOICE_TITLE")
		info.text = LocalizationManager.tr_t("TREAT_CHOICE_INFO") % target_name
		_show_dynamic_buttons()
		var blood_btn := Button.new()
		blood_btn.theme_type_variation = &"ButtonSecondary"
		blood_btn.custom_minimum_size = Vector2(180, 44)
		blood_btn.text = LocalizationManager.tr_t("TREAT_CHOICE_REMOVE_BLOOD")
		blood_btn.pressed.connect(func(): _choose(1))
		buttons.add_child(blood_btn)
		var stand_btn := Button.new()
		stand_btn.theme_type_variation = &"ButtonSecondary"
		stand_btn.custom_minimum_size = Vector2(180, 44)
		stand_btn.text = LocalizationManager.tr_t("TREAT_CHOICE_STAND_UP")
		stand_btn.pressed.connect(func(): _choose(0))
		buttons.add_child(stand_btn)
		GothicThemeHelper.init_ui(self)
		_time_left = AUTO_SECONDS
		countdown.text = LocalizationManager.tr_t("HINT_AUTO_CANCEL") % int(_time_left)
		visible = true
		set_process(true)
		return
	if kind == "special_ammunition":
		title.text = LocalizationManager.tr_t("SPECIAL_AMMUNITION_TITLE")
		info.text = LocalizationManager.tr_t("SPECIAL_AMMUNITION_INFO") % target_name
		_show_dynamic_buttons()
		var dice_btn := Button.new()
		dice_btn.theme_type_variation = &"ButtonSecondary"
		dice_btn.custom_minimum_size = Vector2(160, 44)
		dice_btn.text = LocalizationManager.tr_t("SPECIAL_AMMUNITION_DICE")
		dice_btn.pressed.connect(func(): _choose(1))
		buttons.add_child(dice_btn)
		var ignore_btn := Button.new()
		ignore_btn.theme_type_variation = &"ButtonDanger"
		ignore_btn.custom_minimum_size = Vector2(160, 44)
		ignore_btn.text = LocalizationManager.tr_t("SPECIAL_AMMUNITION_IGNORE_ARMOUR")
		ignore_btn.pressed.connect(func(): _choose(0))
		buttons.add_child(ignore_btn)
		GothicThemeHelper.init_ui(self)
		_time_left = AUTO_SECONDS
		countdown.text = LocalizationManager.tr_t("HINT_AUTO_CANCEL") % int(_time_left)
		visible = true
		set_process(true)
		return
	match kind:
		"blessing":
			title.text = LocalizationManager.tr_t("MARKER_BLESSING_TITLE")
			info.text = LocalizationManager.tr_t("MARKER_BLESSING_INFO") % target_name
		"blessing_success":
			title.text = LocalizationManager.tr_t("MARKER_BLESSING_SUCCESS_TITLE")
			info.text = LocalizationManager.tr_t("MARKER_BLESSING_SUCCESS_INFO") % target_name
		"blood_success":
			title.text = LocalizationManager.tr_t("MARKER_BLOOD_SUCCESS_TITLE")
			info.text = LocalizationManager.tr_t("MARKER_BLOOD_SUCCESS_INFO") % target_name
		"infection_success":
			title.text = LocalizationManager.tr_t("MARKER_INFECTION_SUCCESS_TITLE")
			info.text = LocalizationManager.tr_t("MARKER_INFECTION_SUCCESS_INFO") % target_name
		"time_slip":
			title.text = LocalizationManager.tr_t("TIME_SLIP_TITLE")
			info.text = LocalizationManager.tr_t("TIME_SLIP_INFO") % target_name
		"eye_of_god":
			title.text = LocalizationManager.tr_t("EYE_OF_GOD_TITLE")
			info.text = LocalizationManager.tr_t("EYE_OF_GOD_INFO") % target_name
		"sound_retreat":
			title.text = LocalizationManager.tr_t("SOUND_RETREAT_TITLE")
			info.text = LocalizationManager.tr_t("SOUND_RETREAT_INFO")
		"skirmisher_evade":
			title.text = LocalizationManager.tr_t("SKIRMISHER_EVADE_TITLE")
			info.text = LocalizationManager.tr_t("SKIRMISHER_EVADE_INFO") % target_name
		"pilgrim_bodyguard":
			title.text = LocalizationManager.tr_t("PILGRIM_BODYGUARD_TITLE")
			info.text = LocalizationManager.tr_t("PILGRIM_BODYGUARD_INFO") % target_name
		"infection":
			title.text = LocalizationManager.tr_t("MARKER_INFECTION_TITLE")
			info.text = LocalizationManager.tr_t("MARKER_INFECTION_INFO") % target_name
		_:
			title.text = LocalizationManager.tr_t("MARKER_BLOOD_TITLE")
			info.text = LocalizationManager.tr_t("MARKER_BLOOD_INFO") % target_name

	if kind in _YES_NO_KINDS:
		_show_yes_no()
	else:
		_show_dynamic_buttons()
		for i in range(0, maxv + 1):
			var b := Button.new()
			b.theme_type_variation = &"ButtonSecondary"
			b.custom_minimum_size = Vector2(48, 40)
			b.text = str(i)
			var val: int = i
			b.pressed.connect(func(): _choose(val))
			buttons.add_child(b)
		if (kind == "blood" or kind == "infection") and extra > 0 and maxv >= extra:
			var bb := Button.new()
			bb.theme_type_variation = &"ButtonDanger"
			bb.text = LocalizationManager.tr_t("MARKER_BLOODBATH") % extra
			bb.pressed.connect(func(): _choose(-1))
			buttons.add_child(bb)

	GothicThemeHelper.init_ui(self)
	_time_left = AUTO_SECONDS
	countdown.text = LocalizationManager.tr_t("MARKER_AUTO") % int(_time_left)
	visible = true
	set_process(true)

func _choose(value: int) -> void:
	visible = false
	set_process(false)
	var cb := _callback
	_callback = Callable()
	if cb.is_valid():
		cb.call(value)

func _process(delta: float) -> void:
	_time_left -= delta
	countdown.text = LocalizationManager.tr_t("MARKER_AUTO") % maxi(0, int(ceil(_time_left)))
	if _time_left <= 0.0:
		_choose(0)
