extends RefCounted

## RISKY SUCCESS ROLL — "Sarsılmış ordunun TÜM Success Roll'ları Risky" kuralı.
##
## COMPENDIUM (morale-phase-comprehensive.md): "**ALL** Success Rolls taken for models from a
## Shaken Warband are treated as Risky Success Rolls (unless they are Risky Success Rolls
## already)." + (success-rolls.md): "if the roll is failed the model's Activation immediately ends."
##
## KURAL SAPMASI (2026-07-29 denetimi): bu kural 19 Success Roll çağrı yerinden yalnız 3'ünde
## uygulanıyordu — çoklu-saldırı zincirlerinin her atışı, mayın aksiyonları ve kendi zarını atan
## birime özel yetenek handler'ları kuralın DIŞINDA kalıyordu. Sarsılmış bir ordu RAW'ın
## öngördüğü cezanın çoğundan kaçıyordu. Bu test kapsamın geri daralmasını engeller.

## Success Roll atan ve Risky sonucunu UYGULAMASI gereken dosyalar.
const MUST_APPLY := [
	"res://scripts/unit/attack_flow.gd",
	"res://scripts/unit/unit_attack_chains.gd",
	"res://scripts/rules/mine_actions.gd",
	"res://scripts/rules/abilities/custom/burning_inferno.gd",
	"res://scripts/rules/abilities/custom/temporal_assassin.gd",
	"res://scripts/rules/abilities/custom/vengeful_scripture.gd",
	"res://scripts/rules/abilities/custom/slavemaster.gd",
]

class FakeUnit extends RefCounted:
	var owner_id: int = 1
	var display_name: String = "Sahte"

func run(t) -> void:
	# ── Eşik compendium tablosuyla aynı mı? ──────────────────────────────
	t.eq(RiskyRolls.SUCCESS_THRESHOLD, 7,
		"Başarı eşiği 7 (Success Roll Table: 2-6 Failure, 7-11 Success)")

	# ── Kaynak zaten Risky ise Shaken'a bakılmaz ─────────────────────────
	t.ok(RiskyRolls.is_risky(null, true),
		"Kaynağı Risky olan zar (Dash/tırmanma/[Risky] silah) her hâlükârda Risky")
	t.ok(not RiskyRolls.is_risky(null, false),
		"Geçersiz birim + Risky olmayan kaynak → Risky değil (çökmez)")

	# ── Başarılı zar ASLA aktivasyon bitirmez ────────────────────────────
	var u := FakeUnit.new()
	t.ok(not RiskyRolls.apply_failure(u, 7, true, "test"),
		"7 = Başarı → Risky olsa bile aktivasyon bitmez")
	t.ok(not RiskyRolls.apply_failure(u, 12, true, "test"),
		"12 = Kritik Başarı → aktivasyon bitmez")

	# ── [Risky] silah tespiti ────────────────────────────────────────────
	var risky_atk := AttackData.new()
	risky_atk.keywords[&"risky"] = true
	t.ok(RiskyRolls.weapon_is_risky(risky_atk), "[Risky] keyword'lü silah tespit edilir")
	t.ok(not RiskyRolls.weapon_is_risky(AttackData.new()), "Normal silah Risky değil")
	t.ok(not RiskyRolls.weapon_is_risky(null), "null silah → false (çökmez)")

	# ── KAPSAM: Success Roll atan her yer kuralı uyguluyor mu? ───────────
	for path in MUST_APPLY:
		var f := FileAccess.open(path, FileAccess.READ)
		t.ok(f != null, "%s okunabildi" % path.get_file())
		if f == null:
			continue
		var txt := f.get_as_text()
		f.close()
		t.ok(txt.contains("RiskyRolls."),
			"%s → Risky kuralını uyguluyor (Success Roll atıyor)" % path.get_file())
		# Eski elle-yazılmış koşul geri gelmemeli (tek kaynak korunmalı).
		t.ok(not txt.contains("TurnManager.is_shaken("),
			"%s → Shaken kontrolü elle TEKRARLANMIYOR (tek kaynak RiskyRolls)" % path.get_file())

	# ── AKTİVASYON DIŞI İSTİSNASI ────────────────────────────────────────
	# RAW: aktivasyon DIŞINDA yapılan bir Risky roll başarısızlığı, AKTİVASYONU değil
	# yalnız O AKSİYONU bitirir. Serbest melee vuruşu (kaçan düşmana tepki) tam olarak budur.
	var src := FileAccess.open("res://scripts/unit/unit_attack_chains.gd", FileAccess.READ)
	t.ok(src != null, "unit_attack_chains.gd okunabildi")
	if src != null:
		var utxt := src.get_as_text()
		src.close()
		var i: int = utxt.find("static func execute_free_strike")
		t.ok(i > 0, "execute_free_strike bulundu")
		if i > 0:
			var body: String = utxt.substr(i, 1400)
			t.ok(not body.contains("RiskyRolls.apply_failure"),
				"Serbest melee vuruşu aktivasyon BİTİRMEZ (aktivasyon dışı — RAW istisnası)")
