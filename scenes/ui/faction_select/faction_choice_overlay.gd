extends Control

## GENEL faksiyon-kurulum seçim overlay'i.
##
## Bazı faksiyonlar, warband kurulurken compendium'un zorunlu kıldığı bir seçim yapar:
##   - Court of the Seven-Headed Serpent → Seven Deadly Sins (FactionData.SEVEN_DEADLY_SINS)
##   - Cult of the Black Grail          → The Order of the Fly (FactionData.LEADER_CHOICES)
##
## İkisi de "sözlükten bir anahtar seç" biçiminde olduğu için TEK bileşen sürer; yeni bir
## faksiyon-kurulum seçimi eklemek yalnız FactionData'ya bir sabit sözlük eklemeyi gerektirir,
## yeni bir sahne/script DEĞİL.
##
## Sözlük biçimi: { anahtar: { "display_name": <loc key>, "<desc_field>": <loc key> } }
## İptal edilirse boş bir StringName dönülür; çağıran taraf bunu ele alıp faksiyon seçimini
## iptal etmelidir.

@onready var title: Label = $Center/Panel/Margin/VBox/Title
@onready var description: Label = $Center/Panel/Margin/VBox/Description
@onready var buttons: VBoxContainer = $Center/Panel/Margin/VBox/ChoiceButtons
@onready var cancel_btn: Button = $Center/Panel/Margin/VBox/CancelBtn

var _callback: Callable = Callable()

func _ready() -> void:
	visible = false
	cancel_btn.text = LocalizationManager.tr_t("CANCEL")
	cancel_btn.pressed.connect(func(): _choose(&""))

## choices:     seçenek sözlüğü (bkz. sınıf yorumu)
## desc_field:  her seçenekte açıklamayı taşıyan alan adı
##              (Sins → "demonic_aura_desc", Order of the Fly → "desc")
## title_key / desc_key: overlay başlığı ve alt açıklaması (lokalizasyon anahtarları)
func show_prompt(callback: Callable, choices: Dictionary, desc_field: String,
		title_key: String, desc_key: String) -> void:
	_callback = callback
	title.text = LocalizationManager.tr_t(title_key)
	description.text = LocalizationManager.tr_t(desc_key)

	for c in buttons.get_children():
		c.queue_free()

	for choice_id in choices.keys():
		var data: Dictionary = choices[choice_id]
		var b := Button.new()
		b.theme_type_variation = &"ButtonSecondary"
		b.custom_minimum_size = Vector2(460, 44)  # Geniş tutuyoruz ki metin sığsın
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var choice_name: String = LocalizationManager.tr_t(data.get("display_name", ""))
		var choice_desc: String = LocalizationManager.tr_t(data.get(desc_field, ""))
		b.text = choice_name + " — " + choice_desc
		b.tooltip_text = choice_desc

		# Döngü değişkenini kopyala (lambda yakalaması için)
		var c_id: StringName = choice_id
		b.pressed.connect(func(): _choose(c_id))
		buttons.add_child(b)

	GothicThemeHelper.init_ui(self)
	visible = true

func _choose(value: StringName) -> void:
	visible = false
	var cb := _callback
	_callback = Callable()
	if cb.is_valid():
		cb.call(value)
